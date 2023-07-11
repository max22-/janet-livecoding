A small [Live coding](https://en.wikipedia.org/wiki/Live_coding) environment, to make music with the [Janet](https://janet-lang.org/) language.

Work in progress.

# Dependencies
* RtMidi
* A Janet binding to rtmidi (made by me) :

```shell
sudo jpm install https://github.com/max22-/janet-rtmidi
```

* spork/netrepl

```
sudo jpm install spork
```

# How to use it

```shell
janet livecoding.janet
```

See the example code in playground.janet (send it using a netrepl client, for example [Conjure](https://github.com/Olical/conjure).
Personnally, i have put this in my .emacs config file :

```elisp
(defun janet-netrepl ()
  (interactive)
  (comint-run "janet" '("-s" "-e" "(import spork/netrepl :as netrepl) (netrepl/client)")))

(defun janet-netrepl-send ()
  (interactive)
  (let ((expr (buffer-substring-no-properties  
                     (save-excursion (backward-sexp) (point))
                     (point))))
      (with-current-buffer "*janet*"
          (insert expr)
          (comint-send-input)
	  (comint-send-string "*janet*" "\r\n"))))
	  
(global-set-key [f9] 'janet-netrepl-send)
```