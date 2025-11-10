# byLLM Codebase Genius

Utilizing byLLM libarry to implement our CodebaseGenius github summary app.

## Overview

This repository contains a simple application that utilizes the byLLM library to generate summaries of GitHub repositories. The application fetches repository data and uses byLLM to create concise summaries.

## Folder structure

```
assignment_two/
├── app.py              - Runs the Streamlit app
├── agents/             - folder containing the agents to clone, parse & summarize code
│   └── repo_mapper.jac
        code_analyzer.jac
        doc_genie.jac
├── requirements.txt    - Contain necessary libraries to run the code
├── main.jac            - The module has the code genius supervisor
├── agent_core.jac      - Contain utility code
├── README.md
└── .env
```

## Prerequisites

- Python 3.12 or higher version
- byLLM library use Jaseci it comes as a bundle(byLLM, jac-cloud etc.)
- Streamlit library for the web interface

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/klan86at/genai-course-jaseci-bcs-ouk.git
   ```
2. Navigate to the project directory:

   ```bash
    cd assignment_two
   ```
3. Install the required dependencies:

   ```bash
   pip install -r requirements.txt
   ```

   4. Set up environment variables:

   - Create a `.env` file in the root directory.
   - Add your OpenAI API or Google API key:

     ```
     OPENAI_API_KEY=your_openai_api_key_here
     ```

     ```
     GOOGLE_API_KEY=your_openai_api_key_here
     ```

## Usage

1. Run the Streamlit app:
   ```bash
   streamlit run app.py
   ```
2. Open your web browser and navigate to `http://localhost:8501`.
3. Enter the GitHub repository URL you want to summarize and click "Generate Summary".
4. Download and View the generated summary displayed on the page.

## Note

- Ensure you have a stable internet connection as the application fetches data from GitHub and uses the byLLM API for summarization.
- The quality of the summary may vary based on the complexity and size of the repository.
- For any issues or contributions, feel free to open an issue or pull request on the GitHub repository.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
