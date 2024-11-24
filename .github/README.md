# reader

<div align="center">
    <img src="../reader/Assets.xcassets/AppIcon.appiconset/256x256.png" width="200" height="200">
</div>

reader is a simple book library and reading tracker app for macOS, designed and developed in Swift. It was purposefully built for personal use and to share with a friend, making it easier to manage book collections and track reading progress.

![Screenshot](./assets/img01.png)

[![Download](https://img.shields.io/badge/download-latest-brightgreen?style=flat-square)](https://github.com/chippokiddo/reader/releases/latest)
![Platform](https://img.shields.io/badge/platform-macOS-blue?style=flat-square)
![Requirements](https://img.shields.io/badge/requirements-macOS%2014%2B-fa4e49?style=flat-square)
[![License](https://img.shields.io/github/license/chippokiddo/reader?style=flat-square)](../LICENSE)

## Features

- Add and organize books in your personal library
- Notes section: jot down thoughts or annotations
- Quotes section: save memorable excerpts
- Track reading statuses: unread, reading, or read
- Sort, search, or filter your personal library with ease

## Install

- Download the `reader.zip` file from the [latest release](https://github.com/chippokiddo/reader/releases/latest)
- Unzip the file and move `reader.app` into your `Applications` folder
- Control-click or right-click the app and select 'open'

> [!NOTE]
> Since reader is not notarized, macOS Gatekeeper may block the app:
>
> - Go to **System Settings > Privacy & Security**
> - Scroll down and locate the prompt for `reader.app`
> - Click 'open anyway'

## Compiling reader

If you'd like to compile the app yourself, follow these steps:

1. Open Terminal and run:

   ```bash
   git clone https://github.com/chippokiddo/reader.git
   cd reader
   ```

2. Create a New Xcode Project

   - Open Xcode
   - Select **Create a new Xcode project**
   - Choose **App** under the macOS tab and click **Next**.
   - Enter the following details:
     - Product Name: `reader`
   - Set the **Language** to **Swift** and **User Interface** to **SwiftUI**.
   - Choose a location to save the project.

> [!IMPORTANT]
>
> Ensure you are running **macOS 14 or higher** and have **Xcode 16 or later** installed, as the project uses **Swift 6**

3. Locate the cloned repository and open the `reader` directory in Finder.

4. Drag and drop the following folders and files into your Xcode project:

   ```
   .
   └── reader/
       ├── Assets.xcassets
       ├── ContentView.swift
       ├── Helpers
       ├── Info.plist
       ├── Merriweather
       ├── Modells
       ├── Preview Content
       ├── reader.entitlements
       ├── Subviews
       ├── Utils
       └── Views
   ```

   - When prompted, ensure the **Copy items if needed** option is checked and click **Finish**.

5. Add Your Google Books API Key

   - The app uses the Google Books API to fetch book data. You need to provide your own API key for the app to function.

   - Open the `DataManager.swift` file located in the `Utils` folder.

   - Locate the placeholder for the API key:

     ```swift
     private let apiKey = "GOOGLE_BOOKS_API_KEY"
     ```

   - Replace `"GOOGLE_BOOKS_API_KEY"` with your actual Google Books API key. You can obtain a key from the [Google Cloud Console](https://console.cloud.google.com).

6. Configure Signing to Run Locally

   - In Xcode, open the **Signing & Capabilities** tab for the `reader` target.

   - Under **Signing**, set the **Team** dropdown to **None**.

   - Under **Signing → macOS**, set the **Signing Certificate** to **Sign to Run Locally**.

7. Press `⌘ + R` to build and run the app on your Mac.

# Permissions

reader requires network access to fetch book data via the Google Books API.

## Contribute

Contributions are welcome! Follow these steps to contribute:

1. Fork the repository
2. Create a branch with your feature or bug fix
3. Submit a pull request for review

## Acknowledgements

reader uses the [Merriweather font](https://fonts.google.com/specimen/Merriweather), made available under the [Open Font License](../reader/Merriweather/OFL.txt).
