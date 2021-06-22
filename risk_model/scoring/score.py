import os
from time import sleep
import logging
import pickle
import json
import numpy
import joblib
import pandas as pd


def init():
    global model
    # AZUREML_MODEL_DIR is an environment variable created during deployment.
    # It is the path to the model folder (./azureml-models/$MODEL_NAME/$VERSION)
    # For multiple models, it points to the folder containing all deployed models (./azureml-models)
    model_path = os.path.join(os.getenv("AZUREML_MODEL_DIR"), "model", "risk_model.joblib")
    # deserialize the model file back into a sklearn model
    model = joblib.load(model_path)
    logging.info("Init complete")


def run(raw_data):    
    logging.info("Request received")
    data = json.loads(raw_data)["data"]
    input_df = pd.DataFrame(data)
    result = model.predict_proba(input_df)
    logging.info("Request processed")
    return result.tolist()
    
