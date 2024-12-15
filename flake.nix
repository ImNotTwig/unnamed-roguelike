{
  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pkgs.zig
        pkgs.zls
        pkgs.xorg.libX11
        pkgs.xorg.libXinerama
        pkgs.xorg.libXcursor
        pkgs.xorg.libXrandr
        pkgs.xorg.libXi.dev
        pkgs.xwayland
        pkgs.glfw
        pkgs.glfw-wayland
        pkgs.libGL
      ];
    };
  };
}
