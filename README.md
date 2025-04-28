# 🧾 Digital Receipt Recognition and Shopping Tracker

A mobile application developed with Flutter and Python FastAPI that scans, parses, and categorizes shopping receipts using OCR technologies and Large Language Models (LLMs) like Google Gemini. Easily track and visualize your expenses from physical receipts with just a photo!

## 🚀 Features

- 📸 **Scan Receipts** — Capture photos of your shopping receipts via camera or upload from gallery.
- 🧠 **OCR and AI Analysis** — Extract receipt data using Google ML Kit, PaddleOCR, and Gemini 2.0 Flash models.
- 📊 **Expense Tracking** — View categorized spending in pie charts, bar graphs, and monthly reports.
- 📚 **Local Storage** — Save receipts offline using Isar NoSQL database.
- ⚙️ **Manual Data Entry** — Option to manually input or edit receipt details.
- 📈 **Advanced Statistics** — Analyze shopping habits by date, market, product, category, and sub-category.

## 🛠️ Technologies Used

| Technology       | Purpose                                          |
| -----------------| ------------------------------------------------ |
| Flutter + Dart   | Cross-platform mobile frontend                  |
| FastAPI (Python) | Backend API and OCR processing                  |
| OpenCV           | Image preprocessing                              |
| PaddleOCR        | OCR engine for multilingual text                |
| Google ML Kit    | Mobile-optimized OCR                            |
| Gemini API       | AI-based text parsing and categorization        |
| Isar Database    | Lightweight local NoSQL storage                 |

## 📸 Screenshots

Home Page | Statistics Page | Receipt Details  
(Replace link_here with your screenshots or upload them later)

## 🧩 Installation

Clone the repository:

```bash
git clone https://github.com/Elwynr/Receiptionary.git
cd Receiptionary/
```

### Backend and Frontend Setup

1. Install dependencies:
    ```bash
    flutter pub get
    pip install -r requirements.txt
    ```

2. Run the application:
    ```bash
    flutter run
    uvicorn main:app --reload
    ```

## 📚 How it Works

1. User uploads or takes a photo of a receipt.
2. Image is processed (rotation correction, denoising, thresholding).
3. OCR engine extracts text.
4. Text is sent to Gemini LLM for parsing and categorization.
5. Parsed data is displayed and saved locally.
6. User can view stats, search, and filter past receipts.

## 📬 Contact

If you have any questions or suggestions, feel free to contact:

**Elvin Ramazanli**  
elvin.rmznl16@gmail.com  

## ✨ Contributions

Pull requests are welcome!  
If you would like to improve something, please open an issue first to discuss what you would like to change.

## 🌟 GitHub Repo

You can view the project here:  
[https://github.com/Elwynr/Receiptionary](https://github.com/Elwynr/Receiptionary)
