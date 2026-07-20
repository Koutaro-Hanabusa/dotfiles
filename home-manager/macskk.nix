{ config, lib, ... }:

let
  bundleId = "net.mtgto.inputmethod.macSKK";
  plistPath =
    "${config.home.homeDirectory}/Library/Containers/${bundleId}/Data/Library/Preferences/${bundleId}.plist";
in
{
  # macSKK の設定を宣言的に固定する。
  # 実体は App Sandbox 内の plist なので symlink は cfprefsd に atomic replace で壊されがち。
  # そのため `defaults write` で毎回上書きする方針。UI で設定を変更しても
  # 次回の home-manager switch で dotfiles の値が真になる。
  # macSKK.app が一度も起動していない環境では Container が存在しないためスキップする。
  home.activation.macskkSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -e "${plistPath}" ]; then
      $DRY_RUN_CMD /usr/bin/defaults write ${bundleId} dictionaries '({enabled=1; encoding=3; filename="SKK-JISYO.L"; saveToUserDict=1; type=traditional;})'
      $DRY_RUN_CMD /usr/bin/defaults write ${bundleId} kanaRule -string ""
      $DRY_RUN_CMD /usr/bin/defaults write ${bundleId} directModeBundleIdentifiers -array
      $DRY_RUN_CMD /usr/bin/defaults write ${bundleId} skkserv '{address="127.0.0.1"; enableCompletion=0; enabled=0; encoding=3; port=1178; requestEncoding=3; responseEncoding=3; saveToUserDict=1;}'
    else
      echo "macskk.nix: sandbox container not found at ${plistPath}"
      echo "  → macSKK.app を一度起動してから再度 home-manager switch を実行してください"
    fi
  '';
}
