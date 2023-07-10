(import :rtmidi :as rtmidi)

(def port (rtmidi/open-virtual-output-port "janet"))

(def rng (math/rng (os/time)))
(defn rand-int [x] (math/rng-int rng x))

(defn choose
  [l]
  (l (rand-int (length l))))

(def major
  '(0 2 4 5 7 9 11))

(defn play
  [note dur &opt velocity channel]
  (default velocity 127)
  (default channel 0)
  (rtmidi/note-on port channel note velocity)
  (ev/sleep dur)
  (rtmidi/note-off port channel note velocity))

(def sync-channel (ev/thread-chan 10))

(defn synchronizer
  []
  (def subs @{})
  (forever
   (def [cmd arg1 arg2] (ev/take sync-channel))
   (case cmd
     :sub (put subs arg1 arg2)
     :cue (each [_ c] subs
	    (ev/give c [:cue arg1])))))

(ev/thread (fiber/new synchronizer :t) nil :n)

(def loop-manager-chan (ev/thread-chan 10))

(defn loop-manager
  []
  (def loops @{})
  (forever
   (let [[cmd arg] (ev/take loop-manager-chan)]
     (print "loop-manager received something")
     (print (string "cmd=" cmd ", arg=" arg))
     (case cmd
       :register (put loops (get arg :name) (get arg :data))
       :show (pp loops)
       :stop (let [loop-data (get loops arg)]
	       (when (not (nil? loop-data))
		 (ev/give (get loop-data :channel) :stop)
		 (put loops arg nil)))))))
       
(ev/thread (fiber/new loop-manager :t) nil :n)

(defn show-loops
  []
  (ev/give loop-manager-chan [:show]))

(defn register-loop
  [data]
  (ev/give loop-manager-chan [:register data]))

(defn loop1
  []
  (let [ loop-name :loop1
	  control-chan (ev/thread-chan 10)]
    (register-loop {:name loop-name :data {:channel control-chan}})
    (forever
     (print "loop")
     (repeat 10
	     (play (+ 69 (choose major)) 1)
	     (ev/sleep 1))
     (when (> (ev/count control-chan) 0)
       (let [msg (ev/take control-chan)]
	 (when (= msg :stop)
	   (print (string "Stopping loop " loop-name))
	   (break)))))))

(ev/thread (fiber/new loop1 :t) nil :n)
(ev/give loop-manager-chan [:stop :loop1])

(show-loops)
