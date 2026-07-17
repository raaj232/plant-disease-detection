# Plant Disease Detection System

An end-to-end AI-powered system for detecting plant species and diseases from leaf images, built as part of a PS-I internship project. The system uses a multitask deep learning model served via a FastAPI backend, connected to a Flutter mobile app.

## Overview

- **Model**: Multitask ResNet50 CNN, jointly predicting plant species and disease category
- **Dataset**: [PlantVillage dataset](https://www.kaggle.com/datasets/abdallahalidev/plantvillage-dataset) — ~54,000 images across 14 species and 21 disease categories
- **Backend**: FastAPI server (`server.py`) that loads the trained model and serves predictions via a `/predict` endpoint
- **Frontend**: Flutter mobile app (`main.dart`) that captures a leaf image, sends it to the backend, and displays the diagnosis
- **Extra feature**: GPS-based "Find Nearby Pesticide Shops" using Google Maps

## Files in this repo

| File | Description |
|---|---|
| `workflow.ipynb` | Model training: data loading, augmentation, ResNet50 architecture, training loop |
| `server.py` | FastAPI backend serving the trained model |
| `helper_functions.py` | Model class definition (`MultiTaskLeafModel`) |
| `multitask_class_maps.json` | Index-to-label mappings for species and disease classes |
| `main.dart` | Flutter app: image capture, GPS, API communication, UI |
| `pubspec.yaml` | Flutter app dependencies |

## How it works

1. User selects a leaf image in the app and taps "Analyze Leaf"
2. The app sends the image (and GPS coordinates) as a multipart HTTP POST request to the FastAPI server
3. The server preprocesses the image and runs it through the trained model
4. The model outputs predicted species and disease
5. The result is sent back as JSON and displayed in the app
6. GPS coordinates are used locally in the app to open a Google Maps search for nearby pesticide shops

## Model training details

- Base architecture: ResNet50 (multitask head for species + disease)
- Data augmentation applied to improve robustness to real-world image variation
- Trained for 7 epochs

## Dataset

The full PlantVillage dataset is not included in this repo due to size. It's publicly available at:
(https://www.kaggle.com/datasets/abdallahalidev/plantvillage-dataset)

## Note

This project was built as part of a PS-I internship placement.
