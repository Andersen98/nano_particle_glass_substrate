(define (square x)(* x x))
(define (sum-fn fn lst )
    (if (null? lst)
    (fn 0)
    (+ (fn (car lst)) (sum-fn fn (cdr lst)))))
(define (sum lst)(sum-fn identity lst))
(define (sum-squares lst)(sum-fn square lst) )
(define 
    (geq-threshold? value threshold)
    (lambda ()
        (>= value threshold))
)
