# Upload this project to GitHub

The `lab-rat-github` folder contains source, tests, documentation, and artwork. It has no personal experiment data, compiled app, private credentials, or build cache.

## GitHub website

1. Create an empty repository named `lab-rat` (or a name you prefer).
2. Choose **uploading an existing file** or **Add file → Upload files**.
3. Upload the **contents** of `lab-rat-github`, keeping its directory structure. `README.md` and `Package.swift` belong at the repository root.
4. Make sure `.gitignore` and `.gitattributes` are included; Finder normally hides names beginning with a dot. Press **Command–Shift–.** in Finder to show them.
5. Commit the upload.

If browser upload does not preserve folders or hidden files, use GitHub Desktop or the terminal method below.

## Terminal

Create an empty GitHub repository without adding a README or other initial files. Then open a terminal in this folder and run:

```sh
git init -b main
git add .
git commit -m "Initial Lab Rat macOS app"
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
git push -u origin main
```

Replace `YOUR_USERNAME` and `YOUR_REPOSITORY` with your actual GitHub account and repository name. GitHub may ask you to sign in. There is no remote configured in the prepared folder, and nothing has been uploaded automatically.

## Optional app download

Use the separately supplied `Lab Rat Mac.zip` as a GitHub Release asset, rather than adding an `.app` to this source repository. That supplied binary is for Apple silicon and macOS 14+ and is locally signed. For a public release with standard macOS installation behavior, sign with your Developer ID and notarize through Apple first.

Choose a license before inviting others to reuse or distribute the project. No license has been selected on your behalf.
