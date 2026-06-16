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
  nodejs = mkWelcomeText {
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

  flutter-nixdev = mkWelcomeText {
    path = ./flutter;
    name = "Flutter Template";
    description = ''
      A flutter project template that comes bundled
    '';
  };
}
// nix-templates.templates
