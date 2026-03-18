from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text as sql_text
from database import get_db
from ai_features import get_demand_forecast, get_low_stock_alerts, get_smart_recommendations
import os, json
try:
    from dotenv import load_dotenv
    load_dotenv()
except Exception:
    pass

router = APIRouter()

@router.get("/demand/{product_id}")
def demand_forecast(product_id: int):
    return get_demand_forecast(product_id)

@router.get("/low-stock")
def low_stock_alerts():
    return get_low_stock_alerts()

@router.get("/recommendations/{customer_id}")
def recommendations(customer_id: int):
    return get_smart_recommendations(customer_id)

@router.post("/voice-order")
def voice_order(data: dict, db: Session = Depends(get_db)):
    order_text = data.get("text", "").lower().strip()
    if not order_text:
        raise HTTPException(status_code=400, detail="No text provided")

    result = db.execute(sql_text("SELECT id, name, price, unit FROM products"))
    products = result.fetchall()

    matched = []
    for product in products:
        name_lower = product[1].lower()
        if any(word in order_text for word in name_lower.split()):
            matched.append({
                "id":    product[0],
                "name":  product[1],
                "price": float(product[2]),
                "unit":  product[3],
            })

    if not matched:
        return {
            "matched_items": [],
            "message": f'No products found for "{order_text}". Try different keywords.'
        }

    return {
        "matched_items": matched,
        "message": f"Found {len(matched)} matching products"
    }

@router.post("/chat")
def chat(data: dict, db: Session = Depends(get_db)):
    
    user_message = data.get("message", "").strip()
    history      = data.get("history", [])  # list of {role, content}
    customer_id  = data.get("customer_id", "")

    if not user_message:
        raise HTTPException(status_code=400, detail="No message provided")

    # Fetch all products from DB
    result = db.execute(sql_text(
        "SELECT id, name, price, unit, stock_quantity FROM products"
    ))
    products = result.fetchall()
    product_list = "\n".join([
        f"- {p[1]} | ₹{p[2]} per {p[3]} | Stock: {p[4]}"
        for p in products
    ])

    system_prompt = f"""You are a friendly AI assistant for Annachi Kadai, a hyperlocal grocery store in Coimbatore, India.
You help customers find products, answer questions, and assist with ordering.

Available products:
{product_list}

Guidelines:
- Be friendly and conversational. You can understand Tamil-English mixed messages (Tanglish).
- When recommending products, mention the price and unit.
- If a product is out of stock (Stock: 0), inform the customer politely.
- Keep responses short and helpful (2-4 sentences max).
- If asked to add items to cart, respond with a special JSON block at the END of your message like:
  CART_ACTION:{{"items": [{{"id": 1, "name": "Lays", "price": 10, "unit": "packet", "qty": 2}}]}}
- Do not make up products that are not in the list above.
- If asked about delivery, say delivery is within 10 minutes for nearby locations.
- Shop name: Annachi Kadai. Owner is friendly and helpful."""

    api_key = os.getenv("GROQ_API_KEY", "").strip()
    if not api_key:
        print("❌ GROQ_API_KEY is empty!")
        return {"reply": "AI chat is not configured. GROQ_API_KEY is missing.", "cart_action": None}

    # Build messages with system prompt — only allow valid Groq roles
    groq_messages = [{"role": "system", "content": system_prompt}]
    for h in history[-10:]:
        role = h.get("role", "")
        # Flutter sends 'bot' or 'ai' — map to 'assistant'
        if role == "user":
            groq_messages.append({"role": "user", "content": h["content"]})
        elif role in ("assistant", "bot", "ai", "model"):
            groq_messages.append({"role": "assistant", "content": h["content"]})
        # skip any other invalid roles
    groq_messages.append({"role": "user", "content": user_message})

    try:
        import requests as req_lib
        response = req_lib.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            },
            json={
                "model": "llama-3.3-70b-versatile",
                "messages": groq_messages,
                "max_tokens": 400,
                "temperature": 0.7
            },
            timeout=15
        )
        if response.status_code != 200:
            print(f"❌ Groq API error {response.status_code}: {response.text[:200]}")
            raise HTTPException(status_code=500, detail=f"Groq error: {response.status_code} — {response.text[:100]}")
        result = response.json()
        reply = result["choices"][0]["message"]["content"]
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Groq call failed: {e}")
        raise HTTPException(status_code=500, detail=f"AI error: {str(e)}")

    # Extract cart action if present
    cart_action = None
    if "CART_ACTION:" in reply:
        try:
            parts = reply.split("CART_ACTION:")
            reply = parts[0].strip()
            cart_action = json.loads(parts[1].strip())
        except Exception:
            pass

    return {"reply": reply, "cart_action": cart_action}