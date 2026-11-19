{
  lib,
  stdenvNoCC,
  fetchurl,
}:

# 日本語文書の推敲診断 CLI suiko の公式 pre-built バイナリ。
# nixpkgs 未収録で、ソースビルドは辞書をビルド時に取得するためサンドボックスで失敗する。
#
# バージョン更新手順:
#   1. https://github.com/nwiizo/suiko/releases から新しい vX.Y.Z を選ぶ
#   2. `nix-prefetch-url --type sha256 <tar.gz URL> | xargs nix hash convert --hash-algo sha256 --to sri`
#   3. 下記の version / hash を差し替え
stdenvNoCC.mkDerivation rec {
  pname = "suiko";
  version = "0.4.3";

  src = fetchurl {
    url = "https://github.com/nwiizo/suiko/releases/download/v${version}/suiko-v${version}-aarch64-apple-darwin.tar.gz";
    hash = "sha256-YVrqbPfIeUo3OIzINAVP6m4ZgRqLP4uS0iMORVN0rro=";
  };

  installPhase = ''
    runHook preInstall
    install -Dm755 suiko $out/bin/suiko
    runHook postInstall
  '';

  # 辞書埋め込みの Rust バイナリなので strip しない
  dontStrip = true;

  meta = {
    description = "Deterministic diagnostics for natural and readable Japanese writing";
    homepage = "https://github.com/nwiizo/suiko";
    license = lib.licenses.mit;
    mainProgram = "suiko";
    platforms = [ "aarch64-darwin" ];
  };
}
