;;; init.el --- Modern Emacs configuration -*- lexical-binding: t -*-
;;
;; Requires Emacs 30+
;; IDE features via eglot (built-in LSP client) + tree-sitter (built-in)
;; Completion via corfu (built-in in 30)
;;
;; Language servers needed (install once):
;;   C:          sudo dnf install clang-tools-extra     (provides clangd)
;;   Java:       sudo dnf install java-25-openjdk-devel (eglot handles jdtls)
;;   Python:     pip install pyright
;;   JS/TS:      sudo npm install -g typescript typescript-language-server

;;; ──────────────────────────────────────────────
;;; PACKAGE SETUP
;;; ──────────────────────────────────────────────

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; use-package is built-in from Emacs 29+
(require 'use-package)
(setq use-package-always-ensure t)   ; auto-install packages from MELPA if missing

;;; ──────────────────────────────────────────────
;;; GENERAL SETTINGS
;;; ──────────────────────────────────────────────

;; Allow # to be entered on a Mac keyboard (uncomment if using macOS)
;; (global-set-key (kbd "M-3") '(lambda () (interactive) (insert "#")))

;; Keep backup files out of the way
(setq backup-directory-alist `(("." . "~/.emacs.d/backups")))

;; Indentation
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;; Performance tweaks (important for LSP)
(setq gc-cons-threshold 100000000)             ; 100MB — raise GC threshold
(setq read-process-output-max (* 1024 1024 3)) ; 3MB — read more from LSP per chunk

;; Quality-of-life defaults
(setq ring-bell-function 'ignore)            ; no bell
(column-number-mode 1)                       ; show column in modeline
(show-paren-mode 1)                          ; highlight matching parens
(electric-pair-mode 1)                       ; auto-close brackets/quotes
(delete-selection-mode 1)                    ; typing replaces selected region
(global-auto-revert-mode 1)                  ; reload files changed on disk

;;; ──────────────────────────────────────────────
;;; THEME
;;; ──────────────────────────────────────────────

;; tango-dark theme
;; To try others: M-x customize-themes
(load-theme 'tango-dark t)

;;; ──────────────────────────────────────────────
;;; TREE-SITTER — better syntax highlighting
;;; ──────────────────────────────────────────────
;;
;; Tree-sitter is built into Emacs 29+. It uses compiled grammars that need
;; to be installed once. Run M-x treesit-install-language-grammar for each
;; language, or let the block below handle it automatically on first start.
;;
;; After grammars are installed, the *-ts-mode variants are used automatically
;; via major-mode-remap-alist below.

(setq treesit-language-source-alist
      '((c          . ("https://github.com/tree-sitter/tree-sitter-c"))
        (cpp        . ("https://github.com/tree-sitter/tree-sitter-cpp"))
        (java       . ("https://github.com/tree-sitter/tree-sitter-java"))
        (python     . ("https://github.com/tree-sitter/tree-sitter-python"))
        (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript" "master" "src"))
        (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src"))
        (tsx        . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src"))
        (json       . ("https://github.com/tree-sitter/tree-sitter-json"))
        (yaml       . ("https://github.com/tree-sitter/tree-sitter-yaml"))))

;; Install any missing grammars automatically
(dolist (lang (mapcar #'car treesit-language-source-alist))
  (unless (treesit-language-available-p lang)
    (message "Installing tree-sitter grammar for %s..." lang)
    (treesit-install-language-grammar lang)))

;; Remap classic major modes → tree-sitter enhanced versions
(setq major-mode-remap-alist
      '((c-mode          . c-ts-mode)
        (c++-mode        . c++-ts-mode)
        (java-mode       . java-ts-mode)
        (python-mode     . python-ts-mode)
        (js-mode         . js-ts-mode)
        (typescript-mode . typescript-ts-mode)
        (json-mode       . json-ts-mode)
        (yaml-mode       . yaml-ts-mode)))

;; Explicit auto-mode-alist entries for tree-sitter modes
;; (belt and braces approach as remap-alist alone isn't always reliable)
(add-to-list 'auto-mode-alist '("\\.ts\\'"    . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'"    . js-ts-mode))
(add-to-list 'auto-mode-alist '("\\.py\\'"    . python-ts-mode))
(add-to-list 'auto-mode-alist '("\\.c\\'"     . c-ts-mode))
(add-to-list 'auto-mode-alist '("\\.h\\'"     . c-ts-mode))
(add-to-list 'auto-mode-alist '("\\.cpp\\'"   . c++-ts-mode))
(add-to-list 'auto-mode-alist '("\\.cc\\'"    . c++-ts-mode))
(add-to-list 'auto-mode-alist '("\\.cxx\\'"   . c++-ts-mode))
(add-to-list 'auto-mode-alist '("\\.hpp\\'"   . c++-ts-mode))
(add-to-list 'auto-mode-alist '("\\.hh\\'"    . c++-ts-mode))
(add-to-list 'auto-mode-alist '("\\.java\\'"  . java-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-ts-mode))

;;; ──────────────────────────────────────────────
;;; EGLOT — LSP client (built-in)
;;; ──────────────────────────────────────────────
;;
;; Eglot connects to language servers and provides:
;;   M-.         go to definition
;;   M-,         go back
;;   M-?         find references
;;   C-c C-a     code actions (quick fixes, refactors)
;;   C-c C-d     show documentation
;;   C-c ! n/p   next/previous diagnostic (flymake)

(require 'eglot)

;; Java: tell eglot where to find jdtls
;; Install with: sudo dnf install java-devel  OR  use jdtls from MELPA (see below)
(use-package eglot-java
  :hook (java-ts-mode . eglot-java-mode))
;; eglot-java auto-downloads jdtls on first use — no manual setup needed.

;; Auto-start eglot for all our languages
(dolist (hook '(c-ts-mode-hook
                c++-ts-mode-hook
                java-ts-mode-hook
                python-ts-mode-hook
                js-ts-mode-hook
                typescript-ts-mode-hook))
  (add-hook hook #'eglot-ensure))

;; TypeScript: eglot finds typescript-language-server automatically if it's on PATH
;; (installed via: npm install -g typescript typescript-language-server)
(add-to-list 'eglot-server-programs
             '((js-ts-mode typescript-ts-mode tsx-ts-mode)
               . ("typescript-language-server" "--stdio")))

;; Format buffer on save (optional — comment out if you prefer manual formatting)
(add-hook 'before-save-hook
          (lambda ()
            (when (eglot-managed-p)
              (eglot-format-buffer))))

;; Eglot performance tweaks
(setq eglot-events-buffer-size 0)             ; disable event logging (speeds things up)
(setq eglot-sync-connect nil)                 ; don't block on connect

;;; ──────────────────────────────────────────────
;;; MAGIT - git mode
;;; ──────────────────────────────────────────────

(use-package magit)

;;; ──────────────────────────────────────────────
;;; CORFU — completion popup (built-in in Emacs 30)
;;; ──────────────────────────────────────────────
;;
;; Replaces company-mode. Shows completions in a popup as you type.
;; TAB or RET to accept. M-p/M-n to cycle.

(use-package corfu
  :custom
  (corfu-auto t)              ; show completions automatically (no need to press TAB)
  (corfu-auto-delay 0.2)      ; slight delay to avoid popping up on every keystroke
  (corfu-auto-prefix 2)       ; start completing after 2 characters
  (corfu-cycle t)             ; wrap around at end of completion list
  (corfu-quit-no-match t)     ; close popup if no match
  :init
  (global-corfu-mode))

;; corfu-terminal: makes corfu work if you ever use Emacs in a terminal
(use-package corfu-terminal
  :unless (display-graphic-p)
  :config (corfu-terminal-mode 1))

;;; ──────────────────────────────────────────────
;;; YASNIPPET — code snippets (keeping yours)
;;; ──────────────────────────────────────────────

(use-package yasnippet
  :config (yas-global-mode 1))

;; Optional: a large collection of pre-made snippets
(use-package yasnippet-snippets)

;;; ──────────────────────────────────────────────
;;; VERTICO + ORDERLESS — better M-x and minibuffer
;;; ──────────────────────────────────────────────
;;
;; Vertico: shows a vertical list when you use M-x, C-x C-f, etc.
;; Orderless: lets you type words in any order to filter (e.g. "buf switch" finds switch-buffer)

(use-package vertico
  :init (vertico-mode))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;;; ──────────────────────────────────────────────
;;; MARGINALIA — annotations in the minibuffer
;;; ──────────────────────────────────────────────
;;
;; Shows docstrings, file sizes, keybindings etc. next to M-x candidates

(use-package marginalia
  :init (marginalia-mode))

;;; ──────────────────────────────────────────────
;;; WHICH-KEY — shows available keybindings
;;; ──────────────────────────────────────────────
;;
;; After pressing a prefix key (e.g. C-c), shows a popup of what you can press next.
;; Built-in from Emacs 30.

(which-key-mode 1)

;;; ──────────────────────────────────────────────
;;; FLYMAKE — inline diagnostics (built-in)
;;; ──────────────────────────────────────────────
;;
;; Eglot uses flymake automatically. Errors/warnings show as underlines.
;; M-x flymake-show-buffer-diagnostics  — see all errors in a buffer
;; C-c ! n / C-c ! p                   — jump to next/prev error

(add-hook 'prog-mode-hook #'flymake-mode)

;;; ──────────────────────────────────────────────
;;; DOCKERFILE SUPPORT (keeping your original)
;;; ──────────────────────────────────────────────

(use-package dockerfile-mode)

;;; ──────────────────────────────────────────────
;;; MARKDOWN SUPPORT
;;; ──────────────────────────────────────────────

(use-package markdown-mode)

;;; ──────────────────────────────────────────────
;;; SQL
;;; ──────────────────────────────────────────────

;; Tell sql-mode to use Postgres highlighting by default
(setq sql-dialect 'postgres)

;;; ──────────────────────────────────────────────
;;; INDENT BARS - draws visual indent bars
;;; ──────────────────────────────────────────────

(use-package indent-bars
  :hook ((yaml-ts-mode   . indent-bars-mode)
         (python-ts-mode . indent-bars-mode)))



;;; ──────────────────────────────────────────────
;;; HELPFUL KEY BINDINGS SUMMARY
;;; ──────────────────────────────────────────────
;;
;; IDE actions (via eglot):
;;   M-.           Go to definition
;;   M-,           Go back (pop mark)
;;   M-?           Find all references
;;   C-c C-r       Rename symbol
;;   C-c C-a       Code actions (quick fix, extract, etc.)
;;   C-c C-d       Show documentation (eldoc)
;;   C-c C-f       Format buffer
;;
;; Diagnostics (via flymake):
;;   M-x flymake-show-buffer-diagnostics    List all errors/warnings
;;   M-n / M-p                              Next/prev error (in diagnostics buffer)
;;
;; Completion (via corfu):
;;   (just type — popup appears automatically)
;;   TAB / RET     Accept completion
;;   M-n / M-p     Cycle through candidates
;;   ESC           Dismiss popup


;;; ──────────────────────────────────────────────
;;; EMACS CUSTOM SYSTEM
;;; ──────────────────────────────────────────────

;; The following is added by Emacs automatically to track which packages are installed.
;; Is untidy but can be left and leaving here to be explicit

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(corfu-terminal dockerfile-mode eglot-java indent-bars magit
                    marginalia markdown-mode orderless vertico
                    yasnippet-snippets)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(provide 'init)
;;; init.el ends here
