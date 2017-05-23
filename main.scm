(use srfi-1)
(use srfi-27)                           ; for 乱数
(use util.list)
(use util.match)                        ; like destructuring-bind

(define (good-effect-message?)
  (print "もし提案した手法が効果があると感じた場合は g を入力してください")
  (eq? (read) 'g))

(define (read-file fname)
  (with-input-from-file fname (lambda [] (read))))

(define (save-file fname data)
  (with-output-to-file fname (lambda [] (write data))
                       :if-exists :supersede))

(define (a-process database keys-len)
  (print "調子はどうですか？(good, bad or exit. 他は bad として認識されます)")
  (let ([command (read)])
    (cond [(eq? command 'good)
           (a-process database keys-len)]
          [(eq? command 'exit)
           (print "終了します")]
          [else
           (let* ([target-id    (random-integer keys-len)] ; 貢献度に依存させたい
                  [entry        (assoc target-id database)])
             (match-let1 (id message contribution) entry
               (print message)
               (if (good-effect-message?)
                   (let ([new-database (alist-cons id (list message (+ 1 contribution)) database)])
                     (save-file "./database.scm" new-database)
                     (a-process database keys-len))
                   (a-process database keys-len))))])))

(define main
  (lambda args
    (let* ([database (read-file "./database.scm")]
           [keys (delete-duplicates (map (lambda [lst] (car lst)) database))]
           [keys-len (length keys)])
      (a-process database keys-len))))
