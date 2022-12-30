;; -------------------------SETUP------------------------------------

;; -------------------------RESCALE GOLD TO UM-SCALE------------------------------------


; From Materials Library (https://github.com/NanoComp/meep/blob/master/scheme/materials.scm)

; default unit length is 1 um
(define um-scale 1.0)
(set! um-scale (* 0.05 um-scale))

; conversion factor for eV to 1/um [=1/hc]
(define eV-um-scale (/ um-scale 1.23984193))


;------------------------------------------------------------------
; gold (Au)
; fit to E.D. Palik, Handbook of Optical Constants, Academic Press, 1985

(define Au-visible-frq0 (/ (* 0.0473629248511456 um-scale)))
(define Au-visible-gam0 (/ (* 0.255476199605166 um-scale)))
(define Au-visible-sig0 1)

(define Au-visible-frq1 (/ (* 0.800619321082804 um-scale)))
(define Au-visible-gam1 (/ (* 0.381870287531951 um-scale)))
(define Au-visible-sig1 -169.060953137985)

(define Au-visible (make medium (epsilon 0.6888)
  (E-susceptibilities
   (make drude-susceptibility
     (frequency Au-visible-frq0) (gamma Au-visible-gam0) (sigma Au-visible-sig0))
   (make lorentzian-susceptibility
     (frequency Au-visible-frq1) (gamma Au-visible-gam1) (sigma Au-visible-sig1)))))

;------------------------------------------------------------------


;; From principles of nano-optics, gold nano particles resonate at around 500 nm, or 0.5 um
;; um-scale is defined as 0.05, so unit length in meep is 50 nm.

(define-param r .5 ) ;; radius of sphere is 25nm
(define wvl-min 9) ;; (* (0.450 um) (/ um-scale) ) ) = 9 meep length units
(define wvl-max 12) ;; (* (0.600 um) (/ um-scale) ) = 12 meep length units
(define frq-min (/ wvl-max))
(define frq-max (/ wvl-min))
(define frq-cen (* 0.5 (+ frq-min frq-max)))
(define dfrq (- frq-max frq-min))
(define nfrq 100)


;; try to make resolution comprable to nano particle (8 pixelels over the width of the particle)
(set-param! resolution 50)

;;turn off subpixel averaging since we are 
;;using gold as a material
(set! eps-averaging? false)

(define dpml 4)
(define dair 1)

(define boundary-layers (list (make pml (thickness dpml))))
(set! pml-layers boundary-layers)


(define symm (list (make mirror-sym (direction Y))
                   (make mirror-sym (direction Z) (phase -1))))
(set! symmetries symm)

(define s (* 2 (+ dpml dair r)))
(define cell (make lattice (size s s s)))
(set! geometry-lattice cell)

;; (is-integrated? true) necessary for any planewave source extending into PML
(define pw-src (make source
                 (src (make gaussian-src (frequency frq-cen) (fwidth dfrq) (is-integrated? true)))
                 (center (+ (* -0.5 s) dpml) 0 0)
                 (size 0 s s)
                 (component Ez)))
(set! sources (list pw-src))
(set! force-complex-fields? true)
(set! k-point (vector3 0))


(define box-x1 (add-flux frq-cen dfrq nfrq
                         (make flux-region (center (- r) 0 0) (size 0 (* 2 r) (* 2 r)))))
(define box-x2 (add-flux frq-cen dfrq nfrq
                         (make flux-region (center (+ r) 0 0) (size 0 (* 2 r) (* 2 r)))))


;; -----------------------------MEASURE INCIDENT FLUX------------------------------


(run-sources+ 10)

(display-fluxes box-x1)

(save-flux "box-x1-flux" box-x1)
(save-flux "box-x2-flux" box-x2)

;; -----------------------------RESET MEEP------------------------------

(reset-meep)

;; -----------------------------MEASURE TOTAL FLUX------------------------------

;; try to make resolution comprable to nano particle (8 pixelels over the width of the particle)


(set! geometry (list
                (make sphere
                  (material Au-visible)
                  (radius r)
                  (center 0))))
                  
(set! geometry-lattice cell)

(set! pml-layers boundary-layers)

(set! symmetries symm)

(set! sources (list pw-src))
(set! force-complex-fields? true)
(set! k-point (vector3 0))

(define box-x1 (add-flux frq-cen dfrq nfrq
                         (make flux-region (center (- r) 0 0) (size 0 (* 2 r) (* 2 r)))))
(define box-x2 (add-flux frq-cen dfrq nfrq
                         (make flux-region (center (+ r) 0 0) (size 0 (* 2 r) (* 2 r)))))

(load-minus-flux "box-x1-flux" box-x1)
(load-minus-flux "box-x2-flux" box-x2)


(run-sources+ 100)

(display-fluxes box-x1 box-x2)
