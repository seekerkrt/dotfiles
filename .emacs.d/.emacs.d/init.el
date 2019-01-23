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
(require 'linum)
(global-linum-mode t)
(setq linum-format "%3d ")
;;Auto-Save
(setq make-backup-files nil)
(setq auto-save-default nil)

;;フォント指定
(set-face-attribute 'default nil
                    :family "Ricty alters"
                    :height 12)
(set-frame-font "Ricty alters-10.5")

;; オープニングメッセージを表示しない
(setq inhibit-startup-message t)
;; 対応する括弧をハイライトする
(show-paren-mode 1)
;; カーソル位置の桁数をモードライン行に表示する
(column-number-mode 1)
;; カーソル位置の行数をモードライン行に表示する
(line-number-mode 1)
;; メニューバーを消す
(menu-bar-mode 0)

;; モードラインの設定
(line-number-mode t)                ;; 行数
(column-number-mode t)              ;; 桁数
(which-function-mode 1)
;;
(show-paren-mode t)
(transient-mark-mode t)

;; c-mode のインデントをスペース4個分のタブにする
(add-hook 'c-mode-common-hook
          '(lambda ()
             (c-set-style "k&r")
	               (setq c-basic-offset 4)
		              (setq indent-tabs-mode t)
			                  (setq tab-width 4)))
;;

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

;; auto-complete
;(require 'auto-complete)
;(require 'auto-complete-config)
;(global-auto-complete-mode t)

;; flycheck
;(require 'flycheck)
;;(add-hook 'after-init-hook 'global-flycheck-mode)
;;;

