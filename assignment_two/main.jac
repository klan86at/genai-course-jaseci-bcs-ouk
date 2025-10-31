import from agents.repo_mapper { RepoMapper }
import from agents.code_analyzer { CodeAnalyzer }
import from agents.docgenie { DocGenie }

walker CodeGenius(agent) {
    has github_url: str;

    def route_to_node(phase: str, context: str) -> RoutingNodes by llm();

    can start with `root entry {
        next = self.route_to_node("init", self.github_url);
        self._go_to(next);
    }

    can resume with RepoMapper exit {
        next = self.route_to_node("mapped", visitor.readme_context);
        self._go_to(next);
    }

    can resume with CodeAnalyzer exit {
        next = self.route_to_node("analyzed", str(keys(visitor.code_metadata)));
        self._go_to(next);
    }

    can finalize with DocGenie exit {
        print("✅ Documentation complete.");
        disengage;
    }

    def _go_to(target: RoutingNodes) -> None {
        name = switch (target) {
            RoutingNodes.REPO_MAPPER => "RepoMapper",
            RoutingNodes.CODE_ANALYZER => "CodeAnalyzer",
            RoutingNodes.DOC_GENIE => "DocGenie",
            _ => ""
        };
        node = root -->(`?{name});
        if node: node[0] spawn self;
        else: disengage;
    }
}