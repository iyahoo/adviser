(use srfi-1)
(use srfi-27)                           ; for 乱数
(use util.list)
(use util.match)                        ; like destructuring-bind

(define *database-file-path* "./database.scm")
(define *tmp-database-file-path* "./tmp-database.scm")

(define (good-effect-message?)
  (print "もし提案した手法が効果があると感じた場合は g を入力してください")
  (eq? (read) 'g))

(define (read-file fname)
  (with-input-from-file fname (lambda [] (read))))

(define (save-file fname data)
  (with-output-to-file fname (lambda [] (write data))
                       :if-exists :supersede))

(define (delete-duplicate-assoc-keys alist)
  (delete-duplicates alist (lambda (a b) (equal? (car a) (car b)))))

(define (id-of-num-minused-by-list-until-0 num lst)
  (let loop ([num num] [lst lst] [idx 0])
      (let ([judge-value (- num (car lst))])
	(if (or (< judge-value 0) (null? lst))
	    idx
	    (loop judge-value (cdr lst) (+ idx 1))))))

(define (select-message-id keys-len database)
  (let* ([u-database (delete-duplicate-assoc-keys database)]
         [contributions (map (lambda (entry) (list-ref entry 2)) u-database)]
         [roulette-num (random-integer (reduce + 0 contributions))])
    (id-of-num-minused-by-list-until-0 roulette-num contributions)))

(define (a-process database keys-len)
  (print "調子はどうですか？(good, bad or exit. 他は bad として認識されます)")
  (let ([command (read)])
    (cond [(eq? command 'good)
           (a-process database keys-len)]
          [(eq? command 'exit)
           (save-file *database-file-path* (delete-duplicate-assoc-keys database))
           (print "終了します")]
          [else
           (let* ([target-id (select-message-id keys-len database)]
                  [entry     (assoc target-id database)])
             (match-let1 (id message contribution) entry
               (print message)
               (if (good-effect-message?)
                   (let ([new-database (alist-cons id (list message (+ 1 contribution)) database)])
                     (a-process new-database keys-len))
                   (a-process database keys-len))))])))

(define main
  (lambda [args]
    (let* ([database (read-file *database-file-path*)]
           [keys (delete-duplicates (map (lambda [lst] (car lst)) database))]
           [keys-len (length keys)])
      (a-process database keys-len))))
