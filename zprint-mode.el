;;; zprint-mode.el --- reformat Clojure(Script) code using zprint

;; Author: Paulus Esterhazy (pesterhazy@gmail.com)
;; URL: https://github.com/pesterhazy/zprint-mode.el
;; Version: 0.1
;; Keywords: tools
;; Package-Requires: ((emacs "24.3"))

;; This file is NOT part of GNU Emacs.

;; zprint-mode.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; zprint-mode.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with zprint-mode.el.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Reformat Clojure(Script) code using zprint

;;; Code:

(defun zprint (&optional is-interactive)
  "Reformat code using zprint.
If region is active, reformat it; otherwise reformat entire buffer.
When called interactively, or with prefix argument IS-INTERACTIVE,
show a buffer if the formatting fails"
  (interactive)
  (let* ((b (if mark-active (min (point) (mark)) (point-min)))
         (e (if mark-active (max (point) (mark)) (point-max)))
         (in-file (make-temp-file "zprint"))
         (err-file (make-temp-file "zprint"))
         (out-file (make-temp-file "zprint"))
         (contents (buffer-substring-no-properties b e))
         (_ (with-temp-file in-file (insert contents))))

    (unwind-protect
        (let* ((error-buffer (get-buffer-create "*zprint-mode errors*"))
               (retcode
                (with-temp-buffer
                  (call-process "bash"
                                nil
                                (list (current-buffer) err-file)
                                nil
                                "-c"
                                ;; Autogenerated; see ./build
                                ;; ::START::
                                "set -euo pipefail;our_temp_dir=$(mktemp -d 2>/dev/null||mktemp -d -t \"our_temp_dir\");function cleanup_temp_dir(){ rm -rf \"$our_temp_dir\";}&&trap \"cleanup_temp_dir\" EXIT;if [[ \"$(uname -s)\" == Darwin ]];then os=macos;else os=linux;fi;if [[ \"$os\" == macos ]];then url=\"https://github.com/kkinnear/zprint/releases/download/0.4.11/zprintm-0.4.11\";expected_sha=\"dfe2eb7446253c23d91487cf962e9e6ecbbe747f7915caa815ddadcba76b8a93\";else url=\"https://github.com/kkinnear/zprint/releases/download/0.4.11/zprintl-0.4.11\";expected_sha=\"9436749ea77c2623b177e85add41c996a873e96bd270927a42a016c531e68a54\";fi;dir=\"$HOME/.zprint-cache\";if ! [[ -f \"$dir/${expected_sha}\" ]];then mkdir -p \"$dir\";curl -SL -o \"$our_temp_dir/zprint\" \"$url\";actual_sha=\"$(python -c \"import sys,hashlib; m=hashlib.sha256(); f=open(sys.argv[1]) if len(sys.argv)>1 else sys.stdin; m.update(f.read()); print(m.hexdigest())\" \"$our_temp_dir/zprint\")\";if [[ \"$actual_sha\" != \"$expected_sha\" ]];then printf \"Sha mismatch. Expected=%s Actual=%s\\n\" \"$expected_sha\" \"$actual_sha\";exit 1;fi;chmod +x \"$our_temp_dir/zprint\";mv \"$our_temp_dir/zprint\" \"$dir/${expected_sha}\";cleanup_temp_dir;fi;inf=\"${1-}\";outf=\"${2-}\";if [[ \"$inf\" != \"\" ]];then result=$(\"$dir/${expected_sha}\"<\"$1\";echo x);else result=$(\"$dir/${expected_sha}\";echo x);fi;if [[ \"$result\" =~ ^Failed.* ]];then printf \"%s\\n\" \"${result%?}\">&2;exit 1;fi;if [[ \"$outf\" != \"\" ]];then printf \"%s\" \"${result%?}\">\"$outf\";else printf \"%s\" \"${result%?}\";fi"
                                ;; ::END::
                                "--"
                                in-file
                                out-file))))
          (with-current-buffer error-buffer
            (read-only-mode 0)
            (insert-file-contents err-file nil nil nil t)
            (special-mode))
          (if (eq retcode 0)
              (progn
                (if mark-active
                    (progn
                      ;; surely this can be done more elegantly?
                      (when (not (string= (with-temp-buffer
                                            (insert-file-contents out-file)
                                            (buffer-string))
                                          (buffer-substring-no-properties b e)))
                        (delete-region b e)
                        (insert-file-contents out-file nil nil nil nil)))
                  (insert-file-contents out-file nil nil nil t))
                (message "zprint applied"))
            (if is-interactive
                (display-buffer error-buffer)
              (message "zprint failed: see %s" (buffer-name error-buffer)))))
      (delete-file in-file)
      (delete-file err-file)
      (delete-file out-file))))

;;;###autoload
(define-minor-mode zprint-mode
  "Minor mode for reformatting Clojure(Script) code using zprint"
  :lighter " zprint"
  (if zprint-mode
      (add-hook 'after-save-hook 'zprint nil t)
    (remove-hook 'after-save-hook 'zprint t)))

(provide 'zprint-mode)

;;; zprint-mode.el ends here
