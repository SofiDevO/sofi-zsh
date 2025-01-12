# Sofi Zsh Installer Script 🦝

This script automates the installation and configuration of **Zsh**, **Oh My Zsh**, the **Powerlevel10k** theme, and popular plugins for Ubuntu systems.

---

## Installation

### Option 1: Execute the script directly from GitHub
Run the following command to execute the script directly without cloning the repository:

```bash

curl -fsSL https://raw.githubusercontent.com/SofiDevO/sofi-zsh/main/sofi-zsh.sh | sudo bash

```

### Option 2: Clone the repository and run the script
If you prefer to clone the repository and execute the script manually, follow these steps:

1. Clone the repository:
   ```bash
   git clone https://github.com/SofiDevO/sofi-zsh.git ~/sofi-zsh
   ```

2. Run the script:
   ```bash
   sudo bash ~/sofi-zsh/sofi-zsh.sh
   ```

---

> [!IMPORTANT]
> Important: Install the MesloLGS NF Font

To display icons correctly in the **Powerlevel10k** theme, you must install the **MesloLGS NF** font.

### Steps to Install:

1. Download the font:
   - [MesloLGS NF Regular.ttf](https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf)

2. Install the font:
   - Open the downloaded `.ttf` file and click the **Install** button.

3. Set the font in your terminal:
   - For **GNOME Terminal** (default terminal in Ubuntu):
     1. Open the terminal preferences.
     2. Go to the **Text** or **Appearance** section.
     3. Select **MesloLGS NF** as the font.

   - For **other terminals**, refer to their respective documentation on setting custom fonts.

---

## What does this script do?
- Installs **Zsh**, **Git**, and **Curl**.
- Sets **Zsh** as the default shell.
- Installs **Oh My Zsh**.
- Configures the **Powerlevel10k** theme.
- Installs popular plugins:
  - `zsh-autosuggestions`
  - `zsh-syntax-highlighting`
  - `fast-syntax-highlighting`
  - `zsh-autocomplete`

---

## Support My Work 💜

If you found this project useful and would like to support my work, consider donating or sponsoring me:

<p align="center">
  <a href="https://github.com/sponsors/SofiDevO" target="_blank">
    <img src="https://img.shields.io/badge/Sponsor%20me%20on%20GitHub-30363D?style=for-the-badge&logo=github-sponsors&logoColor=#EA4AAA" alt="GitHub Sponsors">
  </a>
  <a href="https://ko-fi.com/sofidev" target="_blank">
    <img src="https://img.shields.io/badge/Buy%20me%20a%20coffee-Ko--fi-ff5e5b?style=for-the-badge&logo=ko-fi&logoColor=white" alt="Ko-fi">
  </a>
</p>

Your support helps me create more open-source tools like this one! Thank you! 🙌

---

## Contribution
Feel free to contribute to this project! Fork the repository, make your changes, and submit a pull request.

---

## Credits
This script is inspired by the Zsh community and its amazing contributors. Special thanks to the developers of **Oh My Zsh**, the plugins used in this script, and the **Powerlevel10k** theme.

---

### Notes
The buttons use `shields.io` to generate the visuals. They link directly to **GitHub Sponsors** and **Ko-fi**.

Let me know if you need further refinements! 🦝
