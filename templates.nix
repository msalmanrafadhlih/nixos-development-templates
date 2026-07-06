{ nix-templates, ... }:
let
  mkWelcomeText =
    {
      name,
      description,
      path,
      buildTools ? null,
      additionalSetupInfo ? null,
    }:
    {
      inherit path;
      description = name;
      welcomeText = ''
        # ${name}
        ${description}

        ${
          if buildTools != null then
            ''
              Comes bundled with:
              ${builtins.concatStringsSep ", " buildTools}
            ''
          else
            ""
        }
        ${
          if additionalSetupInfo != null then
            ''
              ## Additional Setup
              To set up the project run:
              ```sh
              flutter create .
              ```
            ''
          else
            ""
        }
        ## Other tips
        If you use direnv run:

        ```
            echo "use flake" > .envrc
        ```

        For a quick license setup use licensor:

            ```
                # SPDX is the license id like MIT or GPL-3.0
                nix-shell -p license-cli --command "license text SPDX > LICENSE"
            ```

        ## More info
        - [flake-utils Github Page](https://github.com/numtide/flake-utils)
      '';
    };
in
{
  bun-template = mkWelcomeText {
    path = ./bun;
    name = "Bun Template";
    description = ''
      A basic Bun application template with a package build.
    '';
    buildTools = [
      "bun"
    ];
  };

  nodejs-template = mkWelcomeText {
    path = ./nodejs;
    name = "Nodejs Template";
    description = ''
      A basic Node application template with a package build.
    '';
    buildTools = [
      "nodejs_24"
      "pnpm"
    ];
  };

  flutter-template = mkWelcomeText {
    path = ./flutter;
    name = "Flutter Template";
    description = ''
      A flutter project template that comes bundled
    '';
  };

  rust-template = mkWelcomeText {
    path = ./rust;
    name = "Basic Rust Template";
    description = ''
      A Rust project template that comes bundled
    '';
    buildTools = [
      "All esential rust tools"
      "fenix"
      "naesrk"
    ];
  };

  tauri-mobile = mkWelcomeText {
    path = ./tauri-mobile;
    name = "Rust -- tauri-mobile Template development";
    description = ''
      A Rust project template that comes bundled 
    '';
    buildTools = [
      "All esential rust tools"
    ];
  };

  rustling = mkWelcomeText {
    path = ./rustling;
    name = "Rust -- learning";
    description = ''
      A Rust Learning bundle
    '';
    buildTools = [
      "All esential rust for learning"
    ];
  };
}
// nix-templates.templates
