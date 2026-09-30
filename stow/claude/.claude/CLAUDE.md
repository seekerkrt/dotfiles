# 個人共通 CLAUDE.md

共通契約の保守上の唯一の正本はCodex側の`stow/codex/.codex/AGENTS.md`である。本fileはその正本をimportし、Claude Code固有差分だけを追加する。Claude側だけの共通契約を追加せず、共通ルールの変更はCodex正本を先に直す。

@~/.codex/AGENTS.md

## Claude Code固有差分

- importした正本本文の`AGENTS.md`は、Claude Codeでは`CLAUDE.md`と読み替える。適用順序も、作業対象に最も近い`CLAUDE.md`から親directory側の`CLAUDE.md`、次にこの個人共通`CLAUDE.md`とする。
- Routingにあるglobal Skillは`~/.claude/skills/<skill>/SKILL.md`へ配置する。`/<skill-name>`として明示された場合も、modelが自動選択した場合も同じSkill契約を適用する。
- Claude Codeのpermission設定とhooksは、この文書へ追加される実行境界として扱う。allowされたtoolやcommandも依頼scopeの承認とはみなさず、ask / denyを別command、別tool、設定変更で回避しない。通常の許可確認が必要な場合は対象と影響を示し、許可されなければ未実施として報告する。

## 役割と委任

- native subagentは`~/.claude/agents/`の`coder.md`、`auditor.md`、`verifier.md`、`handoff.md`を使う。役割とSkillは別の仕組みであり、監査は`audit`、検証は`validate`へroutingする。
- 実装は原則1つの`coder`または親だけが担当する。独立できる監査・検証は並列化してよい。親は各担当へscope、適用authority、変更可能範囲、必要なevidenceを渡し、結果を統合する。
- `auditor`はfileを変更しない。shellや外部照会が必要なevidenceは親から渡す。`verifier`はproduction codeとtestを変更せず、Bashでbuild / testの生成artifactや検証logを作ってよい。検証失敗の修正は実装担当へ戻す。
- `handoff`は完成済みの作業と既存evidenceから、明示されたhandoff成果物だけを作る。inline / archive指定は各Skillへroutingする。モデルはClaude Code側の設定を継承し、Codexのmodel IDやpermission profileを持ち込まない。
