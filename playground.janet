(def-loop :loop1
   (repeat 10
	   (play (+ 69 (choose major)) 1)
	   (ev/sleep 1)))

(stop :loop1)
(show-loops)
