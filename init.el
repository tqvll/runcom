;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-

;; managed in ~/git/runcom （~/.emacs.d/init.el からシンボリックリンク）
;;
;; Emacs 28 以上で動く。29 以上なら vertico / consult / corfu によるモダンな
;; 補完スタックが自動的に有効になり、28 では組み込みの fido-vertical +
;; company にフォールバックする。

;;; Code:

;;;; ------------------------------------------------------------ 起動時の調整
;; 起動中は GC を止めておき、終わったら現実的な値に戻す
(setq gc-cons-threshold most-positive-fixnum
      read-process-output-max (* 1024 1024))
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024))
            (message "Emacs ready in %.2fs (%d GCs)"
                     (float-time (time-subtract after-init-time before-init-time))
                     gcs-done)))

;;;; ------------------------------------------------------------ パッケージ
(require 'package)
(setq package-archives '(("gnu"    . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("melpa"  . "https://melpa.org/packages/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; アーカイブのキャッシュが古いとインストールが "Not found" で落ちるので、
;; 失敗したら一度だけ更新して再試行する
(define-advice package-install (:around (fn &rest args) my/retry-after-refresh)
  (condition-case nil
      (apply fn args)
    (error (ignore-errors (package-refresh-contents))
           (apply fn args))))

(defun my/ensure-package (pkg)
  "PKG が Emacs に同梱されていない場合だけインストールする。"
  (unless (or (locate-library (symbol-name pkg)) (package-installed-p pkg))
    (package-install pkg)))

(my/ensure-package 'use-package)
(require 'use-package)
(setq use-package-always-ensure t)

;;;; ------------------------------------------------------------ 基本設定
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)

(when (eq system-type 'darwin)
  (setq mac-option-modifier 'alt
        mac-command-modifier 'meta)
  (global-set-key [kp-delete] #'delete-char))

(setq inhibit-startup-screen t
      initial-scratch-message nil
      ring-bell-function #'ignore
      use-short-answers t              ; yes/no を y/n で答える
      create-lockfiles nil
      make-backup-files nil
      auto-save-default nil
      require-final-newline t
      sentence-end-double-space nil
      vc-follow-symlinks t             ; シンボリックリンク先をそのまま開く
      auto-revert-check-vc-info t
      global-auto-revert-non-file-buffers t
      history-length 1000
      native-comp-async-report-warnings-errors 'silent
      custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file :noerror :nomessage)

(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 100)

;; winner-mode は既定で C-c ←/→ を奪うが、そこは windmove に使うので取らせない
(setq winner-dont-bind-my-keys t)

(dolist (mode '(column-number-mode
                delete-selection-mode
                electric-pair-mode
                global-auto-revert-mode
                recentf-mode
                repeat-mode
                save-place-mode
                savehist-mode
                show-paren-mode
                winner-mode))
  (funcall mode 1))

;; GUI でだけ意味のあるもの
(dolist (mode '(tool-bar-mode scroll-bar-mode))
  (when (fboundp mode) (funcall mode -1)))
(when (fboundp 'pixel-scroll-precision-mode) (pixel-scroll-precision-mode 1))
(when (fboundp 'context-menu-mode) (context-menu-mode 1))

;;;; ------------------------------------------------------------ 見た目
;; modus-themes は Emacs 28 から標準添付（コントラストが高く端末でも読める）
(setq modus-themes-italic-constructs t
      modus-themes-bold-constructs t)
(load-theme 'modus-vivendi :no-confirm)

;; 行番号は linum ではなく display-line-numbers（Emacs 26 以降の標準）
(setq display-line-numbers-width 3)
(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode))
(add-hook 'prog-mode-hook #'hl-line-mode)

;; 全角スペースと行末の空白だけを可視化する
(setq whitespace-style '(face trailing spaces tabs space-mark tab-mark)
      whitespace-space-regexp "\\(\u3000+\\)"          ; 全角スペースのみ対象
      whitespace-trailing-regexp "\\([ \u00A0]+\\)$"
      whitespace-display-mappings '((space-mark ?\u3000 [?\u25a1])   ; 全角スペース → □
                                    (tab-mark ?\t [?\u00BB ?\t])))
(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'whitespace-mode))

;;;; ------------------------------------------------------------ 補完
(if (>= emacs-major-version 29)
    (progn
      ;; ミニバッファを縦に並べる
      (use-package vertico
        :init (vertico-mode))

      ;; 空白区切りの部分一致で絞り込む
      (use-package orderless
        :init
        (setq completion-styles '(orderless basic)
              completion-category-overrides '((file (styles basic partial-completion)))))

      ;; 候補の横に説明を出す
      (use-package marginalia
        :init (marginalia-mode))

      ;; helm-swoop / ace-isearch の後継
      (use-package consult
        :bind (("C-s"   . consult-line)
               ("C-x b" . consult-buffer)
               ("M-y"   . consult-yank-pop)
               ("M-g g" . consult-goto-line)
               ("M-g i" . consult-imenu)
               ("C-c s" . consult-grep)))

      ;; auto-complete の後継（バッファ内補完）
      (use-package corfu
        :init (global-corfu-mode)
        :custom
        (corfu-auto t)
        (corfu-auto-delay 0.2)
        (corfu-auto-prefix 2)
        (corfu-cycle t))

      ;; corfu は子フレームで描画するので、それが使えない端末 Emacs 30 以下では
      ;; popon で代替する（31 以降は端末でも子フレームが使えるので不要）
      (when (and (not (display-graphic-p)) (< emacs-major-version 31))
        (use-package corfu-terminal
          :init (corfu-terminal-mode 1)))

      (use-package cape
        :init (add-hook 'completion-at-point-functions #'cape-file)))

  ;; Emacs 28: 組み込みの機能で代替する
  (fido-vertical-mode 1)
  (use-package company
    :init (global-company-mode)
    :custom
    (company-idle-delay 0.2)
    (company-minimum-prefix-length 2)))

;;;; ------------------------------------------------------------ 編集支援
(use-package which-key
  :init (which-key-mode))

(use-package avy
  :custom (avy-background nil)
  :bind (("M-g c" . avy-goto-char-timer)
         ("M-g l" . avy-goto-line)))

;; 自分が触った行だけ行末空白を削除する（無関係な差分を作らない）
(use-package ws-butler
  :hook (prog-mode . ws-butler-mode))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;;;; ------------------------------------------------------------ Git
(use-package magit
  :bind ("C-x g" . magit-status))

(use-package diff-hl
  :hook ((prog-mode . diff-hl-mode)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  ;; 端末ではフリンジが無いので余白に出す
  (unless (display-graphic-p) (diff-hl-margin-mode 1)))

;;;; ------------------------------------------------------------ 構文チェック / LSP
;; flycheck ではなく組み込みの flymake を使う（eglot とそのまま繋がる）
(use-package flymake
  :ensure nil
  :hook (emacs-lisp-mode . flymake-mode)
  :bind (:map flymake-mode-map
              ("C-c ! n" . flymake-goto-next-error)
              ("C-c ! p" . flymake-goto-prev-error)
              ("C-c ! l" . flymake-show-buffer-diagnostics)))

(my/ensure-package 'eglot)
(use-package eglot
  :ensure nil
  :commands (eglot eglot-ensure)
  :init
  ;; 言語サーバが実際に入っている言語だけ自動で起動する
  (dolist (spec '((go-mode         . "gopls")
                  (python-mode     . "pylsp")
                  (terraform-mode  . "terraform-ls")
                  (yaml-mode       . "yaml-language-server")))
    (when (executable-find (cdr spec))
      (add-hook (intern (format "%s-hook" (car spec))) #'eglot-ensure))))

;;;; ------------------------------------------------------------ Lisp
(defun my/reverse-transpose-sexps (arg)
  "直前の sexp と入れ替える。ARG は繰り返し回数。"
  (interactive "*p")
  (transpose-sexps (- arg))
  (backward-sexp arg)
  (forward-sexp 1))

(defun my/kill-sexp-or-line ()
  "空行なら行を、そうでなければ sexp を kill する。"
  (interactive "*")
  (if (= (line-beginning-position) (line-end-position))
      (kill-line)
    (kill-sexp)))

(defun my/copy-sexp ()
  "ポイント位置の sexp を kill-ring にコピーする。"
  (interactive)
  (save-excursion
    (let ((beg (point)))
      (forward-sexp)
      (copy-region-as-kill beg (point)))))

(defun my/clone-sexp ()
  "ポイント位置の sexp を複製して次の行に挿入する。"
  (interactive "*")
  (let* ((beg (point))
         (end (save-excursion (forward-sexp) (point)))
         (text (buffer-substring-no-properties beg end)))
    (save-excursion
      (goto-char end)
      (newline-and-indent)
      (insert text))))

(defun my/avy-goto-sexp-begin ()
  "画面内の開き括弧へ avy でジャンプする。"
  (interactive)
  (let ((avy-all-windows nil))
    (avy-jump (regexp-quote "("))))

(defun my/avy-goto-sexp-end ()
  "画面内の閉じ括弧へ avy でジャンプする。"
  (interactive)
  (let ((avy-all-windows nil))
    (when (avy-jump (regexp-quote ")"))
      (forward-char))))

(use-package paredit
  :hook ((emacs-lisp-mode
          lisp-mode
          lisp-interaction-mode
          scheme-mode
          ielm-mode) . enable-paredit-mode)
  :init
  (add-hook 'eval-expression-minibuffer-setup-hook #'enable-paredit-mode)
  :bind (:map paredit-mode-map
              ("C-t"   . transpose-sexps)
              ("M-t"   . my/reverse-transpose-sexps)
              ("C-k"   . my/kill-sexp-or-line)
              ("M-k"   . paredit-kill)
              ("M-f"   . paredit-forward)
              ("M-b"   . paredit-backward)
              ("M-d"   . paredit-forward-down)
              ("M-u"   . paredit-forward-up)
              ("M-c"   . paredit-convolute-sexp)
              ("C-w"   . my/copy-sexp)
              ("C-S-w" . kill-region)
              ("C-,"   . my/clone-sexp)
              ("C-o"   . my/avy-goto-sexp-begin)
              ("C-S-o" . my/avy-goto-sexp-end))
  :config
  (eldoc-add-command 'paredit-backward-delete 'paredit-close-round))

(use-package slime
  :commands (slime slime-connect)
  :init
  ;; 処理系は Roswell 経由で起動する。
  ;; ~/.roswell/helper.el は読み込まない — あれが読ませようとする roswell 同梱の
  ;; SLIME は 2018 年版で、新しい Emacs では動かない。ELPA の最新版を使う。
  (setq inferior-lisp-program
        (if (executable-find "ros") "ros -Q run" "sbcl"))
  :bind (("<f2>" . slime-hyperspec-lookup))
  :config
  (setq slime-contribs '(slime-fancy))
  (add-hook 'slime-repl-mode-hook #'enable-paredit-mode)
  ;; SLIME の REPL が DEL を奪って paredit と衝突するのを防ぐ
  (with-eval-after-load 'slime-repl
    (define-key slime-repl-mode-map
                (read-kbd-macro paredit-backward-delete-key) nil))
  ;; HyperSpec をローカルに置いている場合だけ参照先を差し替える
  (let ((root "/usr/local/share/doc/hyperspec/HyperSpec/"))
    (when (file-directory-p root)
      (setq common-lisp-hyperspec-root root
            common-lisp-hyperspec-symbol-table (concat root "Data/Map_Sym.txt")
            common-lisp-hyperspec-issuex-table (concat root "Data/Map_IssX.txt")))))

;;;; ------------------------------------------------------------ 各種言語
(use-package markdown-mode
  :mode ("\\.md\\'" "\\.markdown\\'"))

(use-package yaml-mode
  :mode "\\.ya?ml\\'"
  :hook (yaml-mode . (lambda () (setq-local tab-width 2))))

(use-package terraform-mode
  :mode "\\.tf\\(vars\\)?\\'")

(use-package go-mode
  :mode "\\.go\\'"
  :hook (go-mode . (lambda () (setq-local indent-tabs-mode t tab-width 4))))

(use-package csv-mode
  :mode "\\.csv\\'")

(use-package plantuml-mode
  :mode ("\\.\\(plantuml\\|puml\\|pu\\|uml\\)\\'" . plantuml-mode)
  :init
  ;; plantuml コマンドがあれば jar を探さずそちらを使う。C-c C-c でプレビュー。
  (setq plantuml-default-exec-mode (if (executable-find "plantuml") 'executable 'jar)
        plantuml-options "-charset UTF-8"))

;;;; ------------------------------------------------------------ キーバインド
;; 1行ずつスクロール（組み込みコマンドで十分）
(global-set-key (kbd "M-n") #'scroll-up-line)
(global-set-key (kbd "M-p") #'scroll-down-line)

;; ウィンドウ構成を戻す / やり直す（winner の既定キーは windmove に譲った）
(global-set-key (kbd "C-c u") #'winner-undo)
(global-set-key (kbd "C-c U") #'winner-redo)

;; C-c + 矢印でウィンドウ移動
(global-set-key (kbd "C-c <left>")  #'windmove-left)
(global-set-key (kbd "C-c <right>") #'windmove-right)
(global-set-key (kbd "C-c <up>")    #'windmove-up)
(global-set-key (kbd "C-c <down>")  #'windmove-down)

;; ファイルツリーの代わりに dired を開く
(global-set-key [f8] #'dired-jump)

(defun my/json-pretty-print-dwim ()
  "リージョン、無ければバッファ全体の JSON を整形する。"
  (interactive "*")
  (require 'json)
  (if (use-region-p)
      (json-pretty-print (region-beginning) (region-end))
    (json-pretty-print-buffer)))
(global-set-key (kbd "C-c C-b j") #'my/json-pretty-print-dwim)

;;;; ------------------------------------------------------------ マシン固有設定
(load (expand-file-name "local.el" user-emacs-directory) :noerror :nomessage)

(provide 'init)
;;; init.el ends here
