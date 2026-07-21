{ config, lib, ... }:

let
  bundleId = "net.mtgto.inputmethod.macSKK";
  containerDir =
    "${config.home.homeDirectory}/Library/Containers/${bundleId}";
  plistPath =
    "${containerDir}/Data/Library/Preferences/${bundleId}.plist";
  dictDir = "${containerDir}/Data/Documents/Dictionaries";
  dictBaseUrl = "https://raw.githubusercontent.com/skk-dev/dict/master";
  # macSKK の encoding は Swift の String.Encoding rawValue そのもの。
  # 4 = UTF-8, 3 = EUC-JP。plist に Int で入れないと DictSetting.init が nil を返す。
  # また `enabled` は Bool 型で入れる必要があるため、値の型指定ができる PlistBuddy を使う
  # (defaults write の `( { ... } )` 記法は全て string 化してしまい macSKK に無視される)。
  dicts = [
    { filename = "SKK-JISYO.L"; encoding = 3; }
    { filename = "SKK-JISYO.emoji"; encoding = 4; }
  ];
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

    # 辞書ファイルが無いと macSKK 自身が起動時に enabled=0 に書き戻すので先に用意
    $DRY_RUN_CMD /bin/mkdir -p "${dictDir}"
    ${lib.concatMapStringsSep "\n" (d: ''
      if [ ! -f "${dictDir}/${d.filename}" ]; then
        $DRY_RUN_CMD /usr/bin/curl -fL -o "${dictDir}/${d.filename}" "${dictBaseUrl}/${d.filename}"
      fi
    '') dicts}

    # macSKK 起動中は plist を書き戻されるので一度落とす
    $DRY_RUN_CMD /usr/bin/pkill -f macSKK || true
    sleep 1
    # cfprefsd のキャッシュを飛ばしてから plist を直接書く。
    # (defaults write と PlistBuddy を混ぜると cfprefsd 経由の書き戻しで PlistBuddy の
    #  変更が上書きされ、値が string 化して macSKK に無視される)
    $DRY_RUN_CMD /usr/bin/killall cfprefsd || true
    sleep 1

    PB=/usr/libexec/PlistBuddy

    # dictionaries: 型 (Bool/Integer/String) を厳密に指定する必要があるため PlistBuddy で組む
    $DRY_RUN_CMD $PB -c "Delete :dictionaries" "${plistPath}" 2>/dev/null || true
    $DRY_RUN_CMD $PB -c "Add :dictionaries array" "${plistPath}"
    ${lib.concatStringsSep "\n" (lib.imap0 (i: d: ''
      $DRY_RUN_CMD $PB -c "Add :dictionaries:${toString i} dict" "${plistPath}"
      $DRY_RUN_CMD $PB -c "Add :dictionaries:${toString i}:filename string ${d.filename}" "${plistPath}"
      $DRY_RUN_CMD $PB -c "Add :dictionaries:${toString i}:enabled bool true" "${plistPath}"
      $DRY_RUN_CMD $PB -c "Add :dictionaries:${toString i}:encoding integer ${toString d.encoding}" "${plistPath}"
      $DRY_RUN_CMD $PB -c "Add :dictionaries:${toString i}:type string traditional" "${plistPath}"
      $DRY_RUN_CMD $PB -c "Add :dictionaries:${toString i}:saveToUserDict bool true" "${plistPath}"
    '') dicts)}

    # 他のキーも PlistBuddy で書き揃える (defaults write を混ぜない)
    $DRY_RUN_CMD $PB -c 'Set :kanaRule ""' "${plistPath}" 2>/dev/null \
      || $DRY_RUN_CMD $PB -c 'Add :kanaRule string ""' "${plistPath}"

    $DRY_RUN_CMD $PB -c "Delete :directModeBundleIdentifiers" "${plistPath}" 2>/dev/null || true
    $DRY_RUN_CMD $PB -c "Add :directModeBundleIdentifiers array" "${plistPath}"

    # 旧 macskk.nix が書いていた `skkserv` キーはバージョンアップで廃止されたので消す
    $DRY_RUN_CMD $PB -c "Delete :skkserv" "${plistPath}" 2>/dev/null || true

    # skkservClient は macSKK が必須参照するキー (無いと Fatal error で起動しない)。
    $DRY_RUN_CMD $PB -c "Delete :skkservClient" "${plistPath}" 2>/dev/null || true
    $DRY_RUN_CMD $PB -c "Add :skkservClient dict" "${plistPath}"
    $DRY_RUN_CMD $PB -c "Add :skkservClient:destination dict" "${plistPath}"
    $DRY_RUN_CMD $PB -c "Add :skkservClient:destination:host string 127.0.0.1" "${plistPath}"
    $DRY_RUN_CMD $PB -c "Add :skkservClient:destination:port integer 1178" "${plistPath}"
    $DRY_RUN_CMD $PB -c "Add :skkservClient:destination:encoding integer 3" "${plistPath}"

    $DRY_RUN_CMD /usr/bin/open "/Library/Input Methods/macSKK.app"
  '';
}
