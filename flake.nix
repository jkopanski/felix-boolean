{
  description = "Adds boolean logic to Felix for synthesis of correct hardware";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    agda-stdlib = {
      url = "github:jkopanski/agda-stdlib";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    felix = {
      url = "github:jkopanski/felix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "utils";
        agda-stdlib.follows = "agda-stdlib";
      };
    };
  };

  outputs = { self, nixpkgs, utils, agda-stdlib, felix }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        standard-library = agda-stdlib.packages.${system}.default;
        felix-lib = felix.packages.${system}.default;
        agdaWithStandardLibrary = pkgs.agda.withPackages (_: [
          standard-library
          felix-lib
        ]);

      in {
        devShell = pkgs.mkShell {
          buildInputs = [
            agdaWithStandardLibrary
            pkgs.graphviz
          ];
        };

        packages.default = pkgs.agdaPackages.mkDerivation rec {
          pname = "felix-boolean";
          version = "0.0.1";
          src = ./.;

          buildInputs = [
            standard-library
            felix-lib
          ];

          # agda builder adds `dirOf evenythingFile` to includePaths
          # and it makes module name clashes
          everythingFile = "./src/Felix/Boolean/All.agda";

          buildPhase = ''
            runHook preBuild
            agda -i. ${everythingFile}
            runHook postBuild
          '';

          meta = with pkgs.lib; {
            description = "Adds boolean logic to Felix for synthesis of correct hardware.";
            homepage = "https://github.com/conal/felix-boolean";
            # no license file, all rights reserved?
            # license = licenses.mit;
            # platforms = platforms.unix;
            # maintainers = with maintainers; [ ];
          };
        };
      }
    );
}
