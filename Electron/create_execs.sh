npm install -g electron-packager
read -p "Enter Build Version" build_version
electron-packager ./ VidMapper --platform=darwin --arch=x64 --overwrite --build-version=$build_version --icon=./assets/icons/logo.icns --out=./releases
electron-packager ./ VidMapper --platform=win32 --arch=x64 --overwrite --build-version=$build_version --icon=./assets/icons/logo.ico --out=./releases