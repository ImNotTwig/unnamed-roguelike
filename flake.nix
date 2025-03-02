{
  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pkgs.glfw-wayland
        pkgs.libGL

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
