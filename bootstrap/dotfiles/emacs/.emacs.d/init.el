(defvar comp-deferred-compliation)
(setq comp-deferred-compilation t)

(setq package-enable-at-startup nil)

(defun nc/disable-bg-in-terminal (&optional frame)
  "Make the default face transparent in TTY frames so the terminal's
own background (e.g. kitty's transparency) shows through."
  (unless (display-graphic-p frame)
    (set-face-background 'default "unspecified-bg" frame)))

(add-hook 'after-make-frame-functions 'nc/disable-bg-in-terminal)
(add-hook 'window-setup-hook 'nc/disable-bg-in-terminal)

;; For graphical (PGTK) frames, use alpha-background — translucent frame
;; without breaking face colors. 80 = 80% opaque / 20% transparent.
(set-frame-parameter nil 'alpha-background 80)
(add-to-list 'default-frame-alist '(alpha-background . 80))

;; With the default background unspecified, faces that derive their
;; background from `default' or `highlight' lose their visual contrast.
;; Pin absolute backgrounds for the diff/magit faces we actually care about
;; so reviews stay legible against a transparent terminal.
(with-eval-after-load 'magit-diff
  (set-face-attribute 'magit-diff-added                  nil :background "#1f3a1f" :foreground "#b8d8b0")
  (set-face-attribute 'magit-diff-added-highlight        nil :background "#264826" :foreground "#d0e8c8")
  (set-face-attribute 'magit-diff-removed                nil :background "#3a1f1f" :foreground "#d8b0b0")
  (set-face-attribute 'magit-diff-removed-highlight      nil :background "#482626" :foreground "#e8c8c8")
  (set-face-attribute 'magit-diff-context                nil :background "unspecified-bg" :foreground "#a0a0a0")
  (set-face-attribute 'magit-diff-context-highlight      nil :background "#1f2228" :foreground "#c0c0c0")
  (set-face-attribute 'magit-diff-hunk-heading           nil :background "#1c1c24" :foreground "#a0a0b0")
  (set-face-attribute 'magit-diff-hunk-heading-highlight nil :background "#2a2a36" :foreground "#d0d0e0")
  (set-face-attribute 'magit-diff-file-heading           nil :background "unspecified-bg" :foreground "#d0d0e0" :weight 'bold)
  (set-face-attribute 'magit-diff-file-heading-highlight nil :background "#2a2a36" :foreground "#e8e8f0" :weight 'bold)
  (set-face-attribute 'magit-diff-file-heading-selection nil :background "#3a3046" :foreground "#f0d8a0" :weight 'bold))

;; magit applies these to the whole section under the cursor (status buffer
;; sections, log entries, etc.). Default is a bright wash that obscures text.
(with-eval-after-load 'magit
  (set-face-attribute 'magit-section-highlight           nil :background "#1f2228")
  (set-face-attribute 'magit-section-heading-selection   nil :background "#3a3046" :foreground "#f0d8a0"))

(with-eval-after-load 'diff-mode
  (set-face-attribute 'diff-added          nil :background "#1f3a1f" :foreground "#b8d8b0")
  (set-face-attribute 'diff-removed        nil :background "#3a1f1f" :foreground "#d8b0b0")
  (set-face-attribute 'diff-changed        nil :background "#3a3a1f" :foreground "#d8d8b0")
  (set-face-attribute 'diff-refine-added   nil :background "#2c5a2c" :foreground "#e0f0d8")
  (set-face-attribute 'diff-refine-removed nil :background "#5a2c2c" :foreground "#f0d8d8"))

(setq markdown-hide-markup t)
(setq markdown-fontify-code-blocks-natively t)
(setq markdown-enable-math t)

(add-hook 'markdown-mode-hook #'visual-line-mode)

;; --------------- Power User Stuff ---------------

(setq inhibit-startup-message t)
(put 'set-goal-column 'disabled nil)
(put 'downcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(put 'eval-expression 'disabled nil)
(put 'erase-buffer 'disabled nil)
(save-place-mode 1)
(global-auto-revert-mode 1)

(setq-default show-trailing-whitespace nil)
(setq read-buffer-completion-ignore-case t)
(setq read-file-name-completion-ignore-case t)
;;(setq backup-inhibited t)
(column-number-mode 'true)
(setq compile-command "make -j")
(setq projectile-project-compilation-cmd "cmake --build build -j")
(setq backup-directory-alist `(("." . "~/.saves")))
(setq backup-by-copying t)

;; --------------- Theme ---------------

(load-theme 'wombat t)

;; --------------- Generic key binding ---------------

(global-set-key "\M-k"   'sp-kill-sexp)
(global-set-key "\M-\C-k" 'crux-kill-whole-line)
(global-set-key "\M-g"   'goto-line-with-feedback)
(global-set-key "\M-r"   'revert-buffer)
(global-set-key "\C-ce"  'ediff-buffers)
(global-set-key "\M-@"   'er/expand-region)
(global-set-key "\M-n"   'next-error)
(global-set-key "\M-p"   'previous-error)

;; Code constructor module stuff - formalize some day
(global-set-key "\C-c "  'cc-find-other-file)
(global-set-key "\C-ca"  'cc-append-to-line)
(global-set-key "\C-cc"  'cc-chomp-lines)
;;(global-set-key "\C-cr"  'cc-chomp-lines-regexp)

;; --------------- Personal Emacs Extensions ---------------

(add-to-list 'load-path (expand-file-name "programming" "~/.emacs.d/personal"))
(require 'code-constructor)
(require 'white-space)

;; --------------- General Setup ---------------

(defun goto-line-with-feedback ()
  "Show line numbers temporarily, while prompting for the line number input"
  (interactive)
  (unwind-protect
      (progn
        (display-line-numbers-mode 1)
        (goto-line (read-number "Goto line: ")))
    (display-line-numbers-mode -1)))

;; Resizing the Emacs frame can be a terribly expensive part of changing the
;; font. By inhibiting this, we easily halve startup times with fonts that are
;; larger than the system default.
(setq frame-inhibit-implied-resize t)

(setq package-enable-at-startup nil)

;; Resizing the Emacs frame can be a terribly expensive part of changing the
;; font. By inhibiting this, we easily halve startup times with fonts that are
;; larger than the system default.
(setq frame-inhibit-implied-resize t)

(menu-bar-mode -1)
(unless (and (display-graphic-p) (eq system-type 'darwin))
    (push '(menu-bar-lines . 0) default-frame-alist))
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; max memory available for gc on startup
(defvar me/gc-cons-threshold 16777216)
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold me/gc-cons-threshold
                  gc-cons-percentage 0.1)))

;; max memory available for gc when opening minibuffer
(defun me/defer-garbage-collection-h ()
  (setq gc-cons-threshold most-positive-fixnum))

(defun me/restore-garbage-collection-h ()(setq site-run-file nil)
  ;; Defer it so that commands launched immediately after will enjoy the
  ;; benefits.
  (run-at-time
   1 nil (lambda () (setq gc-cons-threshold me/gc-cons-threshold))))

(add-hook 'minibuffer-setup-hook #'me/defer-garbage-collection-h)
(add-hook 'minibuffer-exit-hook #'me/restore-garbage-collection-h)
(setq garbage-collection-messages t)

(defvar me/-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist me/-file-name-handler-alist)))

(setq site-run-file nil)

(setq inhibit-compacting-font-caches t)


(when (boundp 'read-process-output-max)
  ;; 1MB in bytes, default 4096 bytes
  (setq read-process-output-max 1048576))


(setq straight-use-package-by-default t
      use-package-always-defer t
      straight-cache-autoloads t
      straight-vc-git-default-clone-depth 1
      straight-check-for-modifications '(find-when-checking)
      package-enable-at-startup nil
      vc-follow-symlinks t)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))
(setq vc-follow-symlinks 'ask) ; restore default

(require 'straight-x)

(straight-use-package 'use-package)

(use-package esup
  :demand t
  :commands esup)

(use-package benchmark-init
  :demand t
  :straight (:host github :repo "kekeimiku/benchmark-init-el")
  :hook (after-init . benchmark-init/deactivate))

(add-hook
 'emacs-startup-hook
 (lambda ()
   (message "Emacs ready in %s with %d garbage collections."
            (format
             "%.2f seconds"
             (float-time
              (time-subtract after-init-time before-init-time)))
            gcs-done)))

(use-package gcmh
  :demand t
  :config
  (gcmh-mode 1))

(provide 'early-init)

(use-package emacs
  :init
  ;; Add prompt indicator to `completing-read-multiple'.
  ;; We display [CRM<separator>], e.g., [CRM,] if the separator is a comma.
  (defun crm-indicator (args)
    (cons (format "[CRM%s] %s"
                  (replace-regexp-in-string
                   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
                   crm-separator)
                  (car args))
          (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

  ;; Do not allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

  ;; Emacs 28: Hide commands in M-x which do not work in the current mode.
  (setq read-extended-command-predicate
        #'command-completion-default-include-p)

  ;; Enable recursive minibuffers
  (setq enable-recursive-minibuffers t))

(use-package repeat
  :ensure t
  :hook (after-init . repeat-mode)
  :custom
  (repeat-too-dangerous '(kill-this-buffer))
  (repeat-exit-timeout 5))

(use-package beacon
  :init
  (beacon-mode))

(use-package use-package-chords
  :ensure t
  :demand t
  :init (key-chord-mode 1))

(use-package yasnippet
  :ensure t
  :init
  (yas-global-mode 1))

(use-package powerline
  :init
  (powerline-default-theme)
  :ensure t)

(use-package magit
  :ensure t)

(use-package fancy-compilation
  :ensure t)

(with-eval-after-load 'compile
  (fancy-compilation-mode))

(use-package ag
  :ensure t)

;;(setq projectile-command-map (kbd "C-c p"))
(put 'projectile-project-compilation-cmd 'safe-local-variable #'stringp)
(use-package projectile
  :ensure t
  :bind-keymap ("C-c p" . projectile-command-map))

(use-package swiper
  :ensure t
  :bind (("C-s" . swiper)))

(use-package avy
  :ensure t
  :chords (("jl" . avy-goto-line)
	   ("jk" . avy-goto-char)))

(use-package rtags
  :disabled
  :ensure t
  :demand t
  :bind (("M-." . rtags-find-symbol-at-point)
	 ("M-," . rtags-find-references)
	 ("M-*" . rtags-location-stack-back))
  :config (setq rtags-completions-enabled t
		rtags-path "/home/ncrapo/.local/bin"
		;;rtags-rc-binary-name "/home/manoj/.emacs.d/rtags/bin/rc"
		;;rtags-rdm-binary-name "/home/manoj/.emacs.d/rtags/bin/rdm")
		)
  :hook (c++-ts-mode . rtags-start-process-unless-running)
  :init
  (rtags-enable-standard-keybindings global-map))

(use-package lsp-mode
  :ensure t
  :bind (("M-?" . lsp-find-references))
  :config
  (setq lsp-headerline-breadcrumb-enable nil)
  (setq lsp-idle-delay 0.1))

(use-package company
  :ensure t
  :bind (("C-c /" . company-complete))
  :config
  (setq company-idle-delay 1
	company-minimum-prefix-length 2))

(use-package flycheck
  :ensure t
  :bind (("C-c f" . flycheck-list-errors))
  :init
  (global-flycheck-mode 1))

(use-package which-key
  :ensure t
  :init
  (which-key-mode 1))

(use-package undo-tree
  :chords (("uu" . undo-tree-visualize))
  :init
  (global-undo-tree-mode)
  :config
  (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))
  :ensure t)

;; Other potentially useful commands:
;;  - crux-duplicate-current-line-or-region
(use-package crux
  :bind (("C-c r" . crux-rename-file-and-buffer)
	 ("C-k" . crux-smart-kill-line)
	 ("C-c i" . crux-find-user-init-file)
	 ("C-c s" . crux-sudo-edit)
	 ("C-c d" . crux-insert-date))
  :ensure t)

(use-package drag-stuff
  :ensure t
  :bind (("M-<up>" . drag-stuff-up)
	 ("M-<down>" . drag-stuff-down)
	 ("M-<right>" . drag-stuff-right)
	 ("M-<left>" . drag-stuff-left))
  :init
  (drag-stuff-global-mode 1))

(use-package ace-window
  :ensure t
  :bind (("M-o" . ace-window))
  :config
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

(use-package expand-region
  :ensure t)

;; Balance parens while typing code
(use-package smartparens
  :ensure t)

(use-package smart-compile
  :ensure t)

(use-package savehist
  :demand t
  :config
  (savehist-mode))

(use-package vertico
  :ensure t
  :demand t
  :custom
  (vertico-resize t)
  (vertico-cycle t)
  :config
  (vertico-mode)
  (add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy)
  :bind (:map vertico-map
	      ("RET" . vertico-directory-enter)
	      ("C-l" . vertico-directory-delete-word)))

(use-package icomplete
  :ensure t
  :custom
  (read-file-name-completion-ignore-case t)
  (read-buffer-completion-ignore-case t)
  (completion-ignore-case t)

  (completion-category-defaults nil)
  (completion-category-overrides
   '((file (styles basic partial-completion))))

  (completion-group t)
  (completions-group-format
        (concat
         (propertize "    " 'face 'completions-group-separator)
         (propertize " %s " 'face 'completions-group-title)
         (propertize " " 'face 'completions-group-separator
                     'display '(space :align-to right)))))

;; dired customization
(setq dired-dwim-target t)
(setq trash-directory "~/.trash")
(setq delete-by-moving-to-trash t)
(add-hook 'dired-mode-hook 'dired-hide-details-mode)
(setq global-auto-revert-non-file-buffers t)

(use-package multiple-cursors
  :ensure t
  :bind (("M-#" . mc/mark-next-like-this)))

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode))

(use-package orderless
  :ensure t
  :demand t
  :custom
  (completion-styles '(orderless))
  :config
  (defun prefix-if-tilde (pattern _index _total)
    (when (string-suffix-p "~" pattern)
      `(orderless-prefixes . ,(substring pattern 0 -1))))

  (defun regexp-if-slash (pattern _index _total)
    (when (string-prefix-p "/" pattern)
      `(orderless-regexp . ,(substring pattern 1))))

  (defun literal-if-equal (pattern _index _total)
    (when (string-suffix-p "=" pattern)
      `(orderless-literal . ,(substring pattern 0 -1))))

  (defun without-if-bang (pattern _index _total)
    (cond
     ((equal "!" pattern)
      '(orderless-literal . ""))
     ((string-prefix-p "!" pattern)
      `(orderless-without-literal . ,(substring pattern 1)))))

  (setq orderless-matching-styles '(orderless-flex))
  (setq orderless-style-dispatchers
        '(prefix-if-tilde
          regexp-if-slash
          literal-if-equal
          without-if-bang)))

(use-package consult
  :ensure t
;;  (leader-def
;;    "ff" 'find-file
;;    "fr" 'consult-recent-file
;;    "bb" 'consult-buffer
;;    "tc" 'consult-theme
;;    "/"  'consult-ripgrep
;;    "g/" 'consult-git-grep)
  :custom
  (consult-project-root-function #'projectile-project-root)
  (consult-narrow-key "<"))

(setq custom-file (locate-user-emacs-file "custom-vars.el"))
(load custom-file 'noerror 'nomessage)

;; Manually installing v0.21.0 of the treesit grammars for emacs
;; version 29.3
(use-package treesit-auto
  :ensure t
  :demand t
;;  :custom
;;  (treesit-auto-install 'prompt)
  :config
;;  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

(use-package clang-format
  :ensure t)

(use-package cmake-mode
  :ensure t)

(defun my-c-mode-common-hook ()
  (c-set-style "BSD")
  (smartparens-mode 1)
  (whitespace-set-indention-to-spaces)
  (setq fill-column 80))
(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)

(defun my-c++-mode-hook ()
  (lsp)
  (smartparens-mode 1))
(add-hook 'c++-mode-hook 'my-c++-mode-hook)

(defun my-c++-ts-mode-hook ()
  (my-c++-mode-hook))
(add-hook 'c++-ts-mode-hook 'my-c++-ts-mode-hook)

(defun my-c-mode-hook ()
  (smartparens-mode 1))
(add-hook 'c-mode-hook 'my-c-mode-hook)

(use-package c-ts-mode
    :ensure nil ;; emacs built-in
    :preface
    (defun my--c-ts-indent-style()
        "Override the built-in BSD indentation style with some additional rules.
         Docs: https://www.gnu.org/software/emacs/manual/html_node/elisp/Parser_002dbased-Indentation.html
         Notes: `treesit-explore-mode' can be very useful to see where you're at in the tree-sitter tree,
                especially paired with `(setq treesit--indent-verbose t)' to debug what rules is being
                applied at a given point."
        `(;; do not indent preprocessor statements
          ((node-is "preproc") column-0 0)
          ;; do not indent namespace children
          ((n-p-gp nil nil "namespace_definition") grand-parent 0)
          ;; append to bsd style
          ,@(alist-get 'bsd (c-ts-mode--indent-styles 'cpp))))
    :config
    (setq c-ts-mode-indent-offset 4)
    (setq c-ts-mode-indent-style #'my--c-ts-indent-style))

;; (use-package consult-projectile
;;   :after consult projectile
;;   :demand t
;;   :straight (consult-projectile :type git :host gitlab :repo "OlMon/consult-projectile" :branch "master")
;;   (leader-def
;;     "pp" 'consult-projectile))

;; (use-package consult-lsp
;;   :straight (consult-lsp :type git :host github :repo "gagbo/consult-lsp" :protocol ssh)
;;   :commands (consult-lsp-symbols consult-lsp-diagnostics consult-lsp-file-symbols)
;;   :config (define-key lsp-mode-map [remap xref-find-apropos] #'consult-lsp-symbols))

(use-package eterm-256color
  :ensure t
  :hook (term-mode . eterm-256color-mode))

(defun me/disable-global-hl-line-mode ()
  (global-hl-line-mode -1))

(use-package dashboard
  :ensure t
  :demand
  :config
  (setq dashboard-center-content t)
  (setq dashboard-items '((recents   . 5)
                          (bookmarks . 5)
                          (projects  . 5)
                          (agenda    . 5)))
  (dashboard-setup-startup-hook))

(use-package vterm
  :ensure nil ;; built-in
  :straight nil
  :commands vterm vterm-other-window
  :hook (vterm-mode . #'me/disable-global-hl-line-mode)
  :custom
  (vterm-term-environment-variable "eterm-color")
  :config
  (remove-hook 'vterm-mode-hook 'vterm))

;; (use-package multi-vterm
;;   :commands
;;   multi-vterm
;;   multi-vterm-next
;;   multi-vterm-prev
;;   multi-vterm-dedicated-toggle
;;   multi-vterm-project)
;; (leader-def "pt" 'multi-vterm-dedicated-toggle)
