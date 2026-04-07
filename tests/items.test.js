const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../src/app');
const Item = require('../src/models/item');

// Use a separate test database
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/devopsdb_test';

// ─── Setup & Teardown ──────────────────────────────────────────────────────────

beforeAll(async () => {
  await mongoose.connect(MONGO_URI);
});

afterEach(async () => {
  // Clean up the database between tests
  await Item.deleteMany({});
});

afterAll(async () => {
  await mongoose.connection.close();
});

// ─── Health Check ──────────────────────────────────────────────────────────────

describe('GET /health', () => {
  test('should return 200 with status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body).toHaveProperty('timestamp');
    expect(res.body).toHaveProperty('service', 'nodejs-devops-app');
  });
});

// ─── Items API ─────────────────────────────────────────────────────────────────

describe('POST /api/items', () => {
  test('should create a new item successfully', async () => {
    const newItem = { name: 'Test Item', description: 'A test item', quantity: 5 };
    const res = await request(app).post('/api/items').send(newItem);

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Test Item');
    expect(res.body.data.description).toBe('A test item');
    expect(res.body.data.quantity).toBe(5);
    expect(res.body.data).toHaveProperty('_id');
    expect(res.body.data).toHaveProperty('createdAt');
  });

  test('should return 400 when name is missing', async () => {
    const res = await request(app).post('/api/items').send({ description: 'No name here' });

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toMatch(/required/i);
  });

  test('should return 400 when name exceeds max length', async () => {
    const longName = 'A'.repeat(101);
    const res = await request(app).post('/api/items').send({ name: longName });

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });
});

describe('GET /api/items', () => {
  test('should return an empty array when no items exist', async () => {
    const res = await request(app).get('/api/items');

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toEqual([]);
    expect(res.body.count).toBe(0);
  });

  test('should return all items', async () => {
    await Item.create([
      { name: 'Item One', description: 'First' },
      { name: 'Item Two', description: 'Second' },
    ]);

    const res = await request(app).get('/api/items');

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveLength(2);
    expect(res.body.count).toBe(2);
  });
});

describe('GET /api/items/:id', () => {
  test('should return a single item by ID', async () => {
    const created = await Item.create({ name: 'Specific Item', description: 'Details here' });

    const res = await request(app).get(`/api/items/${created._id}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Specific Item');
    expect(res.body.data._id).toBe(created._id.toString());
  });

  test('should return 404 for a non-existent item', async () => {
    const fakeId = new mongoose.Types.ObjectId();
    const res = await request(app).get(`/api/items/${fakeId}`);

    expect(res.statusCode).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toBe('Item not found');
  });

  test('should return 400 for an invalid ID format', async () => {
    const res = await request(app).get('/api/items/not-a-valid-id');

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });
});

describe('PUT /api/items/:id', () => {
  test('should update an existing item', async () => {
    const created = await Item.create({ name: 'Old Name', quantity: 1 });

    const res = await request(app)
      .put(`/api/items/${created._id}`)
      .send({ name: 'Updated Name', quantity: 10 });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Updated Name');
    expect(res.body.data.quantity).toBe(10);
  });

  test('should return 404 when updating a non-existent item', async () => {
    const fakeId = new mongoose.Types.ObjectId();
    const res = await request(app).put(`/api/items/${fakeId}`).send({ name: 'Ghost' });

    expect(res.statusCode).toBe(404);
    expect(res.body.success).toBe(false);
  });
});

describe('DELETE /api/items/:id', () => {
  test('should delete an existing item', async () => {
    const created = await Item.create({ name: 'To Be Deleted' });

    const res = await request(app).delete(`/api/items/${created._id}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toBe('Item deleted successfully');

    // Verify it's actually gone from the database
    const deletedItem = await Item.findById(created._id);
    expect(deletedItem).toBeNull();
  });

  test('should return 404 when deleting a non-existent item', async () => {
    const fakeId = new mongoose.Types.ObjectId();
    const res = await request(app).delete(`/api/items/${fakeId}`);

    expect(res.statusCode).toBe(404);
    expect(res.body.success).toBe(false);
  });
});

// ─── 404 Route ─────────────────────────────────────────────────────────────────

describe('Unknown routes', () => {
  test('should return 404 for undefined routes', async () => {
    const res = await request(app).get('/api/nonexistent');
    expect(res.statusCode).toBe(404);
    expect(res.body.error).toBe('Route not found');
  });
});
