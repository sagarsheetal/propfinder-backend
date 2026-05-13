# PropFinder Backend API

Complete RESTful API for PropFinder real estate application built with Node.js and Express.

---

## 📋 **Table of Contents**

1. [Setup Instructions](#setup-instructions)
2. [API Endpoints](#api-endpoints)
3. [Testing APIs](#testing-apis)
4. [Project Structure](#project-structure)
5. [Environment Variables](#environment-variables)

---

## 🚀 **Setup Instructions**

### **Step 1: Install Node.js**
Make sure you have Node.js installed on your Mac:
```bash
node --version
```
If not installed, download from: https://nodejs.org/

### **Step 2: Navigate to Backend Folder**
```bash
cd propfinder-backend
```

### **Step 3: Install Dependencies**
```bash
npm install
```

### **Step 4: Start the Server**

**Development mode (with auto-reload):**
```bash
npm run dev
```

**Or production mode:**
```bash
npm start
```

### **Step 5: Verify Server is Running**

Open in browser or terminal:
```
http://localhost:5000/api/health
```

You should see:
```json
{
  "status": "Backend is running! ✅"
}
```

---

## 📡 **API Endpoints**

### **1. Get All Properties (with filters)**

**Endpoint:** `GET /api/properties`

**Query Parameters (optional):**
- `type` - "buy" or "rent"
- `location` - City or locality (e.g., "Bangalore")
- `bhk` - "1 BHK", "2 BHK", "3 BHK", etc.
- `budget` - Budget range (e.g., "40-80L", "20-30K")

**Examples:**

Get all properties:
```
GET http://localhost:5000/api/properties
```

Get properties in Bangalore for buying:
```
GET http://localhost:5000/api/properties?location=Bangalore&type=buy
```

Get 2 BHK properties for rent with budget 20-30K:
```
GET http://localhost:5000/api/properties?type=rent&bhk=2%20BHK&budget=20-30K
```

**Response:**
```json
{
  "success": true,
  "count": 5,
  "data": [
    {
      "id": 1,
      "title": "3 BHK Flat for Sale in Koramangala",
      "location": "Koramangala, Bangalore",
      "bhk": "3 BHK",
      "type": "buy",
      "price": 2.2,
      "pricePerSqft": 11891,
      "area": 1850,
      "bathrooms": 3,
      "furnishing": "Furnished",
      "balconies": 2,
      "agentId": 1,
      "images": [...]
    }
  ]
}
```

---

### **2. Get Property Details**

**Endpoint:** `GET /api/properties/:id`

**Example:**
```
GET http://localhost:5000/api/properties/1
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "3 BHK Flat for Sale in Koramangala",
    "location": "Koramangala, Bangalore",
    "bhk": "3 BHK",
    "type": "buy",
    "price": 2.2,
    "pricePerSqft": 11891,
    "area": 1850,
    "bathrooms": 3,
    "furnishing": "Furnished",
    "balconies": 2,
    "agentId": 1,
    "images": [...]
  }
}
```

---

### **3. Add New Property (Agent)**

**Endpoint:** `POST /api/properties`

**Body (JSON):**
```json
{
  "title": "2 BHK Flat for Sale",
  "location": "Indiranagar, Bangalore",
  "bhk": "2 BHK",
  "type": "buy",
  "price": 1.8,
  "pricePerSqft": 12000,
  "area": 1500,
  "bathrooms": 2,
  "furnishing": "Furnished",
  "balconies": 1,
  "agentId": 1,
  "images": ["image_url_1", "image_url_2"]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Property added successfully",
  "data": {
    "id": 6,
    "title": "2 BHK Flat for Sale",
    ...
  }
}
```

---

### **4. Get Agent Details**

**Endpoint:** `GET /api/agents/:id`

**Example:**
```
GET http://localhost:5000/api/agents/1
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Rajesh Kumar",
    "phone": "+91 98765 43210",
    "email": "rajesh@propfinder.com"
  }
}
```

---

### **5. Get All Agents**

**Endpoint:** `GET /api/agents`

**Example:**
```
GET http://localhost:5000/api/agents
```

**Response:**
```json
{
  "success": true,
  "count": 3,
  "data": [
    {
      "id": 1,
      "name": "Rajesh Kumar",
      "phone": "+91 98765 43210",
      "email": "rajesh@propfinder.com"
    },
    ...
  ]
}
```

---

## 🧪 **Testing APIs**

### **Option 1: Browser (GET requests only)**

Open these URLs in your browser:
- http://localhost:5000/api/health
- http://localhost:5000/api/properties
- http://localhost:5000/api/properties/1
- http://localhost:5000/api/agents/1

### **Option 2: cURL (Terminal)**

Test GET request:
```bash
curl http://localhost:5000/api/properties?location=Bangalore&type=buy
```

Test POST request:
```bash
curl -X POST http://localhost:5000/api/properties \
  -H "Content-Type: application/json" \
  -d '{
    "title": "New Property",
    "location": "Bangalore",
    "bhk": "2 BHK",
    "type": "buy",
    "price": 1.5,
    "agentId": 1
  }'
```

### **Option 3: Postman (Recommended)**

1. Download Postman: https://www.postman.com/downloads/
2. Create requests for each endpoint
3. Test GET, POST, filters, etc.

### **Option 4: Thunder Client (VS Code Extension)**

1. Install Thunder Client in VS Code
2. Create requests and test APIs
3. Great for development!

---

## 📁 **Project Structure**

```
propfinder-backend/
├── server.js                    # Main server file
├── package.json                # Dependencies
├── .env                         # Environment variables
├── .gitignore                   # Git ignore rules
│
├── routes/
│   ├── properties.js           # Property endpoints
│   └── agents.js               # Agent endpoints
│
├── controllers/
│   ├── propertyController.js   # Property logic
│   └── agentController.js      # Agent logic
│
├── middleware/
│   └── errorHandler.js         # Error handling
│
├── data/
│   └── mockData.js             # Mock data (temporary)
│
├── config/
│   └── database.js             # Database config (for later)
│
└── README.md                    # This file
```

---

## 🔧 **Environment Variables**

The `.env` file contains:

```
PORT=5000                        # Server port
NODE_ENV=development            # Development/production
API_URL=http://localhost:5000   # API base URL
```

---

## 📝 **Key Features**

✅ **RESTful API** - Standard REST architecture  
✅ **Filtering** - Filter by location, BHK, budget, type  
✅ **Error Handling** - Comprehensive error handling  
✅ **CORS Enabled** - Works with frontend from any port  
✅ **Mock Data** - Pre-populated with sample properties  
✅ **Scalable Structure** - Ready for database integration  

---

## 🔜 **Next Steps**

1. **Integrate PostgreSQL** - Replace mock data with database
2. **Add Authentication** - User login/signup
3. **Add More APIs** - Wishlist, reviews, ratings, etc.
4. **Deploy** - Deploy to Render.com (free)
5. **Connect Frontend** - Update React app to use backend APIs

---

## 💡 **Tips**

- Press `Ctrl + C` to stop the server
- Use `npm run dev` for development (auto-reload on file changes)
- Check terminal for debug logs
- Test all endpoints before deploying
- Keep `.env` file secure (never commit to git)

---

## 📞 **API Response Format**

All APIs follow this response format:

**Success:**
```json
{
  "success": true,
  "data": { ... },
  "count": 5
}
```

**Error:**
```json
{
  "success": false,
  "error": "Error message"
}
```

---

**Happy coding! 🚀**
