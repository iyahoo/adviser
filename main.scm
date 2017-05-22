(use srfi-27)                           ; for 乱数
(use util.list)

(define (nth n lst)
  (if (zero? n)
      (car lst)
      (nth (- n 1) (cdr lst))))

(define (good-effect-message?)
  (print "もし提案した手法が効果があると感じた場合は \"g\" を入力してください")
  (string=? (read) "g"))

(define (main)
  (let ((database (load "./database.scm")))
    (print "続けますか？(\"exit\" or \"other\")")
    (if (not (string=? (read) "exit"))
        (let ((num (random-integer (length databes))) ; 貢献度に依存させたい
              (message (car (nth num database)))
              (contribution (car (cdr (nth num database)))))
          (print message)
          (if (good-effect-message?)
              (let (new-database (update-nth-assoc database num (+ 1 contribution)))
                (save-file new-database "./database.scm")
                (main))
              (main))))))

;; Issues 実行不可 (good-effect-message?) (update-nth-assoc) (save-file)  同じ質問くる 

