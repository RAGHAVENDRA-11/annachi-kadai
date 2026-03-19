# 🛒 Annachi Kadai — AI-Powered Hyperlocal Grocery App

A full-stack hyperlocal grocery delivery system built with Flutter, FastAPI, and MySQL. Inspired by Zepto/Blinkit — designed for small neighbourhood stores.

---

## 📱 Screenshots

| Customer App | Delivery Partner | Admin Dashboard |
|---|---|---|
| Product listing with categories | Live order tracking | Stock management |
| Voice ordering | Route navigation | Revenue analytics |
| AI chatbot | Status updates | Customer management |

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| **Mobile App** | Flutter (Android + Windows) |
| **Backend API** | FastAPI (Python) |
| **Database** | MySQL |
| **Admin Dashboard** | HTML + Bootstrap 5 |
| **AI Chatbot** | Groq API (LLaMA 3.3 70B) |
| **Maps** | Google Maps / Geo URI |
| **PDF Bills** | ReportLab |
| **Email** | SMTP (Gmail) |

---

## 🚀 Features

### 👤 Customer App
- **OTP-based login & registration** via email
- **Product browsing** with categories (Grocery, Ice Cream, Stationery)
- **Product detail screen** with stock status, images, add to cart
- **Voice ordering** — say "Rendu Pepsi, Moonu Bites" in Tamil/English/Tanglish
- **AI Chatbot** — Groq-powered assistant for product queries and cart actions
- **Cart** with delivery charge logic (free above ₹299)
- **Checkout** with GPS location detection, editable delivery address, 3km radius validation
- **Membership Plans** — Diamond Pass (₹10,000) & Gold Pass (₹26,000)
  - Virtual debit card with card number
  - Free delivery on all orders
  - Monthly spending limits (₹1,000 / ₹2,500)
  - Auto monthly reset for 12 months
- **Reward Points** — earn 1 point per ₹1,000 spent, redeem on orders above ₹1,000
- **Order tracking** with real-time status updates (15s auto-refresh)
- **PDF bill** emailed to customer after every order
- **Order history** with full item details

### 🛵 Delivery Partner App
- **Separate login portal** with phone + password authentication
- **Registration** with name, phone, email, vehicle number
- **Home tab** — today's active orders only with live countdown timer
- **Orders tab** — all orders (active + delivered history)
- **Profile tab** — partner details, change password, logout
- **Navigate button** — opens Google Maps with delivery address for route
- **Tap-to-call** customer directly from order card
- **Status flow** — Pending → Confirmed → Processing → Out for Delivery → Delivered
- **Live timer** per order (green → amber → red based on elapsed time)
- **Auto-refresh** every 15 seconds
- **Switch to Customer Portal** button

### 🖥️ Admin Dashboard
- **Dashboard** with stats — total products, orders, pending, low stock
- **Revenue cards** — today's revenue, total delivered revenue
- **Low stock alerts** with inline stock update
- **Product management** — add, edit, delete, update stock
- **Order management** — view all orders, update status
- **Customer list** with membership badges (💎 Diamond / ⭐ Gold)
- **Auto-refresh** every 15 seconds with stock change notifications
- **Search** across products

---

## 📂 Project Structure

```
annachi-kadai/
├── backend/                    # FastAPI backend
│   ├── routes/
│   │   ├── products.py         # Product CRUD + stock management
│   │   ├── customers.py        # Customer auth + membership
│   │   ├── orders.py           # Order placement + delivery tracking
│   │   ├── ai_routes.py        # Groq AI chatbot
│   │   ├── auth.py             # OTP authentication
│   │   └── delivery_partners.py # Delivery partner auth
│   ├── main.py                 # FastAPI app entry point
│   ├── database.py             # SQLAlchemy DB connection
│   ├── bill_service.py         # PDF bill generation + email
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .env                    # Environment variables (not committed)
│
├── flutter_app/                # Flutter mobile app
│   └── lib/
│       ├── main.dart           # App entry + CartProvider
│       ├── membership_provider.dart  # MembershipProvider (DB-backed)
│       ├── prefs_helper.dart   # SharedPreferences utility
│       ├── api_service.dart    # All API calls
│       ├── login_screen.dart   # OTP login
│       ├── register_screen.dart
│       ├── home_screen.dart    # Main shell with bottom nav
│       ├── products_screen.dart
│       ├── product_detail_screen.dart
│       ├── cart_screen.dart
│       ├── checkout_screen.dart
│       ├── orders_screen.dart
│       ├── membership_screen.dart
│       ├── voice_screen.dart   # Voice ordering
│       ├── chat_screen.dart    # AI chatbot
│       └── delivery_screen.dart # Delivery partner portal
│
└── admin-dashboard/
    └── index.html              # Bootstrap admin panel
```

