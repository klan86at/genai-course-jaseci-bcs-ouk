# # CCG Node Types (defined elsewhere or inline)
# walker BuildCCG {
#     has file_path: str;
#     has ast_units: list[dict] = [];  # Output from Tree-sitter (or mock)
#     has node_map: dict[str, node] = {};  # Tracks created nodes: "file:func" → node

#     # Entry: triggered when spawned on a CodeAnalyzer (or file node)
#     can build_ccg with CodeAnalyzer entry {
#         self.file_path = visitor.target_file;
#         self.ast_units = visitor.parsed_ast;  # Assume this is provided

#         # Create module node for this file
#         mod_name = self.file_path.split("/")[-1].replace(".py", "");
#         mod_node = here ++> Module(name=mod_name, file_path=self.file_path);

#         for unit in self.ast_units {
#             match unit.type {
#                 "function" => {
#                     fn_node = mod_node +>:Contains:+> Function(
#                         name=unit.name,
#                         file_path=self.file_path
#                     );
#                     self.node_map[f"{self.file_path}:{unit.name}"] = fn_node;
#                 }
#                 "class" => {
#                     cls_node = mod_node +>:Contains:+> Class(
#                         name=unit.name,
#                         file_path=self.file_path,
#                         bases=unit.bases ?? []
#                     );
#                     self.node_map[f"{self.file_path}:{unit.name}"] = cls_node;
#                 }
#                 "call" => {
#                     caller_key = f"{self.file_path}:{unit.caller}";
#                     callee_key = unit.callee.includes(":")
#                         ? unit.callee
#                         : f"{self.file_path}:{unit.callee}";

#                     if caller_key in self.node_map and callee_key in self.node_map {
#                         self.node_map[caller_key] +>:Calls:+> self.node_map[callee_key];
#                     }
#                 }
#                 "inheritance" => {
#                     child_key = f"{self.file_path}:{unit.child}";
#                     for base in unit.bases {
#                         // Assume base is fully qualified or resolved
#                         base_key = base.includes(":") ? base : f"{self.file_path}:{base}";
#                         if child_key in self.node_map and base_key in self.node_map {
#                             self.node_map[child_key] +>:Inherits:+> self.node_map[base_key];
#                         }
#                     }
#                 }
#             }
#         }

#         print(f"✅ CCG built for {self.file_path}");
#         disengage;
#     }
# }