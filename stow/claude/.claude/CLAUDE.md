# 個人共通 CLAUDE.md

共通契約の保守上の唯一の正本はCodex側の`stow/codex/.codex/AGENTS.md`である。本fileはその正本をimportし、Claude Code固有差分だけを追加する。Claude側だけの共通契約を追加せず、共通ルールの変更はCodex正本を先に直す。

@~/.codex/AGENTS.md

## Claude Code固有差分

- importした正本本文の`AGENTS.md`は、Claude Codeでは`CLAUDE.md`と読み替える。適用順序も、作業対象に最も近い`CLAUDE.md`から親directory側の`CLAUDE.md`、次にこの個人共通`CLAUDE.md`とする。
- Routingにあるglobal Skillは`~/.claude/skills/<skill>/SKILL.md`へ配置する。`/<skill-name>`として明示された場合も、modelが自動選択した場合も同じSkill契約を適用する。
- Routingの`verify`は、Claude Codeでは組み込みcommandとの衝突を避けるため`verify-diff`という名前で配置している。契約の内容は同じである。
- Claude Codeのpermission設定とhooksは、この文書へ追加される実行境界として扱う。allowされたtoolやcommandも依頼scopeの承認とはみなさず、ask / denyを別command、別tool、設定変更で回避しない。通常の許可確認が必要な場合は対象と影響を示し、許可されなければ未実施として報告する。
