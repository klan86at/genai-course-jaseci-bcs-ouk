# robust_ai.jac
import from byllm { Model, Image }

glob reliable_llm = Model(model_name="gpt-4o", max_tries=3);

obj RobustCaptioner {
    has fallback_enabled: bool = True;

    """Generate caption with error handling."""
    def safe_caption(image_path: str) -> dict {
        try {
            caption = self.generate_caption_ai(image_path);
            return {
                "success": True,
                "caption": caption,
                "source": "ai"
            };
        } except Exception as e {
            if self.fallback_enabled {
                fallback_caption = f"Image analysis unavailable for {image_path}";
                return {
                    "success": False,
                    "caption": fallback_caption,
                    "source": "fallback",
                    "error": str(e)
                };
            } else {
                raise e;
            }
        }
    }

    """AI-powered caption generation."""
    def generate_caption_ai(image_path: str) -> str by reliable_llm();

    """Validate generated content."""
    def validate_caption(caption: str) -> bool {
        # Basic validation rules
        if len(caption) < 10 {
            return False;
        }
        if "error" in caption.lower() {
            return False;
        }
        return True;
    }
}

with entry {
    captioner = RobustCaptioner(fallback_enabled=True);

    # Test with different scenarios
    test_images = [
        Image("valid_photo.jpg"),
        Image("corrupted.jpg"),
        Image("missing.jpg")
    ];

    for image in test_images {
        result = captioner.safe_caption(image);

        if result["success"] {
            is_valid = captioner.validate_caption(result["caption"]);
            print(f"{image}: {result['caption']} (Valid: {is_valid})");
        } else {
            print(f"{image}: Failed - {result['error']}");
        }
    }
}