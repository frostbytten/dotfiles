;; init.el -- Welcome to the jungle
;;; Commentary:
;;; Code:

;; Custom file
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file t)

;; Setup the packages
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; basic package management
(setq package-selected-packages '(corfu eglot org org-contrib vterm))
(global-set-key (kbd "C-c p i") #'package-install-selected-packages)
(global-set-key (kbd "C-c p x") #'package-autoremove)
(global-set-key (kbd "C-c p r") #'package-refresh-contents)
(global-set-key (kbd "C-c p l") #'package-list-packages)

;; Clean UI
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-screen t)
(fido-vertical-mode 1)
(add-to-list 'default-frame-alist
	     '(font . "JetBrainsMono Nerd Font Mono-11"))

;; Corfu
(global-corfu-mode)
(setq corfu-auto t
      corfu-cycle t)

;; Clean files
(setq make-backup-files nil)

;; Shelly
(global-set-key (kbd "C-c t e") #'eshell)
(global-set-key (kbd "C-c t v") #'vterm)
(global-set-key (kbd "C-c t o") #'vshell-other-window)


;; Programming stuff
(require 'project)
(defun cv-gradle-project-override (dir)
  (let ((root (locate-dominating-file dir "build.gradle")))
    (if root
	(cons 'vc root)
      nil)))

(add-to-list 'project-find-functions #'cv-gradle-project-override)

(require 'eglot)
(add-to-list 'eglot-server-programs '(java-mode "jdtls" "-configuration" "~/.cache/jdtls" "-data" "~/.local/share/jdtls/workspaces"))
(add-hook 'java-mode-hook #'eglot-ensure)

;; Org mode stuff
(global-set-key (kbd "C-c l") #'org-store-link)
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'org-capture)

(provide 'init)
;;; init.el ends here


