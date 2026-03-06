# 🛒 Annachi Kadai — AI-Powered Hyperlocal Grocery App

A full-stack hyperlocal grocery management system with AI features, OTP login, voice ordering, and real-time inventory management.

---

## 📦 Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter (Windows / Android) |
| Backend API | FastAPI (Python) |
| Database | MySQL |
| Admin Dashboard | HTML + Bootstrap 5 |
| AI Features | scikit-learn, pandas, numpy |
| Authentication | Email OTP via Gmail SMTP |

---

## 🗂️ Project Structure

```
annachi-kadai/
├── backend/                  # FastAPI backend
│   ├── routes/
│   │   ├── products.py       # Product CRUD
│   │   ├── customers.py      # Customer registration
│   │   ├── orders.py         # Order management
│   │   ├── auth.py           # OTP login
│   │   └── ai_routes.py      # AI endpoints
│   ├── main.py               # App entry point
│   ├── database.py           # DB connection
│   ├── ai_features.py        # ML models
│   ├── otp_service.py        # Gmail OTP
│   ├── requirements.txt      # Python dependencies
│   └── .env                  # Environment variables (not in git)
│
├── admin-dashboard/          # Web admin panel
│   └── index.html            # Bootstrap dashboard
│
├── flutter_app/              # Flutter customer app
│   └── lib/
│       ├── main.dart
│       ├── login_screen.dart
│       ├── register_screen.dart
│       ├── home_screen.dart
│       ├── products_screen.dart
│       ├── cart_screen.dart
│       ├── voice_order_screen.dart
│       └── api_service.dart
│
└── README.md
```

---

## ⚙️ Setup & Installation

### 1. Prerequisites

- Python 3.10+
- Flutter SDK
- MySQL Server
- Gmail account with App Password

---

### 2. MySQL Database Setup

Open MySQL terminal and run:

```sql
CREATE DATABASE annachi_kadai;
USE annachi_kadai;

CREATE TABLE categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100)
);

CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200),
  category_id INT,
  price DECIMAL(10,2),
  stock_quantity INT DEFAULT 0,
  unit VARCHAR(50),
  image LONGTEXT,
  is_available TINYINT DEFAULT 1,
  FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE customers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200),
  phone VARCHAR(15) UNIQUE,
  address TEXT,
  email VARCHAR(200),
  latitude FLOAT DEFAULT 0,
  longitude FLOAT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT,
  total_amount DECIMAL(10,2),
  status ENUM('pending','confirmed','delivered','cancelled') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT,
  product_id INT,
  quantity INT,
  price DECIMAL(10,2),
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (product_id) REFERENCES products(id)
);

INSERT INTO categories (name) VALUES ('Grocery'), ('Ice Cream'), ('Stationery');
```

---

### 3. Backend Setup

```powershell
cd backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
```

Create `backend/.env`:
```env
DATABASE_URL=mysql+pymysql://root:YOUR_PASSWORD@127.0.0.1/annachi_kadai
EMAIL_ADDRESS=your_gmail@gmail.com
EMAIL_PASSWORD=your_gmail_app_password
```

> **Gmail App Password:** Go to Google Account → Security → 2-Step Verification → App Passwords → Generate

```powershell
# Start the server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

API runs at: `http://127.0.0.1:8000`  
Swagger docs: `http://127.0.0.1:8000/docs`

---

### 4. Admin Dashboard

- Open `admin-dashboard/index.html` with **VS Code Live Server**
- Or open directly in browser at `http://127.0.0.1:5500/admin-dashboard/index.html`
- Add products with images, manage orders, view customers

---

### 5. Flutter App Setup

```powershell
cd flutter_app

# Install dependencies
flutter pub get
```

**For Windows desktop:**
```powershell
flutter run -d windows
```

**For Android:**
1. Enable USB Debugging on your phone
2. Connect via USB
3. Update `lib/api_service.dart` — change `localhost` to your PC's IP:
```dart
static const String baseUrl = 'http://192.168.X.X:8000/api';
```
4. Run:
```powershell
flutter run
```

> Phone and PC must be on the **same WiFi network**

---

## 🚀 Features

### Customer App
- 📧 Email OTP Login (no password needed)
- 📝 Register with name, phone, address
- 🛍️ Browse products with real images
- 🔍 Search groceries
- ➕ Zepto-style ADD button with quantity stepper
- 🛒 Cart with total price
- 🎤 Voice ordering (Android/iOS)
- 👤 Profile with logout

### Admin Dashboard
- 📊 Dashboard with stats (products, orders, stock alerts)
- 📦 Add products with image upload
- 🔄 Update stock quantities
- 🗑️ Delete products
- 🛍️ Manage order statuses
- 👥 View registered customers

### AI Features
- 📈 Demand forecasting per product
- ⚠️ Low stock alerts with urgency levels
- 🤖 Smart product recommendations per customer

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/products/` | Get all products |
| POST | `/api/products/add` | Add product |
| PUT | `/api/products/{id}/stock` | Update stock |
| DELETE | `/api/products/{id}` | Delete product |
| POST | `/api/customers/register` | Register customer |
| GET | `/api/customers/all` | Get all customers |
| POST | `/api/auth/send-otp` | Send OTP to email |
| POST | `/api/auth/verify-otp` | Verify OTP & login |
| POST | `/api/orders/` | Place order |
| GET | `/api/orders/` | Get all orders |
| PUT | `/api/orders/{id}/status` | Update order status |
| GET | `/api/ai/low-stock` | Low stock alerts |
| GET | `/api/ai/demand/{id}` | Demand forecast |
| GET | `/api/ai/recommendations/{id}` | Product recommendations |

---

## 🔐 Environment Variables

Create `backend/.env` — **never commit this file**:

```env
DATABASE_URL=mysql+pymysql://root:PASSWORD@127.0.0.1/annachi_kadai
EMAIL_ADDRESS=your@gmail.com
EMAIL_PASSWORD=gmail_app_password
```

---

## 📱 Running All Services

Open 3 terminals:

**Terminal 1 — Backend:**
```powershell
cd backend
venv\Scripts\activate
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Terminal 2 — Admin Dashboard:**
```
Open admin-dashboard/index.html with Live Server in VS Code
```

**Terminal 3 — Flutter App:**
```powershell
cd flutter_app
flutter run -d windows
```

---

## 👨‍💻 Built With

- [FastAPI](https://fastapi.tiangolo.com/)
- [Flutter](https://flutter.dev/)
- [MySQL](https://www.mysql.com/)
- [Bootstrap 5](https://getbootstrap.com/)
- [scikit-learn](https://scikit-learn.org/)

---

## 📄 License

This project is for educational and personal use.
