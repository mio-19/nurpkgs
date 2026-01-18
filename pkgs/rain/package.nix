{
  lib,
  flutter338,
  fetchFromGitHub,
  runCommand,
  yq-go,
  _experimental-update-script-combinators,
  gitUpdater,
  dart,
}:

flutter338.buildFlutterApplication rec {
  pname = "rain";
  version = "1.3.9";

  src = fetchFromGitHub {
    owner = "darkmoonight";
    repo = "Rain";
    tag = "v${version}";
    hash = "sha256-w8bDsb7SfXfnf8Ie1axpW5A+DpwlNendDsbUYoMqHTk=";
  };

  pubspecLock = lib.importJSON ./pubspec.lock.json;
  gitHashes = lib.importJSON ./git-hashes.json;

  # Ensure Isar can dlopen libisar.so when the binary is invoked via a symlink.
  extraWrapProgramArgs = ''
    --prefix LD_LIBRARY_PATH : $out/app/${pname}/lib
  '';

  passthru = {
    pubspecSource =
      runCommand "pubspec.lock.json"
        {
          inherit src;
          nativeBuildInputs = [ yq-go ];
        }
        ''
          yq eval --output-format=json --prettyPrint $src/pubspec.lock > "$out"
        '';
    updateScript = _experimental-update-script-combinators.sequence [
      (
        (gitUpdater {
          ignoredVersions = ".*(rc|beta).*";
          rev-prefix = "v";
        })
        // {
          supportedFeatures = [ ];
        }
      )
      (
        (_experimental-update-script-combinators.copyAttrOutputToFile "rain.pubspecSource" ./pubspec.lock.json)
        // {
          supportedFeatures = [ ];
        }
      )
      {
        command = [
          dart.fetchGitHashesScript
          "--input"
          ./pubspec.lock.json
          "--output"
          ./git-hashes.json
        ];
        supportedFeatures = [ ];
      }
    ];
  };

  meta = {
    description = "Weather application";
    homepage = "https://github.com/darkmoonight/Rain";
    license = lib.licenses.mit;
    mainProgram = "rain";
    platforms = lib.platforms.linux;
  };
}
