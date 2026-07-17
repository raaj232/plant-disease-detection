import sys
import os
import json
from fastapi import FastAPI, UploadFile, File, Form
from datetime import datetime
import torch
import torchvision.transforms as transforms
from PIL import Image
import io

# 1. PATH TO YOUR MODEL FOLDER
whisper_folder = "D:/Program Files/whisper-finetune" # UPDATE THIS IF NEEDED
sys.path.append(whisper_folder)

# 2. IMPORT YOUR CLASS
from helper_functions import MultiTaskLeafModel 

app = FastAPI()
device = torch.device("cpu")

# 3. LOAD DICTIONARIES
json_path = os.path.join(whisper_folder, "multitask_class_maps.json")
weights_path = os.path.join(whisper_folder, "multitask_leaf_specialist.pth")

# with open(json_path, 'r') as f:
#     loaded_maps = json.load(f)
#     my_species_map = loaded_maps["species_map"]
#     my_disease_map = loaded_maps["disease_map"]

with open(json_path, 'r') as f:
    loaded_maps = json.load(f)
    
    # REVERSE the maps: from name->index to index->name
    my_species_map = {str(k): v for k, v in loaded_maps["species_map"].items()}
    my_disease_map = {str(k): v for k, v in loaded_maps["disease_map"].items()}
# 4. INITIALIZE MODEL & LOAD WEIGHTS
num_unique_species = len(my_species_map)
num_unique_diseases = len(my_disease_map)

model = MultiTaskLeafModel(num_species=num_unique_species, num_diseases=num_unique_diseases) 
model.load_state_dict(torch.load(weights_path, map_location=device))
model.eval()

# 5. PREPROCESSING (Must match your training logic)
val_transforms = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],  # ADD THIS
                         std=[0.229, 0.224, 0.225]),   # ADD THIS
])

# 6. THE PREDICTION ENDPOINT
@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
    latitude: str = Form(None),   # ← ADD THIS
    longitude: str = Form(None) 
    ):
    img_bytes = await file.read()
    image = Image.open(io.BytesIO(img_bytes)).convert("RGB")
    
    input_tensor = val_transforms(image).unsqueeze(0).to(device)
    
    with torch.no_grad():
        species_output, disease_output = model(input_tensor) 
        
        species_idx = torch.argmax(species_output, dim=1).item()
        disease_idx = torch.argmax(disease_output, dim=1).item()
        
        species_name = my_species_map[str(species_idx)]
        disease_name = my_disease_map[str(disease_idx)]
        
    return {
        "species": species_name,
        "disease": disease_name
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)