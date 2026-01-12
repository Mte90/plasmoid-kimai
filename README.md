# Kimai Tracker Plasmoid

A KDE Plasma widget (plasmoid) for tracking time with Kimai, allowing you to manage your time entries directly from your desktop panel or widgets.

## Introduction

Kimai Tracker is a KDE Plasma widget that integrates with [Kimai](https://www.kimai.org/), a free and open-source time-tracking application. This plasmoid provides a convenient way to start, stop, and manage time tracking entries without leaving your KDE Plasma desktop environment. It's designed for developers, freelancers, and anyone who needs to track their work hours efficiently.

## Installation from Git

### Prerequisites

- KDE Plasma 5 or later
- Git

### Manual Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Mte90/plasmoid-kimai.git
   cd plasmoid-kimai
   ```

2. **Install the plasmoid:**
   ```bash
   kpackagetool5 -i . -t Plasma/Applet
   ```
   
   If you need to update an existing installation, use:
   ```bash
   kpackagetool5 -u . -t Plasma/Applet
   ```

3. **Enable the widget:**
   - Right-click on your desktop or panel
   - Select "Add Widgets..."
   - Search for "Kimai Tracker"
   - Drag and drop it to your desired location

### Uninstallation

To remove the plasmoid:
```bash
kpackagetool5 -r com.example.kimaitracker -t Plasma/Applet
```

## Development Setup

### Required Dependencies

To develop KDE plasmoids, you need the following:

1. **Qt 5 Development Libraries:**
   ```bash
   # On Debian/Ubuntu
   sudo apt install qtbase5-dev qtdeclarative5-dev
   
   # On Fedora
   sudo dnf install qt5-qtbase-devel qt5-qtdeclarative-devel
   
   # On Arch Linux
   sudo pacman -S qt5-base qt5-declarative
   ```

2. **KDE Frameworks 5:**
   ```bash
   # On Debian/Ubuntu
   sudo apt install libkf5plasma-dev plasma-framework-dev extra-cmake-modules
   
   # On Fedora
   sudo dnf install kf5-plasma-devel extra-cmake-modules
   
   # On Arch Linux
   sudo pacman -S plasma-framework extra-cmake-modules
   ```

3. **Development Tools:**
   ```bash
   # On Debian/Ubuntu
   sudo apt install cmake build-essential
   
   # On Fedora
   sudo dnf install cmake gcc-c++ make
   
   # On Arch Linux
   sudo pacman -S cmake base-devel
   ```

### Setting Up the Development Environment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Mte90/plasmoid-kimai.git
   cd plasmoid-kimai
   ```

2. **Install the plasmoid in development mode:**
   ```bash
   kpackagetool5 -i . -t Plasma/Applet
   ```

3. **Enable QML debugging:**
   Set the following environment variable for debugging:
   ```bash
   export QML_DISABLE_OPTIMIZER=1
   ```

4. **Test your changes:**
   After making changes, update the plasmoid:
   ```bash
   kpackagetool5 -u . -t Plasma/Applet
   ```
   
   Then restart Plasma to see your changes:
   ```bash
   plasmashell --replace &
   ```

### Development Tools

- **plasmaengineexplorer**: Useful for exploring and testing Plasma data engines
- **plasmoidviewer**: Test your plasmoid in isolation
  ```bash
  plasmoidviewer -a com.example.kimaitracker
  ```

## Usage

### Initial Configuration

1. **Add the widget to your desktop or panel** as described in the Installation section.

2. **Configure API Settings:**
   - Right-click on the Kimai Tracker widget
   - Select "Configure..."
   - Enter your Kimai server URL (e.g., `https://your-kimai-instance.com`)
   - Enter your API token (you can generate this in your Kimai user settings)
   - Save the configuration

### Tracking Time

1. **Start Tracking:**
   - Click on the Kimai Tracker widget
   - Select a project and activity from the available options
   - Click "Start" to begin tracking time

2. **Stop Tracking:**
   - Click on the widget while a timer is running
   - Click "Stop" to end the current time entry

3. **View Recent Entries:**
   - The widget displays your recent time entries
   - You can review tracked hours and current activities

### Tips

- Keep the widget visible in your panel for quick access
- Use keyboard shortcuts (if configured) for faster time tracking
- Regularly sync your entries to ensure data is saved to the Kimai server

## Contributing

We welcome contributions from the community! Here's how you can help:

### Getting Started

1. **Fork the repository:**
   - Click the "Fork" button on the GitHub repository page

2. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/plasmoid-kimai.git
   cd plasmoid-kimai
   ```

3. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Making Changes

1. Make your changes following the existing code style
2. Test your changes thoroughly
3. Commit your changes with clear, descriptive commit messages:
   ```bash
   git commit -m "Add feature: description of your changes"
   ```

### Submitting a Pull Request

1. **Push your changes to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a Pull Request:**
   - Go to the original repository on GitHub
   - Click "New Pull Request"
   - Select your fork and branch
   - Provide a clear description of your changes
   - Submit the pull request

### Code Guidelines

- Follow KDE's QML coding style
- Write clear comments for complex logic
- Test your changes on a clean KDE Plasma installation
- Update documentation if you add new features

### Reporting Issues

If you find a bug or have a feature request:
- Check if the issue already exists
- Create a new issue with a clear title and description
- Include steps to reproduce (for bugs)
- Specify your KDE Plasma and Qt versions

## License

This project is licensed under the **GPL-2.0+** (GNU General Public License v2.0 or later).

See the [GPL-2.0 license](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html) for more details.

---

**Note:** This plasmoid requires a working Kimai installation and valid API credentials. For more information about Kimai, visit [kimai.org](https://www.kimai.org/).
