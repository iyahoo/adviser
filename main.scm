(use srfi-1)
(use srfi-13)                           ; 文字列
(use srfi-27)                           ; for 乱数
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

(define (id-of-num-minused-by-list-until-0 num lst keys)
  (let loop ([num num] [lst lst] [keys keys])
    (if (null? lst)
        (car keys)
        (let ([judge-value (- num (car lst))])
          (if (< judge-value 0)
              (car keys)
              (loop judge-value (cdr lst) (cdr keys)))))))

(define (select-advice-id database)
  (let* ([contributions (map (lambda (entry) (list-ref entry 2)) database)]
         [roulette-num  (random-integer (reduce + 0 contributions))]
         [keys          (map (lambda (entry) (car entry)) database)])
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

(define (notify message)
  (when (file-is-executable? *notify-script-path*)
	(sys-system
	 (format #f "~A ~S" *notify-script-path* message))))

(define (show-advices database)
  (string-concatenate
   (map
    (match-lambda ([id advice contribution]
                   (string-concatenate (list (number->string id) ": " advice "\n")))
                  (else
                   ""))
    database)))

(define (good-effect-advice?)
  (eq? (read) 'g))


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



(define (print-evaluate-advice target-id database)
  (let ([entry (get-entry database target-id)])
    (print (entry-advice entry))
    (print "もし提案した手法が効果があると感じた場合は g を入力してください。")
    (if (good-effect-advice?)
	(a-process (increment-contribution database target-id))
	(a-process database))))


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
	 (notify "Finish working time")
         (a-process database))]
      ['exit
       (save-file *database-file-path* database)
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
  (let* ([db-file (if (file-is-writable? *database-file-path*)
		      *database-file-path*
		      *database-seed-path*)]
	 [database (read-file db-file)])
    (a-process database)))
