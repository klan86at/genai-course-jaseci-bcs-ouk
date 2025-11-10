import streamlit as st
import subprocess
import os
import sys
import tempfile
import shutil

# Add the current directory to Python path for imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

st.set_page_config(
    page_title="CodeGenius - AI Documentation Generator",
    page_icon="📒",
    layout="wide"
)

st.title("📜 CodeGenius - AI Documentation Generator")
st.markdown("Generate comprehensive documentation for any GitHub repository using AI")

# Sidebar for configuration
with st.sidebar:
    st.header("⛓️ Configuration")
    
    # API Key inputs
    st.subheader("API Keys")
    groq_key = st.text_input("Groq API Key", type="password", help="Optional: For Groq LLM")
    google_key = st.text_input("Google API Key", type="password", help="For Gemini LLM")
    openai_key = st.text_input("OpenAI API Key", type="password", help="Optional: For GPT models")
    
    # Model selection
    model_options = {
        "Gemini 2.0 Flash": "gemini/gemini-2.0-flash-001",
        "GPT-4o Mini": "openai/gpt-4o-mini", 
        "Llama 3.1 8B": "groq/llama-3.1-8b-instant"
    }
    selected_model = st.selectbox("Select LLM Model", list(model_options.keys()), index=0)

# Main interface
col1, col2 = st.columns([1, 1])

with col1:
    st.header("🔗 Repository Input")
    github_url = st.text_input(
        "GitHub Repository URL",
        placeholder="https://github.com/username/repository",
        help="Enter the full GitHub repository URL"
    )
    
    # Validate URL
    if github_url and not github_url.startswith("https://github.com/"):
        st.error("Please enter a valid GitHub URL starting with https://github.com/")
    
    generate_btn = st.button("🚀 Generate Documentation", type="primary", disabled=not github_url)

with col2:
    st.header("📊 Status")
    status_placeholder = st.empty()
    progress_bar = st.progress(0)

# Results section
st.header("📄 Generated Documentation")
doc_placeholder = st.empty()

def run_jac_command(github_url, model_name):
    """Run the Jac command and return the result"""
    try:
        # Set environment variables
        env = os.environ.copy()
        if groq_key:
            env['GROQ_API_KEY'] = groq_key
        if google_key:
            env['GOOGLE_API_KEY'] = google_key
        if openai_key:
            env['OPENAI_API_KEY'] = openai_key
        
        # Create a temporary input file to simulate user input
        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt') as f:
            f.write(github_url + '\n')
            input_file = f.name
        
        # Run the Jac command
        cmd = f'echo "{github_url}" | jac run main.jac'
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            env=env,
            cwd=os.path.dirname(os.path.abspath(__file__))
        )
        
        # Clean up temp file
        os.unlink(input_file)
        
        return result.stdout, result.stderr, result.returncode
        
    except Exception as e:
        return "", str(e), 1

if generate_btn and github_url:
    with st.spinner("Generating documentation..."):
        status_placeholder.info("🔄 Starting documentation generation...")
        progress_bar.progress(10)
        
        # Update model in main.jac if needed (this is a simplified approach)
        status_placeholder.info("🤖 Initializing AI model...")
        progress_bar.progress(20)
        
        status_placeholder.info("📥 Cloning repository...")
        progress_bar.progress(40)
        
        status_placeholder.info("🔍 Analyzing code structure...")
        progress_bar.progress(60)
        
        status_placeholder.info("📝 Generating documentation...")
        progress_bar.progress(80)
        
        # Run the Jac command
        stdout, stderr, returncode = run_jac_command(github_url, model_options[selected_model])
        
        progress_bar.progress(100)
        
        if returncode == 0:
            status_placeholder.success("✅ Documentation generated successfully!")
            
            # Extract documentation from output
            if "=" * 50 in stdout:
                # Find the documentation between the separator lines
                parts = stdout.split("=" * 50)
                if len(parts) >= 2:
                    documentation = parts[1].strip()
                    
                    with doc_placeholder.container():
                        st.markdown("### 📋 Generated Documentation")
                        st.markdown(documentation)
                        
                        # Download button
                        st.download_button(
                            label="💾 Download Documentation",
                            data=documentation,
                            file_name=f"documentation_{github_url.split('/')[-1]}.md",
                            mime="text/markdown"
                        )
                else:
                    st.warning("Documentation generated but format not recognized")
                    st.text(stdout)
            else:
                st.warning("Documentation generated but format not recognized")
                st.text(stdout)
                
        else:
            status_placeholder.error("❌ Error generating documentation")
            st.error(f"Error: {stderr}")
            if stdout:
                st.text("Output:")
                st.text(stdout)

# Footer
st.markdown("---")
st.markdown("Built with 😰 using Jaclang, Streamlit, and AI")