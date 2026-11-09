from fastapi import FastAPI

app = FastAPI(
    title="Lights Logic Cloud",
    version="1.0.0"
)

@app.get("/")
def home():
    return {
        "app": "Lights Logic",
        "status": "Backend online"
    }

@app.get("/health")
def health():
    return {"status": "healthy"}
