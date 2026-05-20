# JustDraw Blueprint AI

JustDraw Blueprint AI is a Flutter application that transforms your hand-drawn sketches into professional-looking architectural or technical blueprints using Google's Gemini AI.

## Kitchen design
<img width="1172" height="601" alt="image" src="https://github.com/user-attachments/assets/e334fc6a-dbec-48c2-a54e-f2e511e672eb" />


## 📺 Demo
[Watch Kitchen demo](https://www.loom.com/share/c11f01df5394404484d0f88e080483f5)
[Watch it demo](https://www.loom.com/share/8a5ec5f63bb941ed9323e1166077b00e)

## How It Works

The application follows a simple two-step AI transformation process:

1.  **Sketch Analysis**: When you upload or take a photo of a sketch, the app sends it to Gemini AI. The AI analyzes the proportions, labels, and intent of your drawing to create a detailed structured description (Blueprint Analysis).
2.  **Blueprint Generation**: Using the structured analysis, the app generates a precise prompt for an image generation model to create a clean, high-fidelity blueprint image that matches your original vision.

## Features

-   **Image Picker**: Capture sketches directly from your camera or select them from your gallery.
-   **AI-Powered Analysis**: Leverages Google Gemini for intelligent image understanding.
-   **Step-by-Step Progress**: Visual feedback during the analysis and generation phases.
-   **Clean UI**: Minimalist design powered by Flutter and Google Fonts (Space Grotesk).

## Tech Stack

-   **Frontend**: Flutter
-   **State Management**: Riverpod
-   **AI Integration**: Google Gemini API
-   **Environment Config**: flutter_dotenv
-   **Animations**: flutter_animate

## Getting Started

### Prerequisites

-   Flutter SDK
-   A Gemini API Key from [Google AI Studio](https://aistudio.google.com/)

### Setup

1.  Clone the repository.
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Create a `.env` file in the root directory.
4.  Add your Gemini API key to the `.env` file:
    ```env
    GEMINI_API_KEY=your_api_key_here
    ```
5.  Run the application:
    ```bash
    flutter run
    ```

## Project Structure

-   `lib/screens/`: UI screens (Home, etc.)
-   `lib/services/`: External API integrations (Gemini)
-   `lib/providers/`: State management logic using Riverpod
-   `lib/models/`: Data models for analysis results