---

## ⚙️ Setup & Installation

### Prerequisites
- Python 3.10+
- Flutter 3.x
- MySQL 8.0
- Node.js (optional, for live server)

### Backend Setup

```powershell
cd backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Run server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Environment Variables (`.env`)

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASS=your_password
DB_NAME=annachi_kadai
DB_SSL=false

GEMINI_API_KEY=your_gemini_key      # optional
GROQ_API_KEY=your_groq_key          # for AI chatbot

EMAIL_ADDRESS=your@gmail.com
EMAIL_PASSWORD=your_app_password
```

### Flutter Setup

```powershell
cd flutter_app
flutter pub get

# For Android — update IP in api_service.dart
# static const String _pcIp = 'YOUR_PC_IP';

flutter run
```

### Database Setup

```sql
CREATE DATABASE annachi_kadai;
```

Tables are auto-created on first run. To add new status values:
```sql
ALTER TABLE orders MODIFY COLUMN status VARCHAR(20) NOT NULL DEFAULT 'pending';
ALTER TABLE order_items ADD COLUMN price DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE customers MODIFY COLUMN membership_card VARCHAR(30) DEFAULT '';
```

---

## 🔌 API Endpoints

### Products
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/products/` | List all products |
| POST | `/api/products/add` | Add product |
| PUT | `/api/products/{id}` | Update product |
| PUT | `/api/products/{id}/stock` | Update stock |
| DELETE | `/api/products/{id}` | Delete product |

### Customers
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/customers/register/send-otp` | Send registration OTP |
| POST | `/api/customers/register/verify-otp` | Verify & register |
| POST | `/api/customers/login/send-otp` | Send login OTP |
| POST | `/api/customers/login/verify-otp` | Verify & login |
| PUT | `/api/customers/{id}` | Update profile |
| POST | `/api/customers/membership/purchase` | Purchase membership |
| GET | `/api/customers/membership/{id}` | Get membership |

### Orders
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/orders/place-with-bill` | Place order + generate PDF bill |
| GET | `/api/orders/customer/{id}` | Customer order history |
| GET | `/api/orders/all` | All orders (admin) |
| PUT | `/api/orders/{id}/status` | Update order status |
| GET | `/api/orders/delivery/active` | Active orders for delivery |
| GET | `/api/orders/delivery/history` | Delivered order history |

### Delivery Partners
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/delivery-partners/register` | Register partner |
| POST | `/api/delivery-partners/login` | Partner login |
| PUT | `/api/delivery-partners/{id}/password` | Change password |

### AI
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/ai/chat` | Chat with Groq AI assistant |

---

## 🗺️ Order Status Flow

```
pending → confirmed → processing → on_the_way → delivered
                                              ↘ cancelled
```

---

## 📦 Flutter Dependencies

```yaml
dependencies:
  provider: ^6.1.2
  shared_preferences: ^2.2.3
  http: ^1.2.1
  geolocator: ^11.0.0
  geocoding: ^3.0.0
  speech_to_text: ^6.6.2
  url_launcher: ^6.2.5
```

---

## 🛡️ Key Business Rules

- **Delivery radius**: 3km from shop (GPS validated)
- **Delivery charge**: ₹40 below ₹299, FREE above ₹299
- **Membership free delivery**: Only when card is applied at checkout
- **Diamond Pass**: ₹10,000 · ₹1,000/month limit · ₹2,000 annual savings
- **Gold Pass**: ₹26,000 · ₹2,500/month limit · ₹4,000 annual savings
- **Reward points**: 1 point per ₹1,000 spent, redeemable on orders ≥ ₹1,000
- **Monthly limit**: Resets on 1st of every month for 12 months
- **Stock**: Auto-decreases on order placement

---

## 👨‍💻 Author

Built for **Annachi Kadai** — a hyperlocal grocery store in Coimbatore, Tamil Nadu, India.

---

## 📄 License

MIT License — feel free to use and modify.
