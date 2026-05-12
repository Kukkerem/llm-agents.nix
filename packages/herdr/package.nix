{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  flake,
  versionCheckHook,
  versionCheckHomeHook,
}:

let
  versionData = builtins.fromJSON (builtins.readFile ./hashes.json);
  inherit (versionData) version hashes;

  assetMap = {
    x86_64-linux = "herdr-linux-x86_64";
    aarch64-linux = "herdr-linux-aarch64";
    x86_64-darwin = "herdr-macos-x86_64";
    aarch64-darwin = "herdr-macos-aarch64";
  };

  platform = stdenv.hostPlatform.system;
  assetName = assetMap.${platform} or (throw "Unsupported system for herdr: ${platform}");

  src = fetchurl {
    url = "https://github.com/ogulcancelik/herdr/releases/download/v${version}/${assetName}";
    hash = hashes.${platform};
  };
in
stdenv.mkDerivation {
  pname = "herdr";
  inherit version src;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/herdr
    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    versionCheckHook
    versionCheckHomeHook
  ];

  passthru.category = "Utilities";

  meta = {
    description = "Terminal workspace manager for AI coding agents";
    homepage = "https://herdr.dev";
    changelog = "https://github.com/ogulcancelik/herdr/releases/tag/v${version}";
    license = lib.licenses.agpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with flake.lib.maintainers; [ murlakatam ];
    mainProgram = "herdr";
    platforms = builtins.attrNames assetMap;
  };
}
