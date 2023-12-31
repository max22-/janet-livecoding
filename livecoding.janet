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

# Synchronization ######################################################

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

# Loop management ###############################################

(def loop-manager-chan (ev/thread-chan 10))

(defn loop-manager
  []
  (def loops @{})
  (forever
   (let [[cmd loop-name arg] (ev/take loop-manager-chan)]
     (printf "loop-manager received cmd=%v, loop-name=%v, arg=%v" cmd loop-name arg)
     (case cmd
       :register (let [prev-channel (get-in loops [loop-name :channel])]
		   (when (not (nil? prev-channel))
		     (ev/give prev-channel :stop))
		     (put loops loop-name arg))
       :show (pp loops)
       :stop (let [loop-channel (get-in loops [loop-name :channel])]
	       (when (not (nil? loop-channel))
		 (ev/give loop-channel :stop)
		 (put loops loop-name nil)))))))
       
(ev/thread (fiber/new loop-manager :t) nil :n)

(defn stop
  [loop-name]
  (ev/give loop-manager-chan [:stop loop-name]))

(defn show-loops
  []
  (ev/give loop-manager-chan [:show]))

(defn register-loop
  [name data]
  (ev/give loop-manager-chan [:register name data]))

# Loop creation macro ###################################################

(defmacro def-loop
  "Create a new live loop"
  [name body]
  ~(ev/spawn-thread
    (let [control-chan (ev/thread-chan 10)]
      (register-loop ,name {:channel control-chan})
      (forever
       ,body
       (when (> ( ev/count control-chan) 0)
	 (let [msg (ev/take control-chan)]
	   (when (= msg :stop)
	     (printf "Stopping loop %v" ,name)
	     (break))))))))

# Launch a netrepl instance #############################################

(import spork/netrepl :as netrepl)
(netrepl/server "127.0.0.1" 9365 (curenv))



