import os
from time import sleep
import logging
import json
import joblib
import pandas as pd


def init():
    global model
    # construct the model path
    model_path = os.path.join(os.getenv("AZUREML_MODEL_DIR"), "outputs", "risk_model.joblib")    
    # deserialize the model file back into a sklearn model
    model = joblib.load(model_path)    
    logging.info("model loaded!")
    logging.info("Init complete")


def run(raw_data):    
    logging.info("Request received")
    data = json.loads(raw_data)["data"]
    input_df = pd.DataFrame(data)
    result = model.predict_proba(input_df)
    logging.info("Request processed")
    return result.tolist()
    
