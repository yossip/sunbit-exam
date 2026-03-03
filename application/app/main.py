from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel
import uuid
import time
import os
import random

app = FastAPI(
    title="Sunbit POS Processing API",
    description="Microservice to process Point of Sale credit applications.",
    version="1.0.0",
)

# --- Models ---
class CreditApplication(BaseModel):
    merchant_id: str
    user_id: str
    purchase_amount: float
    item_category: str # e.g., 'dental', 'auto_repair'

class ApplicationResponse(BaseModel):
    application_id: str
    status: str
    approved_amount: float
    message: str

# --- Mock AI Insight (SageMaker Simulation) ---
def _mock_sagemaker_inference(app_data: CreditApplication) -> dict:
    """Simulates a call to an AWS SageMaker endpoint for a credit decision."""
    # Simulate network latency to ML Model
    time.sleep(random.uniform(0.1, 0.5))
    
    # Simple mock logic based on high-value categories
    if app_data.purchase_amount > 5000 and app_data.item_category not in ['auto_repair', 'dental']:
        return {"status": "DECLINED", "reason": "High risk amount for non-essential category."}
    
    return {
        "status": "APPROVED",
        "approved_amount": app_data.purchase_amount,
        "reason": "AI Insight confirms healthy financial behavior."
    }

# --- Endpoints ---
@app.post("/api/v1/credit-applications", response_model=ApplicationResponse, status_code=status.HTTP_201_CREATED)
async def process_application(application: CreditApplication):
    """
    Process a new POS credit application.
    Expected Flow in Production:
      1. Validate Payload.
      2. Save Initial State to DynamoDB.
      3. Call SageMaker Endpoint for AI Insight/Risk Scoring.
      4. Save final decision to Aurora PostgreSQL Ledger.
      5. Emit event to MSK (Kafka) for async processing (email/SMS).
    """
    app_id = str(uuid.uuid4())
    
    # 1. (Simulated) Save to DynamoDB
    # dynamodb.put_item(TableName='sunbit-pos-sessions', Item={...})
    
    # 2. Get AI Decision
    try:
        decision = _mock_sagemaker_inference(application)
    except Exception as e:
        # Graceful degradation if ML model is unavailable
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI Insights Service is currently unavailable."
        )

    # 3. (Simulated) Save to Aurora Ledger
    # aurora_cursor.execute("INSERT INTO ledgers ...")

    if decision["status"] == "APPROVED":
        return ApplicationResponse(
            application_id=app_id,
            status="APPROVED",
            approved_amount=decision["approved_amount"],
            message=f"Application approved instantly. {decision['reason']}"
        )
    else:
        return ApplicationResponse(
            application_id=app_id,
            status="DECLINED",
            approved_amount=0.0,
            message=f"Application declined. {decision['reason']}"
        )

@app.get("/healthz")
async def health_check():
    """Liveness probe endpoint for Kubernetes."""
    return {"status": "ok"}

@app.get("/readyz")
async def readiness_check():
    """
    Readiness probe endpoint for Kubernetes.
    Should check DB connections or ML endpoint health.
    """
    # Ex: if not db.is_connected(): return 503
    return {"status": "ready"}
