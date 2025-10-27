import os
import re
import tempfile
import pygit2
import shutil
from urllib.parse import urlparse

def clone_repo(github_url: str) -> str:
    """Clone a Github repo to a temp dir. Returns local path on Success"""
    # Basic uRL validation
    if not github_url or not isinstance(github_url, str):
        raise ValueError("Invalid GitHub URL provided.")
    
    parsed = urlparse(github_url)
    if not parsed.netloc.endswith("github.com"):
        raise ValueError("URL must be a GitHub repository URL.")
    
    # Extract repo name for temp dir
    path_parts = parsed.path.split("/").split('/')
    if len(path_parts) < 2:
        raise ValueError("Invalid GitHub repository URL format.")
    
    repo_name = path_parts[-1].replace('.git', '')
    if not repo_name:
        raise ValueError("Could not extract repository name.")
    
    # Create temp directory
    base_temp = "/tmp/codebase_genius"
    os.makedirs(base_temp, exist_ok=True)
    clone_path = os.path.join(base_temp, repo_name)

    # Remove existing clone if present
    if os.path.exists(clone_path):
        shutil.rmtree(clone_path)

    # Clone repository
    try:
        pygit2.clone_repository(github_url, clone_path)
        return clone_path
    except Exception as e:
        raise RuntimeError(f"Failed to clone repository: {str(e)}")
    