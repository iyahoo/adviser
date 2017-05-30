(use srfi-1)
(use srfi-13)                           ; 文字列
(use srfi-27)                           ; 乱数
(use util.match)                        ; like destructuring-bind
(use gauche.process)                    ; System call
(use file.util)

(define *database-seed-path* "./seed.sxp")
(define *database-file-path* "./database.sxp")
(define *notify-script-path* "./notify.sh")

(define (read-file fname)
  (with-input-from-file fname (lambda [] (read))))

(define (save-file fname data)
  (with-output-to-file fname (lambda [] (write data))
                       :if-exists :supersede))

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

;; Sleep and Display
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
                  (else
                   ""))
    db)))

(define (print-evaluate-advice target-id db)
  (let ([entry (get-entry db target-id)])
    (print (entry-advice entry))
    (print "もし提案した手法が効果があると感じた場合は g を入力してください。")
    (if (good-effect-advice?)
        (a-process (increment-contribution db target-id))
        (a-process db))))

(define (good-effect-advice?)
  (eq? (read) 'g))


(define (check-os)
  (call-with-input-process "uname"
    (lambda (p) (make-keyword (read-line p)))))

(define (notify message)
  (when (file-is-executable? *notify-script-path*)
    (sys-system
     (format #f "~A ~S" *notify-script-path* message))))

(define (a-process db)
  (print "\n調子はどうですか？")
  (print "(good: 作業を継続 bad:アドバイス exit:終了 それ以外:bad として認識)")
  (let ([command (read)])
    (match command
      ['good
       (print "今の作業を何分やりますか？正の整数を入力して下さい")
       (let ([work-time (read)])
         (sleep-loop a-minute-sleep work-time 5))
       (notify "Finish working time")
       (a-process db)]
      ['exit
       (save-file *database-file-path* db)
       (print "終了します")]
      [else
       (let advice-loop []
         (print "何かアドバイスをしましょうか？それとも一覧を見ますか？")
         (print "(t:アドバイスをランダムに選択 all:一覧を見る それ以外:戻る)")
         (let ([op (read)])
           (match op
             ['t
              (let ([target-id (select-advice-id db)])
                (print-evaluate-advice target-id db))]
             ['all
              (print (show-advices db))
              (print "試してみるアドバイスを入力してください")
              (let ([input-id (read)])
                (print-evaluate-advice input-id db))]
             [else
              (a-process db)])))])))


;; main

(define (main :optional (args '()))
  (let* ([db-file (if (file-is-writable? *database-file-path*)
                      *database-file-path*
                      *database-seed-path*)]
         [db (read-file db-file)])
    (a-process db)))
