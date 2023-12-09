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