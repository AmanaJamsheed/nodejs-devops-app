# ─────────────────────────────────────────────────────────────────────────────
# Stage 1: Builder — Install all dependencies
# ─────────────────────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

LABEL maintainer="AmanaJamsheed"
LABEL description="Node.js DevOps App - Builder Stage"

# Set working directory
WORKDIR /app

# Copy package files first (layer caching optimization)
COPY package*.json ./

# Install ALL dependencies (including devDependencies for build step if needed)
RUN npm ci --only=production

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2: Production — Lean, secure final image
# ─────────────────────────────────────────────────────────────────────────────
FROM node:20-alpine AS production

LABEL maintainer="AmanaJamsheed"
LABEL description="Node.js DevOps App - Production"
LABEL version="1.0.0"

# Install dumb-init for proper signal handling (PID 1 fix)
RUN apk add --no-cache dumb-init

# Create a non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S appuser -u 1001 -G nodejs

# Set working directory
WORKDIR /app

# Copy production dependencies from builder stage
COPY --from=builder --chown=appuser:nodejs /app/node_modules ./node_modules

# Copy application source code
COPY --chown=appuser:nodejs src/ ./src/
COPY --chown=appuser:nodejs package*.json ./

# Switch to non-root user
USER appuser

# Expose application port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Use dumb-init as PID 1 to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["node", "src/app.js"]
