# genai-course-jaseci-bcs-ouk
Gen AI Training offered by Open University of Kenya with the partners Jaseci-labs &amp; BCS

## Requirements
- Python 3.12+
- [Jaclang](https://pypi.org/project/jaclang/)
- [byLLM](https://pypi.org/project/byllm/)

## Setup
```bash
# Create virtual environment
python3.12 -m venv jac-env # Windows
source jac-env/bin/activate  # Windows

# Install dependencies
pip install jaclang
pip install qrcode[pil]

# Running your code
set GEMINI_API_KEY="<your-gemini-api-key>"
jac run <file_name>.jac