;; Dispatch Coordination Contract
;; Manages resource activation and coordination

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_DISPATCH_NOT_FOUND (err u401))
(define-constant ERR_INVALID_DURATION (err u402))

;; Dispatch order structure
(define-map dispatch-orders
  { order-id: uint }
  {
    vpp-id: uint,
    resource-id: uint,
    dispatcher: principal,
    power-output: uint,
    duration: uint,
    start-time: uint,
    status: (string-ascii 15), ;; "pending", "active", "completed", "cancelled"
    created-at: uint
  }
)

(define-data-var next-order-id uint u1)

;; Create dispatch order
(define-public (create-dispatch-order (vpp-id uint) (resource-id uint) (power-output uint) (duration uint) (start-time uint))
  (let ((order-id (var-get next-order-id)))
    (asserts! (> duration u0) ERR_INVALID_DURATION)

    (map-set dispatch-orders
      { order-id: order-id }
      {
        vpp-id: vpp-id,
        resource-id: resource-id,
        dispatcher: tx-sender,
        power-output: power-output,
        duration: duration,
        start-time: start-time,
        status: "pending",
        created-at: block-height
      }
    )
    (var-set next-order-id (+ order-id u1))
    (ok order-id)
  )
)

;; Activate dispatch order
(define-public (activate-dispatch (order-id uint))
  (let ((order (unwrap! (map-get? dispatch-orders { order-id: order-id }) ERR_DISPATCH_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set dispatch-orders
      { order-id: order-id }
      (merge order { status: "active" })
    )
    (ok true)
  )
)

;; Complete dispatch order
(define-public (complete-dispatch (order-id uint))
  (let ((order (unwrap! (map-get? dispatch-orders { order-id: order-id }) ERR_DISPATCH_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set dispatch-orders
      { order-id: order-id }
      (merge order { status: "completed" })
    )
    (ok true)
  )
)

;; Get dispatch order
(define-read-only (get-dispatch-order (order-id uint))
  (map-get? dispatch-orders { order-id: order-id })
)

;; Get active dispatches for VPP
(define-read-only (get-vpp-active-dispatches (vpp-id uint))
  ;; In a real implementation, this would iterate through orders
  ;; For simplicity, returning a placeholder
  (ok u0)
)
