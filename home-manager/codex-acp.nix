{
  codex-cli,
  fetchurl,
  lib,
  makeWrapper,
  nodejs,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "codex-acp";
  version = "1.10.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@agentclientprotocol/codex-acp/-/codex-acp-${version}.tgz";
    hash = "sha256-nf+1Jbco0FeaixnUgyIoHsrX7qe6FkD6L43hGZNGNSw=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm644 dist/index.js $out/libexec/codex-acp/index.js
    makeWrapper ${nodejs}/bin/node $out/bin/codex-acp \
      --add-flags $out/libexec/codex-acp/index.js \
      --set CODEX_PATH ${codex-cli}/bin/codex
    runHook postInstall
  '';

  meta = {
    description = "Codex adapter for the Agent Client Protocol";
    homepage = "https://github.com/agentclientprotocol/codex-acp";
    license = lib.licenses.asl20;
    mainProgram = "codex-acp";
  };
}
