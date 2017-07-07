(use srfi-1)
(use srfi-13)                           ; 文字列
(use srfi-19)                           ; date
(use srfi-27)                           ; 乱数
(use util.match)                        ; like destructuring-bind
(use gauche.process)                    ; System call
(use file.util)

(define *database-seed-path* "./seed.sxp")
(define *database-file-path* "./database.sxp")
(define *log-seed-path* "./log-seed.sxp")
(define *log-file-path* "./log.sxp")
(define *notify-script-path* "./notify.sh")
(define *reading-script-path*  "./reading.sh")

;; for debug
(define *debugging* #f)

(define (read-file fname)
  (with-input-from-file fname (lambda [] (read))))

(define (save-file fname data)
  (with-output-to-file fname (lambda [] (write data))
                       :if-exists :supersede))

(define (load-seed-or-user-file seed-file user-file)
  (let* ([file (if (file-is-writable? user-file)
                   user-file
                   seed-file)]
         [contents (read-file file)])
    contents))

(define (load-log)
  (let* ([today-tag (current-date-keyword)]
         [logs (load-seed-or-user-file *log-seed-path* *log-file-path*)])
    (if (null? logs)
        (set-log-entry logs today-tag (make-log-entry today-tag 0))
        logs)))

(define (load-database)
  (load-seed-or-user-file *database-seed-path* *database-file-path*))

;; Log Entry Accecsor
;; Log entry: (:yyyy-mm-dd ((:workedtime total-worked-time)))

(define (current-date-keyword)
  (let ([now (current-date)])
    (make-keyword
     (format #f "~A-~2,,,'0@A-~2,,,'0@A" (date-year now) (date-month now) (date-day now)))))

;; ((:workedtime 5) (:otherinfor hoge)) のように拡張することを想定して以下のように
(define (make-log-entry date worked-time)
  `(,date ((:workedtime ,worked-time))))

(define (log-entry-date entry)
  (first entry))

(define (log-entry-information entry)
  (second entry))

(define (log-entry-worked-time infor)
  ;; infor -> Integer (workedtime)
  (second (assoc :workedtime infor)))

;; Log Accessors (non-destructive)

(define (get-log-entry log date)
  (assoc date log))

(define (set-log-entry log date entry)
  ;; log -> date -> entry -> log
  (alist-cons date (cdr entry) (alist-delete date log)))

(define (update-log-entry log date f)
  ;; log -> date -> (infor -> infor) -> log
  (let* ([entry (get-log-entry log date)]
         [date  (log-entry-date entry)]
         [infor (log-entry-information entry)])
    (set-log-entry log date (list date (f infor)))))

(define (adding-worked-time infor add-time)
  (alist-cons :workedtime
              (list (+ (log-entry-worked-time infor) add-time))
              (alist-delete :workedtime infor)))

;; Entry Accessors
;; entry: (id advice contribution)

(define (make-entry id advice contribution)
  (list id advice contribution))

(define (entry-id entry)
  (first entry))

(define (entry-advice entry)
  (second entry))

(define (entry-contribution entry)
  (third entry))


;; Database Accessors (non-destructive)

(define (get-entry db id)
  (assoc id db))

(define (set-entry db id entry)
  ;; database -> id -> entry -> database
  (alist-cons id (cdr entry) (alist-delete id db)))

(define (db-ids db)
  (map entry-id db))

(define (db-contributions db)
  (map entry-contribution db))

(define (update-entry db id f)
  ;; database -> id -> (advice -> contribution -> entry) -> database
  ;; fにidとentryそのものを渡さないのは、
  ;; - idはこの関数を呼び出した場所でわかるはず
  ;; - entryはそのidとdbから引けるはず
  ;; という理由
  (let* ([entry (get-entry db id)]
         [advice (entry-advice entry)]
         [contrib (entry-contribution entry)])
    (set-entry db id (f advice contrib))))


;; Entry Operators

(define (increment-contribution db id)
  ;; database -> entry-id -> database
  (update-entry db id (lambda [advice contrib] (make-entry id advice (+ contrib 1)))))


;; Entry selection routine

(define (id-of-num-minused-by-list-until-0 num lst keys)
  (let loop ([num num] [lst lst] [keys keys])
    (if (null? lst)
        (car keys)
        (let ([judge-value (- num (car lst))])
          (if (< judge-value 0)
              (car keys)
              (loop judge-value (cdr lst) (cdr keys)))))))

(define (select-advice-id db)
  (let* ([contributions (db-contributions db)]
         [roulette-num  (random-integer (reduce + 0 contributions))]
         [keys          (db-ids db)])
    (id-of-num-minused-by-list-until-0 roulette-num contributions keys)))


;; Print-Eval-Advice-Loop

;; Sleep, Display and Reading
(define (a-minute-sleep)
  (sys-sleep 60))

(define (a-second-sleep) ; for debugging
  (sys-sleep 1))

(define (display-elapsed current-time interval)
  (if (= 0 (remainder current-time interval))
      (display current-time)
      (display "."))
  (flush))

(define (sleep-loop sleep-unit-f time interval)
  ;; sleep-unit-f: プロセスをブロックする、スリープ関数
  ;; これにa-second-sleepなどを渡すことで、REPLから動作を確かめられる
  ;; ex: (sleep-loop a-second-sleep 10 3)
  (let loop ([current 1])
    (sleep-unit-f)
    (display-elapsed current interval)
    (when (> time current) (loop (+ 1 current)))))


(define (show-advices db)
  (string-concatenate
   (map
    (match-lambda ([id advice contribution]
                   (string-concatenate (list (number->string id) ": " advice "\n")))
                  (else ""))
    db)))

(define (executable-file-with-str file-path str)
  (when (file-is-executable? file-path)
    (sys-system (format #f "~A ~S" file-path str))))

(define (reading message)
  (executable-file-with-str *reading-script-path* message))

(define (print-evaluate-advice target-id db)
  (let ([entry (get-entry db target-id)])
    (print-and-reading (entry-advice entry))
    (print "もし提案した手法が効果があると感じた場合は g を入力してください。")
    (if (good-effect-advice?)
        (process (increment-contribution db target-id) log)
        (process db log))))

(define (print-and-reading message)
  (print message)
  (reading message))

(define (good-effect-advice?)
  (eq? (read) 'g))

(define (check-os)
  (call-with-input-process "uname"
    (lambda (p) (make-keyword (read-line p)))))

(define (notify message)
  (executable-file-with-str *notify-script-path* message))

(define (process db log)
  (print-and-reading "調子はどうですか？")
  (print "(good: 作業を継続 rest: 休憩 bad:アドバイス exit:終了 それ以外:bad として認識)")
  (let ([command (read)])
    (match command
      ['good (good-process db log)]
      ['rest (rest-process db log)]
      ['exit (exit-process db log)]
      [else  (else-process db log)])))

(define (good-process db log)
  (print-and-reading "今の作業を何分やりますか？")
  (let ([work-time (read)])
    (if *debugging*
        (sleep-loop a-second-sleep work-time 5)
        (sleep-loop a-minute-sleep work-time 5))
    (print "\n")
    (notify "Finish working time")
    ;; Exit 時だけでは途中で kill された時に残らないので、作業するたびに log file を更新する
    (let* ([today-tag (current-date-keyword)]
           [new-log
            (update-log-entry log today-tag (^[infor] (adding-worked-time infor work-time)))])
      (save-file *log-file-path* new-log)
      (process db new-log))))

(define (rest-process db log)
  (print-and-reading "何分休憩しますか？")
  (let ([rest-time (read)])
    (sleep-loop a-minute-sleep rest-time 5)
    (notify "Finish rest time")
    (process db log)))

(define (exit-process db log)
  (save-file *database-file-path* db)
  (print-and-reading "終了します"))

(define (else-process db log)
  (let advice-loop []
    (print-and-reading "何かアドバイスをしましょうか？それとも一覧を見ますか？")
    (print "(t:アドバイスをランダムに選択 all:一覧を見る それ以外:戻る)")
    (let ([op (read)])
      (match op
        ['t
         (let ([target-id (select-advice-id db)])
           (print-evaluate-advice target-id db))]
        ['all
         (print (show-advices db))
         (print-and-reading "試してみるアドバイスを入力してください")
         (let ([input-id (read)])
           (print-evaluate-advice input-id db))]
        [else
         (process db log)]))))

;; main

(define (main :optional (args '()))
  (when (> (length args) 1)
    (set! *debugging* (eq? (read-from-string (second args)) :debug)))
  (process (load-database) (load-log)))


;; chat

(define (main-chat)
  (chat-repl (load-database)))

(define (advise answer db)
  (print-and-reading "(´・∀・｀)ﾍｰ")
  (not (equal? answer "bye")))

(define (prompt)
  (format #t "> ")
  (flush)
  (read-line))

(define (chat-repl db)
  (print-and-reading "調子はどう？")
  (let loop ()
    (let* ([answer (prompt)])
      (when (advise answer db)
            (loop)))))
