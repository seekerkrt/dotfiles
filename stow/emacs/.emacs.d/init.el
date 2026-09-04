;;; init.el --- Emacs configuration -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------------
;; Symlink
;; ---------------------------------------------------------------------------

;; シンボリックリンク先を編集するときの確認を省略
(setq vc-follow-symlinks t)

;; 常に実体のパスとしてファイルを扱う
(setq-default find-file-visit-truename t)

;; この init.el が置かれているディレクトリを Emacs 設定ディレクトリとする
(when load-file-name
  (setq user-emacs-directory
        (file-name-directory load-file-name)))


;; ---------------------------------------------------------------------------
;; Language / Encoding
;; ---------------------------------------------------------------------------

(set-language-environment "Japanese")
(prefer-coding-system 'utf-8)


;; ---------------------------------------------------------------------------
;; Display
;; ---------------------------------------------------------------------------

;; 行番号
(global-display-line-numbers-mode 1)

;; モードラインに現在位置を表示
(line-number-mode 1)
(column-number-mode 1)

;; ファイルサイズを表示
(size-indication-mode 1)

;; 現在の関数名を表示
(which-function-mode 1)

;; 対応する括弧をハイライト
(show-paren-mode 1)
(setq show-paren-style 'mixed)

;; 選択範囲をハイライト
(transient-mark-mode 1)
(set-face-background 'region "DeepSkyBlue")


;; ---------------------------------------------------------------------------
;; Font
;; ---------------------------------------------------------------------------

(set-face-attribute 'default nil
                    :family "MyricaM M"
                    :height 120)


;; ---------------------------------------------------------------------------
;; Frame
;; ---------------------------------------------------------------------------

(setq default-frame-alist
      (append
       '((foreground-color . "AntiqueWhite")
         (background-color . "black")
         (cursor-color . "Gray")
         (alpha-background . 80))
       default-frame-alist))

;; 最初のフレームにも同じ設定を適用
(setq initial-frame-alist default-frame-alist)


;; ---------------------------------------------------------------------------
;; UI
;; ---------------------------------------------------------------------------

;; メニューバーを非表示
(menu-bar-mode -1)

;; スタートアップ画面を表示しない
(setq inhibit-startup-message t)

;; yes / no ではなく y / n
(setq use-short-answers t)


;; ---------------------------------------------------------------------------
;; Backup / Auto Save
;; ---------------------------------------------------------------------------

;; バックアップファイルを作成しない
(setq make-backup-files nil)

;; Auto Saveを無効化
(setq auto-save-default nil)


;; ---------------------------------------------------------------------------
;; Indent
;; ---------------------------------------------------------------------------

(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq-default c-basic-offset 4)


;; ---------------------------------------------------------------------------
;; Major Modes
;; ---------------------------------------------------------------------------

;; Lua
(autoload 'lua-mode "lua-mode"
  "Major mode for editing Lua source files." t)
(add-to-list 'auto-mode-alist '("\\.lua\\'" . lua-mode))

;; Ruby
(add-to-list 'auto-mode-alist '("\\.rb\\'" . ruby-mode))
(add-to-list 'auto-mode-alist '("Capfile\\'" . ruby-mode))
(add-to-list 'auto-mode-alist '("Gemfile\\'" . ruby-mode))

;; Python
(add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))

;; Rust
(autoload 'rust-mode "rust-mode"
  "Major mode for editing Rust source files." t)
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-mode))


;; ---------------------------------------------------------------------------
;; Color Theme
;; ---------------------------------------------------------------------------

;; 必要なら有効化
;; (load-theme 'manoj-dark t)
;; (load-theme 'tango-dark t)
;; (load-theme 'deep-blue t)


;;; init.el ends here
