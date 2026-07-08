{
  lib,
  stdenv,
  fetchurl,
}:

# OpenAI Codex CLI の公式 pre-built バイナリを Nix 化するインライン derivation。
#
# ryoppippi/nix-claude-code を参考にした最小版：flake は aarch64-darwin 固定なので
# platform 分岐は入れず、必要になったら sources 表を増やす。
#
# バージョン更新手順:
#   1. https://github.com/openai/codex/releases から新しい rust-vX.Y.Z を選ぶ
#   2. `nix-prefetch-url --type sha256 <tar.gz URL> | xargs nix hash convert --hash-algo sha256 --to sri`
#      で SRI 形式のハッシュを取得
#   3. 下記の version / hash を差し替え
stdenv.mkDerivation rec {
  pname = "codex-cli";
  version = "0.143.0";

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-aarch64-apple-darwin.tar.gz";
    hash = "sha256-ffI4TwN1Gd/32/QlLmCROlwcf9tmwUZ8kSWystNZSoY=";
  };

  # tarball 直下にバイナリ 1 本のみ入っている（ディレクトリを噛まない）
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 codex-aarch64-apple-darwin $out/bin/codex
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
