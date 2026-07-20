{ config, lib, ... }:

let
  bundleId = "net.mtgto.inputmethod.macSKK";
  containerDir =
    "${config.home.homeDirectory}/Library/Containers/${bundleId}";
  plistPath =
    "${containerDir}/Data/Library/Preferences/${bundleId}.plist";
  dictDir = "${containerDir}/Data/Documents/Dictionaries";
  dictUrl = "https://raw.githubusercontent.com/skk-dev/dict/master/SKK-JISYO.L";
in
{
  # macSKK の設定を宣言的に固定する。
  # 実体は App Sandbox 内の plist なので symlink は cfprefsd に atomic replace で壊されがち。
  # そのため `defaults write` で毎回上書きする方針。UI で設定を変更しても
  # 次回の home-manager switch で dotfiles の値が真になる。
  # macSKK.app が一度も起動していない環境では Container が存在しないためスキップする。
  home.activation.macskkSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "${plistPath}" ]; then
      echo "macskk.nix: sandbox container not found at ${plistPath}"
      echo "  → macSKK.app を一度起動してから再度 home-manager switch を実行してください"
      exit 0
    fi

    # SKK-JISYO.L が無いと macSKK 自身が起動時に enabled=0 に書き戻すので先に用意
    if [ ! -f "${dictDir}/SKK-JISYO.L" ]; then
      $DRY_RUN_CMD /bin/mkdir -p "${dictDir}"
      $DRY_RUN_CMD /usr/bin/curl -fL -o "${dictDir}/SKK-JISYO.L" "${dictUrl}"
    fi

    # macSKK 起動中は plist を書き戻されるので一度落とす
    $DRY_RUN_CMD /usr/bin/pkill -f macSKK || true
    sleep 1

    $DRY_RUN_CMD /usr/bin/defaults write ${bundleId} dictionaries '({enabled=1; encoding=3; filename="SKK-JISYO.L"; saveToUserDict=1; type=traditional;})'
    $DRY_RUN_CMD /usr/bin/defaults write ${bundleId} kanaRule -string ""
    $DRY_RUN_CMD /usr/bin/defaults write ${bundleId} directModeBundleIdentifiers -array
    # skkservClient は macSKK が必須参照するキー (無いと Fatal error で起動しない)。
    # 旧 macskk.nix が書いていた `skkserv` キーはバージョンアップで廃止されたので消す。
    $DRY_RUN_CMD /usr/bin/defaults delete ${bundleId} skkserv 2>/dev/null || true
    $DRY_RUN_CMD /usr/bin/defaults write ${bundleId} skkservClient '{destination={host="127.0.0.1"; port=1178; encoding=3;};}'

    $DRY_RUN_CMD /usr/bin/open "/Library/Input Methods/macSKK.app"
  '';
}
