(use srfi-1)
(use srfi-27)                           ; for 乱数
(use util.list)

(define (nth n lst)
  (if (zero? n)
      (car lst)
      (nth (- n 1) (cdr lst))))

(define (good-effect-message?)
  (print "もし提案した手法が効果があると感じた場合は g を入力してください")
  (eq? (read) 'g))

(define (read-file fname)
  (with-input-from-file fname (lambda [] (read))))

(define (main args)
  (let* ([database (read-file "./database.scm")]
         [dlen     (length database)])
    (let loop []
      (print "続けますか？(exit or other)")
      (if (not (eq? (read) 'exit))
          (let* ([num (random-integer dlen)] ; 貢献度に依存させたい
                 [entry (list-ref database num)]
                 [message (car entry)]
                 [contribution (cdr entry)])
            (print message)
            (if (good-effect-message?)
                (let ((new-database (update-nth-assoc database num (+ 1 contribution))))
                  (save-file new-database "./database.scm")
                  (loop))
                (loop)))))))

;; Issues 実行不可 (update-nth-assoc) (save-file)  同じ質問くる
