Immunia (Android Version)

----

Made a few updates to the game:

- Darker outer background `poke(0x03FF8,15)`
- Hide mouse cursor `poke(0x3ffb,1) -- 128 deafult`
- Updated tutorial (no background and changed text)

The big update is that I built a custom tic80lua.wasm file in order to fordce integer scale default off...

Here's how I did that...

----

https://github.com/nesbox/TIC-80/discussions/2386

Thanks to @soxfox42 for helping me with this.

How I rebuilt the tic80lua.wasm and tic80lua.js files for version 1.1.2837

I already had my game exported without editors...

`export html game alone=1`

Follow init build instructions from wiki (Linux... https://github.com/nesbox/TIC-80#build-instructions):

`sudo apt-get install g++ git cmake ruby-full libglvnd-dev libglu1-mesa-dev freeglut3-dev libasound2-dev -y`

`git clone --recursive https://github.com/nesbox/TIC-80`

`cd TIC-80`

I wanted to work with a specific version, so...

`git checkout be42d6f146cfa520b9b1050feba10cc8c14fb3bd`

Then I made my source code change in src/studio/config.c

`#define INTEGER_SCALE_DEFAULT false`

Install Emscripten SDK. (https://emscripten.org/docs/getting_started/downloads.html)

`cd build`

`emcmake cmake -DBUILD_SDLGPU=On -DCMAKE_BUILD_TYPE=MinSizeRel -DBUILD_STUB=On ..`

`cmake --build . --parallel`

Output is in build/bin as tic80lua.wasm and tic80lua.js

Replace the files in the export...

`cp bin/tic80lua.wasm /exported/game/`
`cp bin/tic80lua.js /exported/game/tic80.js`

----

I had to pull a fresh clone for this (emscripten) as I'd somehow messed up the build settings in a previous pull while testing.

----

Building the APK with Capacitor...

Helpful docs:

https://capacitorjs.com/docs/getting-started

https://capacitorjs.com/docs/android

https://capacitorjs.com/docs/cli

https://capacitorjs.com/docs/core-apis/android

----

`npm init @capacitor/app`

{fill out questions}

`cd my-app`

`npm install`

`npm install @capacitor/android`

`npx cap add android`

{copy tic web files to my-app/dist}

`npx cap sync`

`npx cap run android`

Tips:

To make updates make your changes in ./dist then run `npx cap sync`
List emulators `npx cap run --list android`
Run specific emulator `npx cap run --target [id] android`

To install on your actual phone...
 - Enable developer options
 - Enable USB debugging
 - Check the list: `npx cap run --list android`
 - Target your device: `npx cap run --target [id] android`

Update splash screen and icon: https://capacitorjs.com/docs/guides/splash-screens-and-icons
(updated file in _work/app-resources then copied to android/capacitor/my-app/resources then run npx capacitor-assets generate)

Final build:
https://capacitorjs.com/docs/cli/commands/build

For final build need all signing options: (Keystore Path, Keystore Password, Keystore Key Alias, Keystore Key Password)

https://developer.android.com/studio/publish/app-signing

`keytool -genkey -v -keystore your_keystore_name.keystore -alias your_alias_name -keyalg RSA -keysize 2048 -validity 10000`

Final build: `npx cap build android`
