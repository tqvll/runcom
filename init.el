(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

(when (eq system-type 'darwin)
  (setq mac-option-modifier 'alt)
  (setq mac-command-modifier 'meta)
  (global-set-key [kp-delete] 'delete-char))

(setq backup-directory-alist '(("." . "~/.saves")))
(setq backup-inhibited t)
(setq auto-save-default nil)

(global-linum-mode t)
(setq linum-format "%d ")

(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)
(show-paren-mode t)
(electric-pair-mode 1)

(delete-selection-mode)

(global-set-key (kbd "M-n") (lambda () (interactive) (scroll-up 1)))
(global-set-key (kbd "M-p") (lambda () (interactive) (scroll-down 1)))

;; allow to read symlinks
(setq vc-follow-symlinks t)
;; autoupdate buffer when the symlinked file updated on VCS
(setq auto-revert-check-vc-info t)

(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/") t)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

(dolist (package '(
                   whitespace
                   avy
                   helm-swoop
                   ace-isearch
                   auto-compile
                   auto-complete
                   avy-flycheck
                   flycheck
                   highlight-indentation
                   base16-theme
                   fuzzy
                   slime
                   ac-slime
                   nimbus-theme
                   paredit
                   eldoc
                   markdown-mode
                   plantuml-mode
                   python-mode
                   go-mode
                   yaml-mode
                   terraform-mode
                   go-autocomplete
                   csv-mode
                   neotree
                   rainbow-delimiters
                   cl-lib
                   color
                   ))
  (unless (package-installed-p package)
    (package-install package))
  (require package))

;; paredit
(autoload 'enable-paredit-mode "paredit" "Turn on pseudo-structural editing of Lisp code." t)
(add-hook 'emacs-lisp-mode-hook       #'enable-paredit-mode)
(add-hook 'eval-expression-minibuffer-setup-hook #'enable-paredit-mode)
(add-hook 'ielm-mode-hook             #'enable-paredit-mode)
(add-hook 'lisp-mode-hook             #'enable-paredit-mode)
(add-hook 'lisp-interaction-mode-hook #'enable-paredit-mode)
(add-hook 'scheme-mode-hook           #'enable-paredit-mode)

(define-key paredit-mode-map "\C-t" 'transpose-sexps)
(define-key paredit-mode-map "\M-t" 'reverse-transpose-sexps)
(define-key paredit-mode-map "\C-k" 'kill-my-sexp)
(define-key paredit-mode-map "\M-k" 'paredit-kill)
(define-key paredit-mode-map "\M-f" 'sp-next-sexp)
(define-key paredit-mode-map "\M-b" 'sp-backward-sexp)
(define-key paredit-mode-map "\C-h" 'sp-down-sexp)
(define-key paredit-mode-map "\C-u" 'sp-up-sexp)
(define-key paredit-mode-map "\C-w" 'sp-copy-sexp)
(define-key paredit-mode-map (kbd "C-S-w") 'kill-region)
(define-key paredit-mode-map (kbd "C-,") 'sp-clone-sexp)
(define-key paredit-mode-map "\M-d" 'paredit-forward-down)
(define-key paredit-mode-map "\M-u" 'paredit-forward-up)
(define-key paredit-mode-map "\M-c" 'paredit-convolute-sexp)
(define-key paredit-mode-map "\C-o" 'avy-goto-sexp-begin)
(define-key paredit-mode-map (kbd "C-S-o") 'avy-goto-sexp-end)

(defun reverse-transpose-sexps (arg)
  (interactive "*p")
  (transpose-sexps (- arg))
  (backward-sexp  arg)
  (forward-sexp 1))

(defun kill-my-sexp ()
  (interactive "*")
  (if (zerop (length (buffer-substring (point-at-bol) (point-at-eol))))
      (kill-line)
      (kill-sexp)))

(setf avy-background nil)

(defun avy-goto-sexp-begin ()
  (interactive "*")
  (let ((avy-all-windows nil))
    (avy-with avy-goto-char
      (avy--process
       (avy--regex-candidates
        (regexp-quote "("))
       (avy--style-fn avy-style)))))

(defun avy-goto-sexp-end ()
  (interactive "*")
  (let ((avy-all-windows nil))
    (avy-with avy-goto-char
      (avy--process
       (avy--regex-candidates
        (regexp-quote ")"))
       (avy--style-fn avy-style)))
    (forward-char)))

(eldoc-add-command
 'paredit-backward-delete
 'paredit-close-round)

(add-hook 'slime-repl-mode-hook (lambda () (paredit-mode +1)))

;; flycheck
(add-hook 'after-init-hook #'global-flycheck-mode)

;; Stop SLIME's REPL from grabbing DEL,
;; which is annoying when backspacing over a'('
(defun override-slime-repl-bindings-with-paredit ()
  (define-key slime-repl-mode-map
    (read-kbd-macro paredit-backward-delete-key) nil))
(add-hook 'slime-repl-mode-hook 'override-slime-repl-bindings-with-paredit)

;; rainbow-delimiters
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)
;; rainbow-delimiters-stronger-colors-mode
;;(defun rainbow-delimiters-using-stronger-colors ()
;;  (interactive)
;;  (cl-loop
;;   for index from 1 to rainbow-delimiters-max-face-count
;;   do
;;   (let ((face (intern (format "rainbow-delimiters-depth-%d-face" index))))
;;     (cl-callf color-saturate-name (face-foreground face) 30))))
;;(add-hook 'emacs-startup-hook 'rainbow-delimiters-using-stronger-colors)

;; whitespace
(setq whitespace-style
      '(
        face
        trailing
        tabs
        spaces
        space-mark
        tab-mark
        ))
(setq whitespace-display-mappings
      '(
        (space-mark ?\u3000 [?\u2423])
        (tab-mark ?\t [?\u00BB ?\t] [?\\ ?\t])
        ))
(setq whitespace-trailing-regexp  "\\([ \u00A0]+\\)$")
(setq whitespace-space-regexp "\\(\u3000+\\)")
(set-face-attribute 'whitespace-trailing nil
                    :foreground "RoyalBlue4"
                    :background "RoyalBlue4"
                    :underline nil)
(set-face-attribute 'whitespace-tab nil
                    :foreground "yellow4"
                    :background "yellow4"
                    :underline nil)
(set-face-attribute 'whitespace-space nil
                    :foreground "gray40"
                    :background "gray20"
                    :underline nil)
(global-whitespace-mode t)

;; yaml-mode
(add-hook 'yaml-mode-hook
          (lambda ()
            (define-key yaml-mode-map "\C-m" 'newline-and-indent)))
(add-hook 'yaml-mode-hook 'highlight-indentation-mode)
(add-hook 'yaml-mode-hook 'highlight-indentation-current-column-mode)
(add-hook 'yaml-mode-hook '(lambda() (setq highlight-indentation-offset 2)))

;; highlight-indentation
(setq highlight-indentation-offset 2)

;; You must install plantuml and set plantuml-jar-path as custom-set-variables
;; Enable plantuml-mode for PlantUML files
(add-to-list 'auto-mode-alist '("\\.plantuml\\'" . plantuml-mode))
(add-to-list 'auto-mode-alist '("\\.uml\\'" . plantuml-mode))
(add-to-list 'auto-mode-alist '("\\.pu\\'" . plantuml-mode))

(setq plantuml-options "-charset UTF-8")

(add-hook 'plantuml-mode-hook
          (lambda () (local-set-key (kbd "C-c C-s") 'plantuml-save-png)))

;;(add-hook 'plantuml-mode-hook
;;          (lambda () (add-hook 'after-save-hook 'plantuml-save-png)))

(defun plantuml-save-png ()
  (interactive)
  (when (buffer-modified-p)
    (map-y-or-n-p "Save this buffer before executing PlantUML?"
                  'save-buffer (list (current-buffer))))
  (let ((code (buffer-string))
        out-file
        cmd)
    (when (string-match "^\\s-*@startuml\\s-+\\(\\S-+\\)\\s*$" code)
      (setq out-file (match-string 1 code)))
    (setq cmd (concat
               "java -Djava.awt.headless=true -jar " plantuml-java-options " "
               (shell-quote-argument plantuml-jar-path) " "
               (and out-file (concat "-t" (file-name-extension out-file))) " "
               plantuml-options " "
               (buffer-file-name)))
    (message cmd)
    (call-process-shell-command cmd nil 0)))

;; neotree
(global-set-key [f8] 'neotree-toggle)
(setq neo-theme (if (display-graphic-p) 'icons 'arrow))
(setq neo-smart-open t)

;; auto-complete-config
(ac-config-default)
(add-to-list 'ac-modes 'text-mode)
(add-to-list 'ac-modes 'fundamental-mode)
(add-to-list 'ac-modes 'org-mode)
(add-to-list 'ac-modes 'yatex-mode)
(ac-set-trigger-key "TAB")
(setq ac-use-menu-map t)
(setq ac-use-fuzzy t)

;; ace-isearch
(global-ace-isearch-mode +1)

;; slime
;;(setq inferior-lisp-program "clisp")
;;(setq slime-contrib '(slime-fancy))
;;(slime-setup '(slime-repl slime-fancy slime-banner slime-indentation))
(load (expand-file-name "~/.roswell/helper.el"))

;; hyperspec
;; You must install hyperspec and set path
(global-set-key [(f2)] 'slime-hyperspec-lookup)
(eval-after-load "slime"
  '(progn
     (setq common-lisp-hyperspec-root
           "/usr/local/share/doc/hyperspec/HyperSpec/")
     (setq common-lisp-hyperspec-symbol-table
           (concat common-lisp-hyperspec-root "Data/Map_Sym.txt"))
     (setq common-lisp-hyperspec-issuex-table
           (concat common-lisp-hyperspec-root "Data/Map_IssX.txt"))))

(global-set-key (kbd "C-c <left>")  'windmove-left)
(global-set-key (kbd "C-c <right>") 'windmove-right)
(global-set-key (kbd "C-c <up>")    'windmove-up)
(global-set-key (kbd "C-c <down>")  'windmove-down)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes (quote (sanityinc-tomorrow-night)))
 '(custom-safe-themes
   (quote
    ("06f0b439b62164c6f8f84fdda32b62fb50b6d00e8b01c2208e55543a6337433a" default)))
 '(package-selected-packages
   (quote
    (flycheck ac-slime base16-theme nimbus-theme fuzzy avy-flycheck ace-isearch avy helm-swoop auto-complete auto-compile)))
 '(plantuml-jar-path "/usr/local/Cellar/plantuml/1.2018.8/libexec/plantuml.jar"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(fset 'beautify-json
   (lambda (&optional arg) "Keyboard macro." (interactive "p") (kmacro-exec-ring-item (quote (" >|jq '.'" 0 "%d")) arg)))
(global-set-key (kbd "C-c C-b j") 'beautify-json)
