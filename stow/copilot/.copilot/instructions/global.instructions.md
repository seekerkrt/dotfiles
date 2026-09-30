---
name: 共通開発指示
description: Codexの共通AGENTS.mdを参照する
applyTo: "**"
---

# 共通開発指示

共通開発ルールとして
[Codex AGENTS.md](~/.codex/AGENTS.md)
を参照し、その指示に従うこと。

## Copilot固有差分

- 共通SkillはCopilot CLIが対応する`~/.agents/skills/<skill>/SKILL.md`を使う。`~/.copilot/skills/`へ同名Skillを複製しない。canonical nameとroutingはCodex正本に従う。
- 対象repositoryの`AGENTS.md`と適用される`copilot-instructions.md` / `*.instructions.md`を確認する。Copilotのtool / directory permissionは追加の実行境界であり、allowを依頼scopeの承認とみなさず、拒否を迂回しない。
- native roleは`~/.copilot/agents/`の`coder.agent.md`、`auditor.agent.md`、`verifier.agent.md`、`handoff.agent.md`を使う。実装は原則1つのcoderまたは親へ集中し、独立範囲の監査・検証は並列化してよい。
- auditorはfileを編集しない。verifierはproduction code / testを変更せず、shellでbuild / testに必要なartifactと検証logを生成してよい。監査は`audit`、検証は`validate`へroutingする。親はsubagentへ適用instruction、scope、対象diffとevidenceを渡す。
- handoff担当は既存evidenceを使って明示された成果物だけを作る。artifact filenameのagent部分は`copilot`と読み替える。Codexのmodel IDやpermission profileは使わない。
