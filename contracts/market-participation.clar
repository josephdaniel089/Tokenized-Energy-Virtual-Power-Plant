;; Market Participation Contract
;; Enables collective energy trading for VPPs

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_BID_NOT_FOUND (err u301))
(define-constant ERR_INVALID_AMOUNT (err u302))
(define-constant ERR_INVALID_PRICE (err u303))

;; Market bid structure
(define-map market-bids
  { bid-id: uint }
  {
    vpp-id: uint,
    bidder: principal,
    energy-amount: uint,
    price-per-mwh: uint,
    bid-type: (string-ascii 10), ;; "buy" or "sell"
    status: (string-ascii 10), ;; "active", "filled", "cancelled"
    created-at: uint
  }
)

(define-data-var next-bid-id uint u1)

;; Submit energy bid
(define-public (submit-bid (vpp-id uint) (energy-amount uint) (price-per-mwh uint) (bid-type (string-ascii 10)))
  (let ((bid-id (var-get next-bid-id)))
    (asserts! (> energy-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> price-per-mwh u0) ERR_INVALID_PRICE)

    (map-set market-bids
      { bid-id: bid-id }
      {
        vpp-id: vpp-id,
        bidder: tx-sender,
        energy-amount: energy-amount,
        price-per-mwh: price-per-mwh,
        bid-type: bid-type,
        status: "active",
        created-at: block-height
      }
    )
    (var-set next-bid-id (+ bid-id u1))
    (ok bid-id)
  )
)

;; Cancel bid
(define-public (cancel-bid (bid-id uint))
  (let ((bid (unwrap! (map-get? market-bids { bid-id: bid-id }) ERR_BID_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get bidder bid)) ERR_UNAUTHORIZED)
    (map-set market-bids
      { bid-id: bid-id }
      (merge bid { status: "cancelled" })
    )
    (ok true)
  )
)

;; Execute trade (simplified)
(define-public (execute-trade (buy-bid-id uint) (sell-bid-id uint))
  (let (
    (buy-bid (unwrap! (map-get? market-bids { bid-id: buy-bid-id }) ERR_BID_NOT_FOUND))
    (sell-bid (unwrap! (map-get? market-bids { bid-id: sell-bid-id }) ERR_BID_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    ;; Mark both bids as filled
    (map-set market-bids { bid-id: buy-bid-id } (merge buy-bid { status: "filled" }))
    (map-set market-bids { bid-id: sell-bid-id } (merge sell-bid { status: "filled" }))
    (ok true)
  )
)

;; Get bid details
(define-read-only (get-bid (bid-id uint))
  (map-get? market-bids { bid-id: bid-id })
)
