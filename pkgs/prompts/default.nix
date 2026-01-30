# Prompt templates for pi coding agent
#
# These prompts can be invoked with /name in the pi editor
{ pkgs }:

{
  # Git commit - intelligent conventional commits
  git-commit = import ./git-commit.nix { inherit pkgs; };
}
