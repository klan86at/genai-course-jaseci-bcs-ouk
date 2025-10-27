# Graph schema
# Core repository structure
node repo {
    has url: str;
    has local_path: str;
    has status: str = "pending";
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

# CCG: Code Context Graph nodes
node module {
    has name: str;          # e.g., "main", "utils"
    has file_path: str;     # source file path
}

node class_node {
    has name: str;
    has docstring: str = "";
    has file_path: str;
}

node function {
    has name: str;
    has signature: str = "";
    has docstring: str = "";
    has file_path: str;
}

node variable {
    has name: str;
    has value_repr: str = "";  # optional: string representation of value
    has file_path: str;
}

# CCG edges
edge contains {}      # module --contains--> class/function/variable
edge inherits {}      # class --inherits--> parent_class
edge calls {}         # function --calls--> called_function
edge uses {}          # function --uses--> variable
edge defines {}       # file --defines--> module/class/function/variable