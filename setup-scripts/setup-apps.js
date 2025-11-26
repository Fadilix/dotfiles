import { spawn } from "node:child_process";

const packages = [
  // code
  "visual-studio-code-bin",
  "zen-browser-bin",
  "jetbrains-toolbox",
  "neovim",

  // linux
  "vi",
  "vim",
  "more",
  "less",

  "downgrade",

  // hyprland plugins
  "hyprsunset",
  "pyprland",
];

const installPackages = async (packages) => {
  for (let pkg of packages) {
    const installer = spawn("yay", ["-S", pkg, "--noconfirm"], {
      stdio: "inherit",
    });

    await new Promise((resolve, reject) => {
      installer.on("close", (code) => {
        if (code === 0) {
          console.log(`${pkg} Installed successfully`);
          resolve();
        } else {
          console.log(`Failed to install ${pkg} (exit code ${code}`);
          resolve();
        }
      });
    });
  }
};

installPackages(packages);
