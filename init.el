;;;; STARTUP

;; Minimize garbage collection during startup
;; The default is 800 kilobytes. Measured in bytes
(setq gc-cons-threshold (* 50 1000 1000))

(defun td/display-startup-time ()
  (if (daemonp)
    (message "Emacs loaded in the daemon in %s with %d garbage collections."
         (format "%.2f seconds"
                 (float-time
                  (time-subtract after-init-time before-init-time)))
         gcs-done)
    (message "Emacs loaded in %s with %d garbage collections."
         (format "%.2f seconds"
                 (float-time
                  (time-subtract after-init-time before-init-time)))
         gcs-done)))

(add-hook 'emacs-startup-hook #'td/display-startup-time)

;;;; INITIALIZE PACKAGE SOURCES
(require 'package)

;;; PACKAGE LIST
(setq package-archives '(("melpa"  . "https://melpa.org/packages/")
                         ("elpa"   . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

;;; BOOTSTRAP USE-PACKAGE
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

;;;; AUTO UPDATES
;; Run auto-upates on packages 1/week
(use-package auto-package-update
  :custom
  (auto-package-update-interval 7)
  (auto-package-update-prompt-before-update t)
  :config
  (auto-package-update-maybe)
  (auto-package-update-at-time "09:00"))

;;;; SERVER SETUP
(use-package server
  :ensure nil
  :defer 1
  :config
  (unless (server-running-p)
    (server-start)))

;; Check user on login
(defvar td/my-system
  (if (string-equal user-login-name "td")
      t
    nil)
  "Non-nil value if it's my system.")

;; Use this to properly sync env variables when running Emacs daemon
(use-package exec-path-from-shell
  :ensure t)
(when (daemonp)
  (exec-path-from-shell-initialize))


;;;; CLEAN UP FOLDERS
(setq backup-directory-alist `(("." . ,(expand-file-name "tmp/backups/" user-emacs-directory))))

;; auto-save-mode doesn't create the path automatically!
(make-directory (expand-file-name "tmp/auto-saves/" user-emacs-directory) t)

(setq auto-save-list-file-prefix (expand-file-name "tmp/auto-saves/sessions/" user-emacs-directory)
      auto-save-file-name-transforms `((".*" ,(expand-file-name "tmp/auto-saves/" user-emacs-directory) t)))

;; Keep custom-set-variables and faces out of my main file
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

;;;; BASIC UI CONFIG
(setq inhibit-startup-message t)

(setq initial-scratch-message ";; Don't panic\n\n")

(scroll-bar-mode -1)		; Disable visible scrollbar
(tool-bar-mode -1)		; Disable the toolbar
(tooltip-mode -1)		; Disable tooltips
(set-fringe-mode 15)		; Give some breathing room

(menu-bar-mode -1)	       	; Disable the menu bar

;; Set up the visible bell
(setq ring-bell-function 'ignore)

;; Using spaces instead of tabs for indentation
(setq-default indent-tabs-mode nil)

;; Don't warn for large files
(setq large-file-warning-threshold nil)

;; Don't warn for following symlinks
(setq vc-follow-symlinks t)

;; Set line numbers
(column-number-mode)
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode t)

;; Disable line numbers for some modes
(dolist (mode '(org-mode-hook
                term-mode-hook
                vterm-mode-hook
                shell-mode-hook
                eshell-mode-hook
                dired-mode-hook
                geiser-repl-mode-hook
                sly-mrepl-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;; Scrolling like vim
(setq scroll-margin 10)
(setq scroll-step 1)
(setq use-dialog-box nil)

;; Save place
(save-place-mode 1)
(setq save-place-forget-unreadable-files nil)

;; UTF-8 encoding
(prefer-coding-system 'utf-8)

;; Dont' ask to spell out "yes"
(fset 'yes-or-no-p 'y-or-n-p)

;; Set mouse-pointer to disappear when typing
(setq make-pointer-invisible t)

;; Let the desktop background show through
;; Note: This only works with a compositor such as picom
;; (set-frame-parameter (selected-frame) 'alpha '(97 . 100))
;; (add-to-list 'default-frame-alist '(alpha . (90 . 90)))

;; Only open the buffer if there is output
(setq async-shell-command-display-buffer nil)
;; Uncomment if multiple buffers should be spawned when running several async shell commands at once.
;; (setq async-shell-command-buffer new-buffer)


;;;; FONT
(defun td/set-font-faces ()
  (message "Setting font faces!")
  ;; Set font
  (set-face-attribute 'default nil :font "FantasqueSansM Nerd Font" :height 220)

  ;; Set fixed pitch face
  (set-face-attribute 'fixed-pitch nil :font "FantasqueSansM Nerd Font" :height 220)

  ;; Set the variable pitch face
  (set-face-attribute 'variable-pitch nil :font "FantasqueSansM Nerd Font" :height 220))


;; Fix fonts when running emacsclient (in daemon)
(if (daemonp)
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (setq doom-modeline-icon t)
                (with-selected-frame frame
                  (td/set-font-faces))))
  (td/set-font-faces))


(use-package ligature
  :config
  ;; Enable all ligatures in all modes
  (ligature-set-ligatures 't '("<>" "==" "===" "<=" ">=" "->" "<-" "-->"
                               "==>" "<==" "=>" "||" "&&" "!=" "<->" "~~"
                               "~>" "<~" "<=>" "<<" ">>"))
  ;; Enables ligature checks globally in all buffers. You can also do it
  ;; per mode with `ligature-mode'.
  (global-ligature-mode t))

(add-hook 'emacs-lisp-mode-hook 'prettify-symbols-mode)
(add-hook 'lisp-mode-hook 'prettify-symbols-mode)


;;;; THEME
(use-package spaceway-theme
  :ensure nil
  :load-path "lisp/spaceway/"
  :config
  (when td/my-system
    (add-to-list 'default-frame-alist '(background-color . "black")))
  (load-theme 'spaceway t)
  (setenv "SCHEME" "dark"))

(use-package doom-themes
  :disabled t
  :ensure t
  :config
  (load-theme 'doom-earl-grey t)
  (set-face-attribute 'default nil :foreground "#333")
  (setenv "SCHEME" "light"))

;; Make sure to run (nerd-icons-install-fonts) and (all-the-icons-install-fonts)
;; one time after installing the package

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-height 10))

(use-package all-the-icons)

(use-package beacon
  :ensure t
  :config
  (beacon-mode 1))


;;;; KEYBINDINGS
;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;; general (keybinds)
(use-package general
  :config
  (general-create-definer td/leader-keys
    :keymaps '(normal insert visual emacs)
    :prefix "SPC"
    :global-prefix "C-SPC")

  (td/leader-keys
    "t" '(:ignore t :which-key "toggles")
    "tt" '(counsel-load-theme :which-key "choose themes")))

(general-define-key
 "C-x h" 'previous-buffer
 "C-x l" 'next-buffer)

;; Load evil-mode config
(load (concat user-emacs-directory
              "lisp/evil-config.el"))

(use-package hydra)

(defhydra hydra-text-scale (:timeout 4)
  "scale text"
  ("j" text-scale-increase "in")
  ("k" text-scale-decrease "out")
  ("f" nil "finished" :exit t))

(td/leader-keys
  "ts" '(hydra-text-scale/body :which-key "scale text"))

(use-package which-key
  :defer 0
  :diminish which-key-mode
  :config
  (which-key-mode)
  (setq which-key-idle-delay 0.3))

(use-package ivy
  :diminish
  :bind (("C-s" . swiper)
         :map ivy-minibuffer-map
         ("RET" . ivy-alt-done)
         ("C-l" . ivy-alt-done)
         ("C-j" . ivy-next-line)
         ("C-k" . ivy-previous-line)
         :map ivy-switch-buffer-map
         ("C-k" . ivy-previous-line)
         ("C-l" . ivy-done)
         ("C-d" . ivy-switch-buffer-kill)
         :map ivy-reverse-i-search-map
         ("C-k" . ivy-previous-line)
         ("C-d" . ivy-reverse-i-search-kill))
  :config
  (ivy-mode 1))

(use-package ivy-rich
  :init
  (ivy-rich-mode 1))

;; Make completions `psychic`
(use-package ivy-prescient
  :after counsel
  :config
  (ivy-prescient-mode 1)
  (prescient-persist-mode 1))

;; Retain ivy's default sorting and highlighting
(setq prescient-sort-length-enable nil)
(setq ivy-prescient-retain-classic-highlighting t)

(use-package counsel
  :bind (("M-x" . counsel-M-x)
         ("C-x b" . counsel-ibuffer)
         ("C-x C-f" . counsel-find-file)
         :map minibuffer-local-map
         ("C-r" . 'counsel-minibuffer-history))
  :config
  (setq ivy-initial-inputs-alist nil)) ;; Don't start searches with ^

(use-package helpful
  :ensure t
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))


;;;; COMPLETION
(use-package eglot
  :ensure t :defer t
  :config
  (add-to-list 'eglot-server-programs '(c-mode      . ("clangd")))
  (add-to-list 'eglot-server-programs '(c++-mode    . ("clangd")))
  (add-to-list 'eglot-server-programs '(rust-mode   . ("rust-analyzer")))
  (add-to-list 'eglot-server-programs '(python-mode . ("pyls")))
  (add-to-list 'eglot-server-programs '(go-mode     . ("gopls")))
  :hook
  ((python-mode   . eglot-ensure)
   (rust-mode     . eglot-ensure)
   (go-mode       . eglot-ensure)
   (c-mode        . eglot-ensure)
   (c++-mode      . eglot-ensure)))

(use-package orderless
  :commands (orderless)
  :custom
  (completion-styles '(orderless flex))
  (completion-category-override '((eglot (styles . (orderless-flex))))))

(use-package corfu
  :custom
  (corfu-cycle t)                  ; Allow cycling through candidates
  (corfu-auto t)                   ; Enable auto completion
  (corfu-auto-prefix 2)            ; Enable auto completion
  (corfu-auto-delay 0.0)           ; Enable auto completion
  (corfu-quit-at-boundary 'separator)
  (corfu-echo-documentation 0.25)  ; Enable auto completion
  (corfu-preview-current 'insert)  ; Do not preview current candidate
  (corfu-preselect-first nil)
  :bind (:map corfu-map
              ("M-SPC"      . corfu-insert-separator)
              ("C-n"        . corfu-next)
              ([tab]        . corfu-next)
              ("C-p"        . corfu-previous)
              ([backtab]    . corfu-previous)
              ("S-<return>" . corfu-insert)
              ("RET"        . nil)) ; Leave ENTER alone!
  :init
  ;; Use corfu everywhere
  (global-corfu-mode)
  ;; Save completion history for better sorting
  (corfu-history-mode))

(use-package cape
  :defer 10
  :init
  ;; Add 'completion-at-point-functions', used by 'completion-at-point'
  (add-to-list 'completion-at-point-functions #'cape-file)
  ;; Nice completion to have available everywhere
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  :config
  ;; Silence then pcomplete capf, no errors or messages!
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-silent)
  ;; Ensure that pcomplete does not write to the buffer
  ;; and behaves as a pure 'completion-at-point-function'
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-purify))

;; Programming
(use-package sly
  :ensure t
  :commands (sly sly-connect)
  :config
  (setq inferior-lisp-program "/usr/bin/sbcl"))

(use-package geiser
  :ensure t
  :config
  (setq geiser-guile-binary "/usr/bin/guile"
        geiser-active-implementations '(guile)
        geiser-default-implementations '(guile))
  (use-package geiser-guile))

(use-package paren-face
  :ensure t
  :hook ((prog-mode eshell-mode
                    inferior-lisp-mode inferior-emacs-lisp-mode
                    lisp-interaction-mode sly-mrepl-mode scheme-mode)
         . paren-face-mode))

(use-package python-mode
  :ensure t :defer t :mode "\\.py\\'")

(use-package rust-mode
  :ensure t :defer t :mode "\\.rs\\'")

(setenv "GOPATH" "/home/td/.go/")
(use-package go-mode
  :ensure t :defer t :mode "\\.go\\'")

(use-package yaml-mode
  :ensure t :mode "\\.ya?ml\\'")

(add-hook 'sh-mode-hook
  (lambda () (setq sh-basic-offset 2)))


;;;; WRITING
(use-package writegood-mode
  :hook (jinx-mode . writegood-mode))

(use-package jinx
  :ensure t
  :hook ((org-mode  . jinx-mode)
         (text-mode . jinx-mode))
  :bind (("M-$"     . jinx-correct)
         ("C-M-$"   . jinx-languages)))

;; Load in org config
(load (concat user-emacs-directory
              "lisp/org-config.el"))


;;;; GIT & PROJECTS
(use-package magit
  :commands magit-status)

(use-package projectile
  :diminish projectile-mode
  :config (projectile-mode)
  :custom ((projectile-completion-system 'ivy))
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :init
  (when (file-directory-p "~/projects")
    (setq projectile-project-search-path '("~/projects")))
  (setq projectile-switch-project-action #'projectile-dired))

(use-package counsel-projectile
  :after projectile
  :config (counsel-projectile-mode))


;;;; TERMINALS
(use-package term
  :commands term
  :config
  (setq explicit-shell-file-name "zsh"))

(use-package vterm
  :commands vterm
  :config
  (setq vterm-max-scrollback 10000))

(defun td/eshell-prompt ()
  (concat
   "\n"
   (propertize (abbreviate-file-name (eshell/pwd)) 'face `(:foreground "cyan"))
   (if (zerop (user-uid))
       (propertize " # " 'face `(:foreground "red"))
     (propertize " λ " 'face `(:foreground "yellow")))))

(defun td/configure-eshell ()
  (require 'evil-collection-eshell)
  (evil-collection-eshell-setup)

  (require 'xterm-color)

  (push 'xterm-color-filter eshell-preoutput-filter-functions)
  (delq 'eshell-handle-ansi-color eshell-output-filter-functions)

  (add-hook 'eshell-before-prompt-hook
            (lambda ()
              (setq xterm-color-preserve-properties t)))

  ;;Use xterm-256color when running interactive commands
  (add-hook 'eshell-pre-command-hook
            (lambda () (setenv "TERM" "xterm-256color")))
  (add-hook 'eshell-post-command-hook
            (lambda () (setenv "TERM" "dumb")))

  ;; Save command history when commands are entered
  (add-hook 'eshell-pre-command-hook 'eshell-save-some-history)

  ;; Truncate buffer for performance
  (add-to-list 'eshell-output-filter-functions 'eshell-truncate-buffer)

  ;; Bind some useful keys for evil-mode
  (evil-define-key '(normal insert visual) eshell-mode-map (kbd "C-r") 'counsel-esh-history)

  (evil-normalize-keymaps)

  (setq eshell-prompt-function      'td/eshell-prompt
        eshell-prompt-regexp        "^[^λ]+ λ "
        eshell-history-size         10000
        eshell-buffer-maximum-lines 10000
        eshell-hist-ignoredups      t
        eshell-highlight-prompt     t
        eshell-scroll-to-bottom-on-input t))

(use-package eshell-git-prompt
  :after eshell)

(use-package eshell
  :hook (eshell-first-time-mode . td/configure-eshell))

(use-package eshell-syntax-highlighting
  :after eshell
  :ensure t
  :config (eshell-syntax-highlighting-global-mode +1))

(use-package eshell-toggle
  :custom
  (eshell-toggle-size-fraction 3)
  (eshell-toggle-run-command nil)
  :bind
  ("C-`" . eshell-toggle))


;;;; FILE MANAGEMENT
(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "h" 'dired-single-up-directory
    "l" 'dired-single-buffer)
  (setq dired-listing-switches "-aghoA --group-directories-first"))

(use-package dired-single
  :commands (dired dired-jump))

(use-package all-the-icons-dired
  :hook (dired-mode . all-the-icons-dired-mode))

(use-package dired-hide-dotfiles
  :hook (dired-mode . dired-hide-dotfiles-mode)
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "H" 'dired-hide-dotfiles-mode))


;;;; ETC

;; Local Web-hosting
(use-package simple-httpd
  :ensure t)


;; Make gc pauses faster by decreasing the threshold
(setq gc-cons-threshold (* 2 1000 1000))
