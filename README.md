# genai-course-jaseci-bcs-ouk
Gen AI Training offered by Open University of Kenya with the partners Jaseci-labs &amp; BCS

## Requirements
- Python 3.12+
- [Jaclang](https://pypi.org/project/jaclang/)
- [byLLM](https://pypi.org/project/byllm/)

## Setup
```bash
# Create virtual environment
python3.12 -m venv jac-env 
jac-env\Scripts\activate # Windows
source jac-env/bin/activate  # Linux/Mac

# Install dependencies
pip install jaclang
pip install qrcode[pil]
pip install byllm

# Running your code
export GROQ_API_KEY="<your-groq-api-key>"
export GOOGLE_API_KEY="<your-google-api-key>"
export OPEN_API_KEY="<your-open-api-key>"
jac run <file_name>.jac
