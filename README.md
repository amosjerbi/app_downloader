# muOS App Downloader

Welcome to the muOS App Downloader! This application is designed to simplify the process of downloading apps for the muOS platform. Built using the Godot game engine, this app runs as a port through Portmaster, allowing you to easily access and manage your favorite applications.

## Features

- **Download Apps**: Seamlessly download applications from GitHub releases.
- **Dynamic App Listing**: Automatically fetches the list of available apps from `apps_listing.json` hosted in the repository.
- **User-Friendly Interface**: Designed with simplicity in mind, making it easy for users to find and download apps.

## Requirements

- **muOS**: Ensure you have the muOS operating system installed.
- **Portmaster**: This app runs as a port through Portmaster. Make sure you have it set up correctly.
- **Godot FRT Runtime 4.1.3**: The app is built using Godot, so ensure you have the necessary runtime.

## Installation

1. Download the [latest release](https://github.com/andersmmg/app_downloader/releases/latest)

2. Transfer the .muxzip file to your handhelds `SD1 (mmc)/ARCHIVE` directory

3. Open the **Archive Manager** app.

4. Select the transfered archive and select it to install.

3. Launch the app via the **Applications** menu!

## Usage

1. Upon launching the app, it will automatically fetch the app listing from the remote `apps_listing.json` hosted in the repository.
2. Browse through the available applications, descriptions will show on the right along with a preview image if there is one.
3. Press (A) on the desired app to initiate the download from its GitHub release.

### Example of `apps_listing.json`:

The app listing is fetched from the following structure:

```json
[
    {
        "title": "App Downloader",
        "image_url": "https://cdn.jsdelivr.net/gh/andersmmg/app_downloader/project/splash.png",
        "description": "A muOS application for downloading apps directly from their GitHub releases.",
        "repo": "andersmmg/app_downloader"
    }
]
```

## Adding New Apps

To add a new app to the listing, you can create a pull request with the updated `apps_listing.json` file. Ensure that the new app follows the existing structure for proper functionality. Image previews are not required, but are encouraged to enhance the user experience.

## Contributing

Contributions are welcome! If you have suggestions for improvements or new features, feel free to open an issue or submit a pull request.

1. Fork the repository.
2. Create your feature branch (`git checkout -b feat/feature_name`).
3. Commit your changes (`git commit -m 'Add some feature'`).
4. Push to the branch (`git push origin feat/feature_name`).
5. Open a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Godot Engine](https://godotengine.org/) for providing a powerful game engine.
- [Portmaster](https://portmaster.games/) for enabling easy porting of applications.

## Contact

For any inquiries or support, please reach out by creating a GitHub issue.
