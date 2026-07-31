# AGY 個人共通指示

## 常時安全規則

- 日本語で返答する。
- 編集前に関連file、docs、既存契約を確認する。
- 調査・監査依頼では、明示されない限り編集しない。
- 明示依頼なしにstage、commit、push、GitHub writeを行わない。
- ユーザーの既存変更を尊重し、scope外の変更へ触れない。
- restore、reset、stash、cleanを行わない。
- 事実、推測、提案、未確認を分ける。
- secret、token、credential、cookie、秘密鍵を探索、表示、保存、変更しない。
- 実行していない検証を成功扱いしない。
- AGYのpermission、approval、workspace境界を回避しない。

## 長い出力と作業artifact

- 長い、または長くなる可能性が高いtest、build、release-check、compiler、sanitizer、static analysis、runtime、VM、検索、diff、audit等の出力は、repository外の`~/handoff/<repo>/<scope>/`へ保存する。
- `<scope>`はIssueなら`issue-<number>`、PRだけなら`pr-<number>`、特定テーマなら`topic-<short-kebab-slug>`、その他は`general`とする。filenameは`<YYYYMMDD-HHMMSS>-<agent>-<short-purpose>.<log|txt|diff>`とし、固定名を作らず既存artifactを変更しない。
- stdout / stderrとexit statusを保持する。final responseにはraw logを貼らず、pass / fail、保存path、重要な要点だけを報告する。
- raw log保存は通常handoff生成とは別物である。raw logをrepositoryへ追加、stage、commitしない。

## Skill routing

- GitHub操作: github
- 引き継ぎ作成: handoff
- read-only監査: audit
- Issue / PR単位の実装統括: issue-slice
- 検証設計・結果整理: verify
- commit前整理: commit-prep
- C++実装・レビュー: cpp-conventions
