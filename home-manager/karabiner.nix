# Karabiner-Elements の設定を Nix の式から生成する。
# 「Mouse Keys Mode v4」= d+<key> でマウス操作モードを起動し、hjkl 移動 / uio クリック /
# v・n 画面移動 / s スクロール・f,g 速度調整 をキーボードだけで行う。
#
# 注意: このファイルが karabiner.json の唯一の生成元。Karabiner GUI で編集しても
# home-manager switch で上書きされるため、変更はここに書くこと。
{ lib, ... }:

let
  # ── 共通の条件・パーツ ───────────────────────────────
  modeCond = {
    name = "mouse_keys_mode_v4";
    type = "variable_if";
    value = 1;
  };
  scrollCond = {
    name = "mouse_keys_mode_v4_scroll";
    type = "variable_if";
    value = 1;
  };
  screenCond = idx: {
    name = "mouse_keys_screen_index";
    type = "variable_if";
    value = idx;
  };
  optAny = { optional = [ "any" ]; };

  # d+<key> でモードを起動するとき、to の先頭で実行するアクション
  activate = [
    { set_variable = { name = "mouse_keys_mode_v4"; value = 1; }; }
    { set_notification_message = { id = "mouse_keys_mode_v4"; text = "Mouse Keys Mode v4"; }; }
  ];
  # d+<key> を離したとき（simultaneous_options.to_after_key_up）モードを終了するアクション
  resetActions = [
    { set_variable = { name = "mouse_keys_mode_v4"; value = 0; }; }
    { set_variable = { name = "mouse_keys_mode_v4_scroll"; value = 0; }; }
    { set_variable = { name = "mouse_keys_mode_v4_selection"; value = 0; }; }
    { set_notification_message = { id = "mouse_keys_mode_v4"; text = ""; }; }
  ];

  # モード中に単キーを押したときの基本 manipulator
  onKey =
    {
      key,
      to,
      conditions ? [ modeCond ],
      extra ? { },
    }:
    {
      type = "basic";
      from = {
        key_code = key;
        modifiers = optAny;
      };
      inherit to conditions;
    }
    // extra;

  # d+<key> 同時押し manipulator（モード起動 + 任意アクション）
  dKey =
    {
      key,
      to,
      extra ? { },
    }:
    {
      type = "basic";
      from = {
        modifiers = optAny;
        simultaneous = [
          { key_code = "d"; }
          { key_code = key; }
        ];
        simultaneous_options = {
          key_down_order = "strict";
          key_up_order = "strict_inverse";
          to_after_key_up = resetActions;
        };
      };
      parameters = {
        "basic.simultaneous_threshold_milliseconds" = 500;
      };
      to = activate ++ to;
    }
    // extra;

  mouseKey = attrs: [ { mouse_key = attrs; } ];

  # ── Rule 0: カーソル移動 (hjkl) ──────────────────────
  # 各キーにつき「スクロール時=ホイール / 通常=カーソル移動 / d+key=起動して移動」の3つ
  moveDirs = [
    {
      key = "j";
      axis = "y";
      delta = 1536;
      wheelAxis = "vertical_wheel";
      wheel = 32;
    }
    {
      key = "k";
      axis = "y";
      delta = -1536;
      wheelAxis = "vertical_wheel";
      wheel = -32;
    }
    {
      key = "h";
      axis = "x";
      delta = -1536;
      wheelAxis = "horizontal_wheel";
      wheel = 32;
    }
    {
      key = "l";
      axis = "x";
      delta = 1536;
      wheelAxis = "horizontal_wheel";
      wheel = -32;
    }
  ];
  moveManips = lib.concatMap (d: [
    (onKey {
      key = d.key;
      conditions = [
        modeCond
        scrollCond
      ];
      to = mouseKey { ${d.wheelAxis} = d.wheel; };
    })
    (onKey {
      key = d.key;
      to = mouseKey { ${d.axis} = d.delta; };
    })
    (dKey {
      key = d.key;
      to = mouseKey { ${d.axis} = d.delta; };
    })
  ]) moveDirs;

  # ── Rule 1: クリック (uio) ───────────────────────────
  clickButtons = [
    {
      key = "u";
      button = "button1";
    } # 左
    {
      key = "i";
      button = "button3";
    } # 中
    {
      key = "o";
      button = "button2";
    } # 右
  ];
  clickManips = lib.concatMap (c: [
    (onKey {
      key = c.key;
      to = [ { pointing_button = c.button; } ];
    })
    (dKey {
      key = c.key;
      to = [ { pointing_button = c.button; } ];
    })
  ]) clickButtons;

  # ── Rule 2: 画面移動 (v: サイクル, n: ウィンドウ中央) ──
  cursorTo = screen: [
    { software_function = { set_mouse_cursor_position = { inherit screen; x = "50%"; y = "50%"; }; }; }
  ];
  toScreen =
    screen:
    [ { set_variable = { name = "mouse_keys_screen_index"; value = screen; }; } ] ++ cursorTo screen;
  centerCursor = [
    { software_function = { set_mouse_cursor_position = { x = "50%"; y = "50%"; }; }; }
  ];
  screenManips = [
    (onKey {
      key = "v";
      conditions = [
        modeCond
        (screenCond 0)
      ];
      to = toScreen 1;
    })
    (onKey {
      key = "v";
      conditions = [
        modeCond
        (screenCond 1)
      ];
      to = toScreen 2;
    })
    (onKey {
      key = "v";
      conditions = [
        modeCond
        (screenCond 2)
      ];
      to = toScreen 0;
    })
    (onKey {
      key = "v";
      to = toScreen 1;
    }) # 初期状態（screen_index 未設定）
    (dKey {
      key = "v";
      to = toScreen 1;
    })
    (onKey {
      key = "n";
      to = centerCursor;
    })
    (dKey {
      key = "n";
      to = centerCursor;
    })
  ];

  # ── Rule 3: スクロールモード (s) / 速度調整 (f,g) ─────
  scrollOn = [ { set_variable = { name = "mouse_keys_mode_v4_scroll"; value = 1; }; } ];
  scrollOff = [ { set_variable = { name = "mouse_keys_mode_v4_scroll"; value = 0; }; } ];
  speedManips = lib.concatMap (s: [
    (onKey {
      key = s.key;
      to = mouseKey { speed_multiplier = s.mult; };
    })
    (dKey {
      key = s.key;
      to = mouseKey { speed_multiplier = s.mult; };
    })
  ]) [
    {
      key = "f";
      mult = 2;
    }
    {
      key = "g";
      mult = 0.5;
    }
  ];
  scrollManips = [
    (onKey {
      key = "s";
      to = scrollOn;
      extra = { to_after_key_up = scrollOff; };
    })
    (dKey {
      key = "s";
      to = scrollOn;
      extra = { to_after_key_up = scrollOff; };
    })
  ]
  ++ speedManips;

  mkRule = description: manipulators: { inherit description manipulators; };

  karabinerConfig = {
    profiles = [
      {
        name = "Default profile";
        selected = true;
        virtual_hid_keyboard = {
          keyboard_type_v2 = "jis";
        };
        complex_modifications = {
          rules = [
            (mkRule "Mouse Keys Mode v4 - カーソル移動 (hjkl)" moveManips)
            (mkRule "Mouse Keys Mode v4 - クリック (uio)" clickManips)
            (mkRule "Mouse Keys Mode v4 - 画面移動 (v: サイクル, n: ウィンドウ中央)" screenManips)
            (mkRule "Mouse Keys Mode v4 - スクロールモード (s) / 速度調整 (f: 2倍, g: 0.5倍)" scrollManips)
          ];
        };
      }
    ];
  };
in
{
  home.file.".config/karabiner/karabiner.json".text = builtins.toJSON karabinerConfig;
}
