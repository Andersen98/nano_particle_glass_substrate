(load-from-path "/home/maeve/Github/nano_particle_glass_substrate/src/utils.scm")
(define-param r 1.0) ;; radius of sphere
(define-param inc-threshold 0) ;; threshold of total accumulated energy. default 0
(define-param nsteps 25)
(define-param runtime 10)

(define wvl-min (/ (* 2 pi r) 10))
(define wvl-max (/ (* 2 pi r) 2))

(define frq-min (/ wvl-max))
(define frq-max (/ wvl-min))
(define frq-cen (* 0.5 (+ frq-min frq-max)))
(define dfrq (- frq-max frq-min))
(define nfrq 100)

;; at least 8 pixels per smallest wavelength, i.e. (floor (/ 8 wvl-min))
(set-param! resolution 25)
;; Meep stores and computes on every grid point that intersects the flux region.
;; For test calculations/sanity checks, we can just make the flux regions tiny.
;; (Storing and computing field spectra is expensive both in COMPUTE TIME and MEMORY)
(define-param incident-flux-scale 0.1)
(define-param side-flux-scale 0.1)

(define dpml (* 0.5 wvl-max))
(define dair (* 0.5 wvl-max))


(define boundary-layers (list (make pml (thickness dpml))))
(set! pml-layers boundary-layers)

(define symm (list (make mirror-sym (direction Y))
                   (make mirror-sym (direction Z) (phase -1))))
(set! symmetries symm)

(define nsphere 2.0)
(set! geometry (list
                (make sphere
                  (material (make medium (index nsphere)))
                  (radius r)
                  (center 0))))


(define s (* 2 (+ dpml dair r)))
(define cell (make lattice (size s s s)))
(set! geometry-lattice cell)

;;  necessary for any planewave source extending into PML
;;(is-integrated? true) for plane wave extending into pml
(define pw-src (make source
                 (src (make gaussian-src (frequency frq-cen) (fwidth dfrq) (is-integrated? true)))
                 (center (+ (* -0.5 s) dpml) 0 0)
                 (size 0 s s)
                 (component Ez)))
(set! sources (list pw-src))

(set! k-point (vector3 0))

(define incident-center (vector3 (- r) 0 0))
(define incident-size (vector3 0 (* 2 r ) (* 2 r)))
(define side-center (vector3 0 (- r) 0))
(define side-size (vector3 (* 2 r ) 0 (* 2 r)))

;; rescale flux regions
(set! incident-size (vector3* incident-size incident-flux-scale))
(set! side-size (vector3* side-size side-flux-scale))

(define incident-energy-region (make energy-region
    (center incident-center)
    (size incident-size)))
(define side-energy-region (make energy-region
    (center side-center)
    (size side-size)
    (weight -1.0) ;; flux is computed in the positive coordinate. So we want the outward flux
))

(define Einc (add-energy frq-cen dfrq nfrq incident-energy-region ))
(define Eside (add-energy frq-cen dfrq nfrq side-energy-region ))
(define (zip . ls)(apply map (cons list ls)))
(define (energy-spectra energy)(zip (get-energy-freqs Eside) (get-total-energy energy)))
(define (energy-step-function energy) (lambda () (begin 
    (print "%\n")
    (for-each (lambda (x) (print (first x) " " (second x) "\n")) (energy-spectra energy ))
    (print "\n"))))

(use-output-directory)


(run-until (+ 0.000001 runtime )
    (at-every (/ runtime nsteps)
    (when-true (geq-threshold? (sum-squares 
            (get-total-energy Einc)) inc-threshold)
            (energy-step-function Eside)
            (in-volume (volume (center 0) (size s s 0))
                (output-png Ez "-Zc dkbluered")))))
