;; Resource Verification Contract
;; Validates and manages distributed energy assets

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_RESOURCE_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_VERIFIED (err u102))
(define-constant ERR_INVALID_CAPACITY (err u103))

;; Resource data structure
(define-map resources
  { resource-id: uint }
  {
    owner: principal,
    resource-type: (string-ascii 20),
    capacity: uint,
    location: (string-ascii 50),
    verified: bool,
    verification-date: uint
  }
)

(define-data-var next-resource-id uint u1)

;; Register a new energy resource
(define-public (register-resource (resource-type (string-ascii 20)) (capacity uint) (location (string-ascii 50)))
  (let ((resource-id (var-get next-resource-id)))
    (asserts! (> capacity u0) ERR_INVALID_CAPACITY)
    (map-set resources
      { resource-id: resource-id }
      {
        owner: tx-sender,
        resource-type: resource-type,
        capacity: capacity,
        location: location,
        verified: false,
        verification-date: u0
      }
    )
    (var-set next-resource-id (+ resource-id u1))
    (ok resource-id)
  )
)

;; Verify a resource (only contract owner)
(define-public (verify-resource (resource-id uint))
  (let ((resource (unwrap! (map-get? resources { resource-id: resource-id }) ERR_RESOURCE_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (not (get verified resource)) ERR_ALREADY_VERIFIED)
    (map-set resources
      { resource-id: resource-id }
      (merge resource { verified: true, verification-date: block-height })
    )
    (ok true)
  )
)

;; Get resource details
(define-read-only (get-resource (resource-id uint))
  (map-get? resources { resource-id: resource-id })
)

;; Check if resource is verified
(define-read-only (is-verified (resource-id uint))
  (match (map-get? resources { resource-id: resource-id })
    resource (get verified resource)
    false
  )
)
