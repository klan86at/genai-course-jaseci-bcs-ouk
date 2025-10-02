# captioner.jac
import from byllm { Model, Image }

glob vision_llm = Model(model_name="groq/meta-llama/llama-guard-4-12b");

obj PhotoAnalyzer {
    has photographer_name: str;
    has style_preference: str;
    has image: Image;
}

# Add semantic context for better AI understanding
sem PhotoAnalyzer = "Professional photo analysis tool for photographers";
sem PhotoAnalyzer.photographer_name = "Name of the photographer for personalized analysis";
sem PhotoAnalyzer.style_preference = "Preferred photography style (artistic, documentary, commercial)";


"""Generate caption considering photographer's style preference."""
def generate_styled_caption(pa: PhotoAnalyzer) -> str by vision_llm();

"""Provide technical photography feedback."""
def analyze_composition(pa: PhotoAnalyzer) -> list[str] by vision_llm();

"""Suggest improvements for the photo."""
def suggest_improvements(pa: PhotoAnalyzer) -> list[str] by vision_llm();


with entry {
    analyzer = PhotoAnalyzer(
        photographer_name="Ken",
        style_preference="artistic",
        image=Image("D:/Gen AI Course/genai-course-jaseci-bcs-ouk/photo.jpg")
    );

    # Generate styled caption
    caption = generate_styled_caption(analyzer);
    print(f"Styled caption: {caption}");

    # Analyze composition
    composition = analyze_composition(analyzer);
    print(f"Composition analysis: {composition}");

    # Get improvement suggestions
    suggestions = suggest_improvements(analyzer);
    print(f"Suggestions: {suggestions}");
}