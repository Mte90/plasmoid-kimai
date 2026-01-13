# Kimai Tracker Plasmoid

A KDE Plasma widget (plasmoid) for tracking time with Kimai, allowing you to manage your time entries directly from your desktop panel or widgets.

## Introduction

Kimai Tracker is a KDE Plasma widget that integrates with [Kimai](https://www.kimai.org/), a free and open-source time-tracking application. This plasmoid provides a convenient way to start, stop, and manage time tracking entries without leaving your KDE Plasma desktop environment. It's designed for developers, freelancers, and anyone who needs to track their work hours efficiently.

## Installation and Development

### Prerequisites

- KDE Plasma 6 or later
- Git

**For development only:**
- Qt 6 Development Libraries
- KDE Frameworks 6
- Development Tools (cmake, build-essential)

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Mte90/plasmoid-kimai.git
   cd plasmoid-kimai
   ```

2. **For development, install dependencies:**
   ```bash
   # On Debian/Ubuntu
   sudo apt install qtbase6-dev qtdeclarative5-dev libkf5plasma-dev plasma-framework-dev extra-cmake-modules cmake build-essential
   
   # On Fedora
   sudo dnf install qt6-qtbase-devel qt5-qtdeclarative-devel kf5-plasma-devel extra-cmake-modules cmake gcc-c++ make
   
   # On Arch Linux
   sudo pacman -S qt6-base qt6-declarative plasma-framework extra-cmake-modules cmake base-devel
   ```

3. **Install the plasmoid:**
   ```bash
   kpackagetool6 -i . -t Plasma/Applet
   ```
   
   To update an existing installation:
   ```bash
   kpackagetool6 -u . -t Plasma/Applet
   ```

4. **Enable the widget:**
   - Right-click on your desktop or panel
   - Select "Add Widgets..."
   - Search for "Kimai Tracker"
   - Drag and drop it to your desired location

### Development Workflow

After making changes, update the plasmoid:
```bash
kpackagetool6 -u . -t Plasma/Applet
plasmashell --replace &
```

For QML debugging, set:
```bash
export QML_DISABLE_OPTIMIZER=1
```

**Testing the compact representation (panel icons):**
```bash
# Use plasmoidviewer with parameters to simulate a horizontal panel
plasmoidviewer -a com.mte90.kimaitracker -l topedge -f horizontal

# Or test in an actual panel for most accurate results
kpackagetool6 -u . -t Plasma/Applet
plasmashell --replace &
# Then add/configure the widget in your actual panel
```

**Testing the full representation (popup):**
```bash
# plasmoidviewer can be used for testing the popup interface
plasmoidviewer -a com.mte90.kimaitracker
```

### Uninstallation

```bash
kpackagetool6 -r com.mte90.kimaitracker -t Plasma/Applet
```

## Usage

### Initial Configuration

1. **Add the widget to your desktop or panel** as described in the Installation section.

2. **Configure API Settings:**
   - Right-click on the Kimai Tracker widget
   - Select "Configure..."
   - Go to the "General" tab
   - Enter your Kimai server URL (e.g., `https://your-kimai-instance.com`)
   - Enter your API token (you can generate this in your Kimai user settings)
   - Click "Test Connection" to verify your settings
   - Save the configuration

3. **Configure Quick Actions (Recommended):**
   - Right-click on the Kimai Tracker widget
   - Select "Configure..."
   - Go to the "Quick Actions" tab
   - Click on a project from the left list
   - Check the activities you want as quick actions from the right list
   - You can select multiple project-activity combinations
   - Save the configuration
   - **Multiple icons will now appear in your panel**, one for each configured quick action

### Tracking Time

#### Quick Actions (Multiple Panel Icons)

Once you have configured quick actions, you'll see **multiple icons in the panel**, one for each activity:

1. **Start Tracking:**
   - **Left-click** any quick action icon to start tracking that specific activity
   - The icon changes from play to stop when tracking is active
   - Hover over an icon to see which project-activity it represents

2. **Stop Tracking:**
   - **Left-click** the stop icon (of the currently tracking activity) to stop
   - The icon changes back to a play icon

3. **No Quick Actions Configured:**
   - If no quick actions are configured, a single icon is shown
   - Click it to open the full widget for manual selection

#### Manual Selection (Full Widget)

1. **Start Tracking:**
   - **Right-click** any panel icon and the widget will expand
   - Or click the single icon if no quick actions are configured
   - Select a project and activity from the available options
   - Click "Start" to begin tracking time

2. **Stop Tracking:**
   - Click on the widget while a timer is running
   - Click "Stop" to end the current time entry

3. **View Recent Entries:**
   - The widget displays your recent time entries
   - You can review tracked hours and current activities

### Tips

- **Configure quick actions** for your most frequently used project-activity combinations
- **Each quick action gets its own icon** in the panel for instant one-click access
- Keep the widget visible in your panel for quick access
- Hover over icons to see which activity they represent
- Regularly sync your entries to ensure data is saved to the Kimai server

## Contributing

We welcome contributions! Here's how to help:

1. **Fork the repository** on GitHub

2. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/plasmoid-kimai.git
   cd plasmoid-kimai
   ```

3. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make your changes** following the existing code style

5. **Test thoroughly** and commit with clear messages

6. **Push and create a Pull Request** on GitHub

### Guidelines

- Follow KDE's QML coding style
- Write clear comments for complex logic
- Test on a clean KDE Plasma installation
- Update documentation for new features

## License

This project is licensed under **GPL-3.0**.

---

**Note:** This plasmoid requires a working Kimai installation and valid API credentials. For more information about Kimai, visit [kimai.org](https://www.kimai.org/).
