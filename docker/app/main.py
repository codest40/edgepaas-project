# main.py
from fastapi import FastAPI, Request, Form, Depends, WebSocket, WebSocketDisconnect
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
import requests
import os

import crud, models, schemas
from db import get_db
from websock import manager
from sre.system_health import router as system_router
from sre.health import router as health_router

app = FastAPI()
app.include_router(system_router)
app.include_router(health_router)


@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.get("/favicon.ico")
def get_favicon():
    return {""}

# Static + templates
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

API_KEY = os.getenv("OPENWEATHER_API_KEY", "DEFAULT")


# --------------- Home / Weather ----------------
@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request, "weather": None})


@app.post("/weather", response_class=HTMLResponse)
async def get_weather(request: Request, city: str = Form(...)):
    url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={API_KEY}&units=metric"
    resp = requests.get(url).json()

    if resp.get("cod") != 200:
        weather_info = {"city": city, "temperature": "-", "description": "City not found"}
    else:
        weather_info = {
            "city": city,
            "temperature": resp["main"]["temp"],
            "description": resp["weather"][0]["description"],
        }

    return templates.TemplateResponse("index.html", {"request": request, "weather": weather_info})


# --------------- Preferences Page ----------------
@app.get("/preferences", response_class=HTMLResponse)
async def read_preferences(request: Request):
    return templates.TemplateResponse("preferences.html", {"request": request})


@app.post("/preferences")
async def save_preferences(
    name: str = Form(...),
    email: str = Form(...),
    city: str = Form(...),
    alert_type: str = Form(...),
    db: Session = Depends(get_db),
):
    # Check if user exists
    user = db.query(models.WeatherUser).filter(models.WeatherUser.email == email).first()

    if not user:
        user_in = schemas.UserCreate(name=name, email=email)
        user = crud.create_user(db, user_in)

    # Save preference
    pref_in = schemas.PreferenceCreate(user_id=user.id, city=city, alert_type=alert_type)
    crud.create_preference(db, pref_in)

    # Broadcast real-time alert to all connected clients
    await manager.broadcast(f"New preference saved: {city} ({alert_type})")
    return JSONResponse({"message": "Preferences saved!", "user_id": user.id})


@app.get("/preferences/{user_id}")
async def get_user_preferences(user_id: int, db: Session = Depends(get_db)):
    prefs = crud.get_preferences_by_user(db, user_id)
    return [schemas.PreferenceOut.from_orm(p) for p in prefs]

# --------------- WebSocket Endpoint ----------------
@app.websocket("/ws/alerts")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await manager.send_personal_message(f"You said: {data}", websocket)
    except WebSocketDisconnect:
        manager.disconnect(websocket)

