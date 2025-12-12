;; シンボリックリンクを強制的にたどる＝＞プロンプトを出さない
(setq vc-follow-symlinks t)
(setq-default find-file-visit-truename t)
;;
(when load-file-name
  (setq user-emacs-directory (file-name-directory load-file-name)))

;;言語環境指定
(set-language-environment "japanese")
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(setq coding-system-for-read 'utf-8)
(setq coding-system-for-write 'utf-8)
;;行番号表示指定
;(require 'linum)
;(global-linum-mode t)
;(setq linum-format "%4d ")
(if (version<= "26.0.50" emacs-version)
      (global-display-line-numbers-mode))


;;フォント指定
(set-face-attribute 'default nil
                    :family "Mgen+ 1mn"
                    :height 12)
(set-frame-font "Mgen+ 1m-9")

;; メニューバーを消す
(menu-bar-mode 0)
;; スタートアップメッセージを表示しない
(setq inhibit-startup-message t)
; yes/no => y/n
(defalias 'yes-or-no-p 'y-or-n-p)
;;Auto-Save
(setq make-backup-files nil)
(setq auto-save-default nil)

;; 対応する括弧をハイライトする
(show-paren-mode 1)
;;画面内に対応する括弧がある場合は括弧だけを、ない場合は括弧で囲まれた部分をハイライト
(setq show-paren-style 'mixed)
;; カーソル位置の桁数をモードライン行に表示する
(column-number-mode 1)
;; カーソル位置の行数をモードライン行に表示する
(line-number-mode 1)
;;ファイルサイズを表示
(size-indication-mode t)

;; モードラインや見た目の設定
(line-number-mode t)                ;; 行数
(column-number-mode t)              ;; 桁数
(which-function-mode t)
(setq default-frame-alist
      (append (list
       '(set-foreground-color . "AntiqueWhite")  ; 前景色
       '(set-background-color . "black") ; 背景色
;      '(cursor-color     . "DarkGreen")  ; カーソル色
       '(set-cursor-color     . "Gray")  ; カーソル色
       '(set-frame-parameter nil 'alpha 80);透過度
       )
       default-frame-alist))
;;適用?
(setq initial-frame-alist default-frame-alist)

;;
;; 選択範囲に色をつける
(transient-mark-mode t)
(set-face-background 'region "DeepSkyBlue") ;選択範囲の色


;; Indent
(setq-default indent-tabs-mode nil)
(setq-default c-basic-offset 4)
(setq-default tab-width 4)



;;カラーテーマ設定
;(require 'color-theme)
;(color-theme-initialize)
;(load-theme 'manoj-dark t)
;(load-theme 'tango-dark t)
;(load-theme 'deep-blue t)


;;Lua-mode
(setq auto-mode-alist (cons '("\.lua$" . lua-mode) auto-mode-alist))
(autoload 'lua-mode "lua-mode" "Lua mode." t)

;;Ruby-mode
(autoload 'ruby-mode "ruby-mode"
  "Mode for editing ruby source files" t)
(add-to-list 'auto-mode-alist '("\\.rb$latex " . ruby-mode))
(add-to-list 'auto-mode-alist '("Capfile$" . ruby-mode))
(add-to-list 'auto-mode-alist '("Gemfile$" . ruby-mode))

;;Python-mode
(autoload 'python-mode "python-mode.el" "Python mode." t)
(setq auto-mode-alist (append '(("/.*\.py\'" . python-mode)) auto-mode-alist))

;;Haskell-mode
;(require 'haskell-mode-autoloads)
;; auto-complete
;(require 'auto-complete)
;(require 'auto-complete-config)
;(global-auto-complete-mode t)

