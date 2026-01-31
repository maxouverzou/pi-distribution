# mkPiEnv - Assemble a complete .pi/agent/ directory tree
#
# Produces a single derivation whose $out/ mirrors the layout expected by pi:
#   skills/<name>        → skill derivation (symlink)
#   prompts/<name>.md    → prompt file inside its derivation (symlink)
#   extensions/<path>    → extension file or directory (symlink)
#   settings.json        → written inline when settings != null
#
# Can be used standalone (project-local flakes via ln -sf) or as the source
# for Home Manager's recursive directory symlink.
{
  lib,
  pkgs,
}:

{
  skills ? [ ],     # List of skill derivations (mkSkill / mkSkillFromGeminiCommand / mkSkillWithDeps)
  prompts ? [ ],    # List of prompt derivations (mkPromptTemplate)
  extensions ? [ ], # List of extension derivations (mkExtension / mkExtensionWithDeps)
  settings ? null,  # Attribute set → settings.json, or null to leave unmanaged
}:

let
  # ---------------------------------------------------------------------------
  # Name-extraction helpers
  # ---------------------------------------------------------------------------

  # Skills: use passthru.skillName if present, else parse "skill-<name>-validated"
  getSkillName =
    drv:
    if drv ? passthru && drv.passthru ? skillName then
      drv.passthru.skillName
    else
      let
        drvName = drv.name or (builtins.baseNameOf drv);
      in
      lib.removeSuffix "-validated" (lib.removePrefix "skill-" drvName);

  # Prompts: derivation name is "<name>.md" (from writeTextDir).
  # Strip .md to get the base name; the actual file is ${drv}/${baseName}.md
  getPromptBaseName =
    drv:
    let
      drvName = drv.name or (builtins.baseNameOf drv);
    in
    lib.removeSuffix ".md" drvName;

  # Extensions: use passthru when available, fall back to name parsing
  getExtensionInfo =
    drv:
    let
      hasPassthru = drv ? passthru;
      extName =
        if hasPassthru && drv.passthru ? extensionName then
          drv.passthru.extensionName
        else
          let
            drvName = drv.name or (builtins.baseNameOf drv);
            withoutPrefix = lib.removePrefix "extension-" drvName;
          in
          builtins.head (lib.splitString "-" withoutPrefix);
      extPath =
        if hasPassthru && drv.passthru ? extensionPath then
          drv.passthru.extensionPath
        else
          extName;
      isDir =
        if hasPassthru && drv.passthru ? isDirectoryExtension then
          drv.passthru.isDirectoryExtension
        else
          !(lib.hasSuffix ".ts" extPath);
    in
    {
      name = extName;
      path = extPath;
      inherit isDir;
    };

  # ---------------------------------------------------------------------------
  # Shell snippets for each category
  # ---------------------------------------------------------------------------

  skillLinks = lib.concatStringsSep "\n" (
    map (
      drv:
      let
        name = getSkillName drv;
      in
      "ln -s ${drv} $out/skills/${name}"
    ) skills
  );

  promptLinks = lib.concatStringsSep "\n" (
    map (
      drv:
      let
        baseName = getPromptBaseName drv;
      in
      "ln -s ${drv}/${baseName}.md $out/prompts/${baseName}.md"
    ) prompts
  );

  extensionLinks = lib.concatStringsSep "\n" (
    map (
      drv:
      let
        info = getExtensionInfo drv;
      in
      "ln -s ${drv}/${info.path} $out/extensions/${info.path}"
    ) extensions
  );

  settingsSnippet = lib.optionalString (settings != null) ''
    cat > $out/settings.json << 'SETTINGSEOF'
    ${builtins.toJSON settings}
    SETTINGSEOF
  '';
in
pkgs.runCommand "pi-env"
  { }
  ''
    mkdir -p $out/skills $out/prompts $out/extensions

    ${skillLinks}
    ${promptLinks}
    ${extensionLinks}
    ${settingsSnippet}
  ''
