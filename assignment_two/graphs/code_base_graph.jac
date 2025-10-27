# Graph schema
node repo {
    has github_url: "";
    has local_path: str;
}

node folder {
    has name: str;
    has path: str;
}

node file {
    has name: str;
    has path: str;
    has language: str = "unknown";
    has content: str = "";
    has summary: str = "";
}

