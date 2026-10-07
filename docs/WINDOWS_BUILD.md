# Standalone Windows build

Playable folder: `D:\Pixel Monsters`

The Windows Desktop preset exports a release x86_64 build to `D:\Pixel Monsters\Pixel Monsters.exe`. The game runs directly from its executable and local PCK; the Godot editor and development project are not player dependencies. The BAT uses its own directory, so no development path is passed to the game. Its window title and executable product metadata are Pixel Monsters, version 0.1.0.0. No console wrapper is exported.

Keep the EXE, PCK and accompanying runtime DLL together. The existing development project stays at `D:\Godot\Projects\Pixel-Monsters` with its editor tools and MCP helper intact. Godot AI's export plugin strips the MCP helper from the exported settings, without changing the development autoload.

To rebuild using installed Godot 4.7.2 export templates:

```powershell
Start-Process -FilePath 'D:\Godot\Godot.exe' -ArgumentList '--headless --path D:\Godot\Projects\Pixel-Monsters --export-release "Windows Desktop" "D:\Pixel Monsters\Pixel Monsters.exe"' -WindowStyle Hidden -Wait
Copy-Item -LiteralPath 'D:\Godot\Projects\Pixel-Monsters\tools\Play Pixel Monsters.bat' -Destination 'D:\Pixel Monsters\Play Pixel Monsters.bat'
```

Export templates came from the official Godot 4.7.2 release, with its published SHA512 checksum verified. Export excludes development documentation, tests, scripts for tools, Godot AI, gdUnit and asset placer content. Runtime dependencies from the template remain packaged.

Validation on 2026-10-07:

- Release export exited with code 0 and produced the EXE/PCK/runtime DLL.
- Running the exported EXE headlessly for 120 ticks exited with code 0 and reported exactly 1000 + 1000 body cubes, with no runtime errors or MCP helper startup.
- Running the BAT created a responsive native game window titled exactly Pixel Monsters.
- The launched process path was D:\Pixel Monsters\Pixel Monsters.exe, and its command line contained only that executable. No editor/project manager or F5/F6 step was used.
- The standalone game was left running after validation.

Headless export emitted existing asset placer editor shutdown/resource warnings. These did not affect the release export or the clean standalone runtime check. No gameplay code was changed for this build task.
