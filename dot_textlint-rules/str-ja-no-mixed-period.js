/**
 * Strノードに対して文末の句点チェックを行うカスタムルール
 * textlint-plugin-jsxがStringLiteralをStrノードとしてパースするため、
 * 通常のja-no-mixed-periodルールが適用されない問題を解決する
 */

const defaultOptions = {
  // 期待する句点
  periodMark: "。",
  // 許可する句点
  allowPeriodMarks: [".", "．"],
  // 句点で終わらなくてもOKなパターン（正規表現）
  allowPatterns: [
    // 短いメッセージ（10文字以下）
    /^.{1,10}$/,
    // 疑問文
    /[？?]$/,
    // 感嘆文
    /[！!]$/,
    // 括弧で終わる
    /[）)」』】］\]]$/,
    // 英数字のみ
    /^[a-zA-Z0-9\s\-_.,]+$/,
    // ファイル拡張子リスト的なもの
    /^[a-zA-Z0-9,\s]+$/,
  ],
  // 日本語を含むかどうかのチェック
  requireJapanese: true,
};

// 日本語文字を含むかチェック
function containsJapanese(text) {
  return /[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]/.test(text);
}

// 許可パターンにマッチするかチェック
function matchesAllowPattern(text, allowPatterns) {
  return allowPatterns.some((pattern) => pattern.test(text));
}

// 文末が適切な句点で終わっているかチェック
function endsWithPeriod(text, periodMark, allowPeriodMarks) {
  const trimmed = text.trim();
  if (trimmed.endsWith(periodMark)) {
    return true;
  }
  return allowPeriodMarks.some((mark) => trimmed.endsWith(mark));
}

module.exports = function (context, options = {}) {
  const { Syntax, report, RuleError } = context;

  const config = {
    ...defaultOptions,
    ...options,
    allowPatterns: options.allowPatterns
      ? options.allowPatterns.map((p) => (typeof p === "string" ? new RegExp(p) : p))
      : defaultOptions.allowPatterns,
  };

  return {
    [Syntax.Str](node) {
      const text = node.value;

      // 空文字列はスキップ
      if (!text || text.trim().length === 0) {
        return;
      }

      // 日本語を含まない場合はスキップ（オプション）
      if (config.requireJapanese && !containsJapanese(text)) {
        return;
      }

      // 許可パターンにマッチする場合はスキップ
      if (matchesAllowPattern(text.trim(), config.allowPatterns)) {
        return;
      }

      // 文末チェック
      if (!endsWithPeriod(text, config.periodMark, config.allowPeriodMarks)) {
        report(
          node,
          new RuleError(
            `文末が"${config.periodMark}"で終わっていません。\n` +
            `対象テキスト: "${text.trim().slice(0, 50)}${text.trim().length > 50 ? '...' : ''}"`
          )
        );
      }
    },
  };
};
