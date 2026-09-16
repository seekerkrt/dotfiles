# Handoff共通契約

## 目的

後続のChatGPT会話や別agentが、長いterminal logを再読せずに作業を安全に再開できるhandoffを作る。
handoffは作成時点のsnapshotであり、現在仕様のsource of truthではない。

## ユーザー追加指定のoverlay

handoffは次の式で作る。

```text
handoff Skillの既定契約
    +
今回のユーザーの追加指定
    ↓
重複や矛盾を整理した1つのhandoff
```

優先順位は次とする。

1. 安全性、事実性、未実施を偽らない契約
2. 今回のユーザーの明示指定
3. 本Skillの既定形式

追加指定を末尾へ機械的に付け足さず、既定sectionへ統合する。

- 「短く」: 必須情報を落とさず圧縮する。
- 「設計判断を詳しく」: Decisionと理由・棄却案を拡張する。
- 「実機確認中心」: Validationを実機の機種、条件、観測、未確認中心に再構成する。
- 「次スレに貼る本文だけ」: 対象本文を`handoff-inline`で扱う。
- 「残作業をIssue単位で」: RemainingをIssue候補、scope、acceptanceへ整理する。

## Authority

現状の観測と意図・仕様は分けて根拠を確認する。

- 現状の観測: 現在のsource code、実際のbuild設定、runtime evidence。
  観測条件と未確認範囲を記録する。
- 意図・仕様: repositoryが指定するdecision authorityに従い、採用済みの決定（Issue / PR等）や
  正式な仕様書 / architecture / decision documentを確認する。
  未採用のproposalを採用済み仕様と扱わない。

両者が食い違う場合は、現在実装と採用済み仕様の内容・根拠・不一致を両方残す。
codeまたはdocsを一律に優先して片方を消さない。

handoff内のbranch、commit SHA、line番号、caller一覧、validation、推奨、推測は作成時点のsnapshotである。
agentの推奨とユーザーが採用した判断を分ける。

確認済み事実、採用判断、proposal、推測、未確認を区別し、未取得の情報や未実施検証を捏造しない。

## Session evidenceの再利用

normal / inlineでは、出所、対象repo / revision / fileやdiff、観測時点、必要な実行環境を対応付けられ、
対象を無効化する変更の兆候がないsession evidenceを再利用する。出所を保持したsession summaryも利用できる。

- 過去runのpassをcurrent passへ昇格しない。対象や実行後の変更との対応が不明なら、現状態への適用は未確認とする。
- GitHub Issue / PR等は取得時点のsnapshotとして扱い、現在のserver stateへ昇格しない。
  現在の外部状態が必要なclaimだけ、必要なresourceを再取得する。local remote-tracking情報で代用しない。
- provenance不足、historical claimのみ、対象の変更兆候等があれば、不明なclaimだけ限定Recoveryする。
  有効なevidenceは保持し、全repositoryの再監査へ拡張しない。取得できない情報は未確認と理由を残す。
- handoff生成だけを理由にsource全量再読、既存build / test / audit再実行、不要なIssue / PR再取得・remote再照会、
  過去handoffの広範探索、diff全量再取得、新しい実装、その他の広範な調査・高cost検証を始めない。

## 必須情報

該当する内容を次から落とさない。空のsectionを増やす必要はない。

- repository、branch、HEAD、日時、agent、phase
- taskの目的、scope、non-goal
- 読んだfileと変更したfile
- 完了事項と実施していない事項
- 確認済み事実、採用判断、推測、未確認
- validation command、結果、未実施理由、環境
- known issue / risk
- 次に推奨する作業
- working tree状態
- `git add`、commit、pushの実施有無

## Validationの書き方

- commandを実際に実行した形で記録する。
- pass、fail、warning、partial、not run、environment blockedを区別する。
- build、test、runtime、QEMU KVM / TCG、VirtualBox、実機を区別する。
- 外部log、画面、動画、counterは観測事実と解釈を分ける。
- 長いlogを貼らず、再開に必要な値とerrorだけ残す。
