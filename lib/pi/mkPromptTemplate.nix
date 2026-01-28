# mkPromptTemplate - Build a pi prompt template file
#
# Creates a prompt template file that can be invoked with /name in pi
{
  lib,
  pkgs,
}:

{
  # Required
  name, # Template name (becomes /name command)
  content, # Markdown string (template body)

  # Optional
  description ? null, # Shown in autocomplete
}:

let
  # Build file content with optional frontmatter
  fileContent =
    if description != null then
      ''
        ---
        description: ${description}
        ---
        ${content}''
    else
      content;

in
pkgs.writeTextDir "${name}.md" fileContent
