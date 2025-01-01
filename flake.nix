{
  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        # pkgs.xorg.libX11
        # pkgs.xorg.libXinerama
        # pkgs.xorg.libXcursor
        # pkgs.xorg.libXrandr
        pkgs.glfw-wayland
        pkgs.libGL
        # zig-overlay.packages.${system}.master
        # zls.packages.${system}.default
        pkgs.zig
        pkgs.zls

        pkgs.wayland
        pkgs.wayland-protocols
        pkgs.wayland-scanner
        pkgs.libxkbcommon
      ];
    };
  };
}
