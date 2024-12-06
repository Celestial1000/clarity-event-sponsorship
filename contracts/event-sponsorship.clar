;; Event Sponsorship Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-event-ended (err u104))

;; Data Variables
(define-data-var next-event-id uint u0)

;; Data Maps
(define-map events
    uint 
    {
        organizer: principal,
        title: (string-ascii 100),
        target-amount: uint,
        current-amount: uint,
        end-block: uint,
        is-active: bool
    }
)

(define-map sponsorships
    {event-id: uint, sponsor: principal}
    uint
)

;; Public Functions
(define-public (create-event (title (string-ascii 100)) (target-amount uint) (duration uint))
    (let
        (
            (event-id (var-get next-event-id))
            (end-block (+ block-height duration))
        )
        (map-insert events event-id {
            organizer: tx-sender,
            title: title,
            target-amount: target-amount,
            current-amount: u0,
            end-block: end-block,
            is-active: true
        })
        (var-set next-event-id (+ event-id u1))
        (ok event-id)
    )
)

(define-public (sponsor-event (event-id uint) (amount uint))
    (let
        (
            (event (unwrap! (map-get? events event-id) err-not-found))
            (current-block block-height)
        )
        (asserts! (<= current-block (get end-block event)) err-event-ended)
        (asserts! (get is-active event) err-event-ended)
        (try! (stx-transfer? amount tx-sender (get organizer event)))
        (map-set events event-id (merge event {
            current-amount: (+ (get current-amount event) amount)
        }))
        (map-set sponsorships {event-id: event-id, sponsor: tx-sender} 
            (+ (default-to u0 (map-get? sponsorships {event-id: event-id, sponsor: tx-sender})) amount)
        )
        (ok true)
    )
)

(define-public (end-event (event-id uint))
    (let
        (
            (event (unwrap! (map-get? events event-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get organizer event)) err-owner-only)
        (map-set events event-id (merge event {
            is-active: false
        }))
        (ok true)
    )
)

;; Read Only Functions
(define-read-only (get-event (event-id uint))
    (ok (map-get? events event-id))
)

(define-read-only (get-sponsorship-amount (event-id uint) (sponsor principal))
    (ok (default-to u0 (map-get? sponsorships {event-id: event-id, sponsor: sponsor})))
)

(define-read-only (get-next-event-id)
    (ok (var-get next-event-id))
)
