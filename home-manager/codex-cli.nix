{
  lib,
  stdenv,
  fetchurl,
}:

# OpenAI Codex CLI の公式 package を Nix 化するインライン derivation。
#
# ryoppippi/nix-claude-code を参考にした最小版：flake は aarch64-darwin 固定なので
# platform 分岐は入れず、必要になったら sources 表を増やす。
#
# バージョン更新手順:
#   1. https://github.com/openai/codex/releases から新しい rust-vX.Y.Z を選ぶ
#   2. `nix-prefetch-url --type sha256 <codex-package tar.gz URL> | xargs nix hash convert --hash-algo sha256 --to sri`
#      で SRI 形式のハッシュを取得
#   3. 下記の version / hash を差し替え
stdenv.mkDerivation rec {
  pname = "codex-cli";
  version = "0.153.4";

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-package-aarch64-apple-darwin.tar.gz";
    hash = "sha256-NUONofv3ptt92zvOyERI+mAVuhiEYUcql9nR2n2cQ1M=";
  };

  # package の bin / resources / metadata は tarball 直下にある。
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R bin codex-package.json codex-path codex-resources $out/
    runHook postInstall
  '';

  # Rust バイナリなので strip 不要（署名や埋め込みバージョン情報を壊さないため）
  dontStrip = true;

  meta = {
    description = "OpenAI Codex CLI (pre-built binary)";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = [ "aarch64-darwin" ];
  };
}
