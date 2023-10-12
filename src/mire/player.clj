(ns mire.player)

(def ^:dynamic *current-room*)
(def ^:dynamic *inventory*)
(def ^:dynamic *name*)

(defn calc-attack
  [lvl]
  (* lvl 6))
(defn calc-defence
  [lvl]
  (int (* lvl 1.4)))

(defn calc-hitpoints
  [lvl]
  (* lvl 20))
(defn calc-sides
  [lvl]
  (if (> lvl 5) 4 6))
(defn kill-negative
  [n]
  (if (neg? n) 0 n))
(defn calc-base-damage
  [att def]
  (kill-negative (- att def)))
(defn roll-dice
  [sides]
  (inc (rand-int sides)))

(defn create-character
  [name lvl]
  {
   :name name
   :lvl lvl
   :att (calc-attack lvl)
   :def (calc-defence lvl)
   :hp (calc-hitpoints lvl)
   })


(defn real-damage
  [base sides]
  (let [rd (roll-dice sides)
        s (/ sides 2)]
    (cond
      (<= rd s) (int (/ base 2))
      (> rd s) base
      (= rd sides) (* base 2))))

(defn take-damage
  [from to]
  (let [bd (calc-base-damage (:att from) (:def to))
        s (calc-sides (:lvl from))
        rd (real-damage bd s)]
    [rd (update-in to [:hp] #(- % rd))]))



(def player (create-character "you" 6))
(def troll (create-character "troll" 4))



(def log-template
  " %s received %d damage.
  his new life is %d")

(defn print-battle-log
  [damage character]
  (let [name (:name character)
        newhp (:hp character)
        s (format log-template name damage newhp)]
    (println s)))

(defn print-winner
  [p-hp e-hp]
  (if (<= p-hp 0)
    (println "Enemy won...")
    (println "You won!!!")))

(defn game-logic
  [config]
  (loop [player (:player config)
         enemy (:enemy config)
         round 1]
    (if (or (<= (:hp player) 0)
            (<= (:hp enemy) 0))
      (print-winner (:hp player) (:hp enemy))
      (let [pl->en (take-damage player enemy)
            en->pl (take-damage enemy player)]
        (do (println (str "Round " round ":"))
            (print-battle-log (pl->en 0) (pl->en 1))
            (print-battle-log (en->pl 0) (en->pl 1))
            (recur (en->pl 1) (pl->en 1) (inc round)))))))
(def prompt "> ")
(def streams (ref {}))

(defn carrying? [thing]
  (some #{(keyword thing)} @*inventory*))

