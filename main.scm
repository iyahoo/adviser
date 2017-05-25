(use srfi-1)
(use srfi-13)                           ; 文字列
(use srfi-27)                           ; for 乱数
(use util.match)                        ; like destructuring-bind
(use gauche.process)                    ; System call

(define *database-file-path* "./database.scm")
(define *tmp-database-file-path* "./tmp-database.scm")
(define *sys-path* "/usr/local/bin/")

(define (read-file fname)
  (with-input-from-file fname (lambda [] (read))))

(define (save-file fname data)
  (with-output-to-file fname (lambda [] (write data))
                       :if-exists :supersede))

(define (delete-duplicate-assoc-keys alist)
  (delete-duplicates alist (lambda (a b) (equal? (car a) (car b)))))

(define (id-of-num-minused-by-list-until-0 num lst keys)
  (let loop ([num num] [lst lst] [keys keys])
    (if (null? lst)
        (car keys)
        (let ([judge-value (- num (car lst))])
          (if (< judge-value 0)
              (car keys)
              (loop judge-value (cdr lst) (cdr keys)))))))

(define (select-advice-id database)
  (let* ([u-database    (delete-duplicate-assoc-keys database)]
         [contributions (map (lambda (entry) (list-ref entry 2)) u-database)]
         [roulette-num  (random-integer (reduce + 0 contributions))]
         [keys          (map (lambda (entry) (car entry)) u-database)])
    (id-of-num-minused-by-list-until-0 roulette-num contributions keys)))

(define (a-minute-sleep)
  (sys-sleep 60))

(define (time-manage current-time interval)
  (a-minute-sleep)
  (if (= 0 (remainder current-time interval))
      (display current-time)
      (display "."))
  (flush))

(define (check-os)
  (call-with-input-process "uname"
    (lambda (p) (make-keyword (read-line p)))))

(define (notify)
  (call-with-input-process
   (string-concatenate (list *sys-path*
                             "terminal-notifier -message \"Finish working time\""
                             " -closeLabel Close"))
   (lambda (p) #t)
   :on-abnormal-exit :ignore))

(define (show-advices database)
  (string-concatenate
   (map
    (match-lambda ([id advice contribution]
                   (string-concatenate (list (number->string id) ": " advice "\n")))
                  (else
                   ""))
    (delete-duplicate-assoc-keys database))))

(define (good-effect-advice?)
  (eq? (read) 'g))

(define (print-evaluate-advice target-id database)
  (let ([entry (assoc target-id database)])
    (match-let1 (id advice contribution) entry
      (print advice)
      (print "もし提案した手法が効果があると感じた場合は g を入力してください。")
      (if (good-effect-advice?)
          (let ([new-database
                 (alist-cons id (list advice (+ 1 contribution)) database)])
            (a-process new-database))
          (a-process database)))))

(define (a-process database)
  (print "\n調子はどうですか？(good, bad or exit. 他は bad として認識されます)")
  (let ([command (read)])
    (match command
      ['good
       (print "今の作業を何分やりますか？正の整数を入力して下さい")
       (let ([work-time (read)])
         (let sleep-loop ([current-time 1] [work-time work-time])
           (unless (> 0 (- work-time current-time))
             (time-manage current-time 5)
             (sleep-loop (+ 1 current-time) work-time)))
         (match (check-os)
           [':Darwin (notify)])
         (a-process database))]
      ['exit
       (save-file *database-file-path* (delete-duplicate-assoc-keys database))
       (print "終了します")]
      [else
       (let advice-loop []
         (print "何かアドバイスをしましょうか？それとも一覧を見ますか？")
         (print "(t:アドバイスをランダムに選択 all:一覧を見る others:戻る)")
         (match (read)
           ['t
            (let ([target-id (select-advice-id database)])
              (print-evaluate-advice target-id database))]
           ['all
            (print (show-advices database))
            (print "試してみるアドバイスを入力してください")
            (let ([input-id (read)])
              (print-evaluate-advice input-id database))]
           [else
            (a-process database)]))])))

(define (main :optional (args '()))
  (let* ([database (read-file *database-file-path*)])
    (a-process database)))
