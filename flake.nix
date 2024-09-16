{
  description = "WWW challenge environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs    = import nixpkgs {  
        inherit system;  
        config = {
            permittedInsecurePackages = [
              "python-2.7.18.7"
              "python-2.7.18.7-env"
            ];
          };
        };
    in
    {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [ 
          (python2.withPackages (p: with p; [
            pip
            setuptools
          ]))

          xorg.libX11
          xorg.libXi
          xorg.libXcursor
          xorg.libXrandr
          xdotool

          autoPatchelfHook
        ];

        shellHook = ''
          export PIP_PREFIX="$(pwd)/venv"
          export PYTHONPATH="$(pwd)/venv/lib/python2.7/site-packages:$PYTHONPATH"
          export PATH=$PWD:$PATH
          export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${ pkgs.lib.makeLibraryPath [ 
            pkgs.xorg.libX11 
            pkgs.xdotool 
          ]}"

          # Use the modified config to use the current directory instead of /{home,opt}/www
          mkdir -p ~/.previous
          cp previous.cfg ~/.previous/previous.cfg

          # Create the patched previous for nix
          if [ ! -f previous.patched ]; then
            cp previous previous.patched

            patchelf \
              --replace-needed libSDL2-2.0.so.0  ${pkgs.SDL2}/lib/libSDL2.so \
              --replace-needed libpthread.so.0 ${pkgs.glibc}/lib/libpthread.so.0 \
              --replace-needed libreadline.so.6 ${pkgs.readline}/lib/libreadline.so \
              --replace-needed libz.so.1 ${pkgs.zlib}/lib/libz.so \
              --replace-needed libpng16.so.16 ${pkgs.libpng}/lib/libpng.so \
              --replace-needed libpcap.so.0.8 ${pkgs.libpcap}/lib/libpcap.so \
              previous.patched

            autoPatchelf previous.patched
          ]

          # Install the python requirements
          pip install -r requirements.txt
        '';
      };
    });
}

