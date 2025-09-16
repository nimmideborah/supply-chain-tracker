;; Product Registry Contract
;; Manages product creation and registration with unique identifiers, stores manufacturing details and 
;; sustainability metrics, handles ownership transfers between supply chain participants, and maintains
;; immutable product histories with batch tracking.

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_OWNER (err u103))
(define-constant ERR_INVALID_STATUS (err u104))
(define-constant ERR_INVALID_BATCH (err u105))
(define-constant ERR_TRANSFER_FAILED (err u106))
(define-constant ERR_METRIC_LIMIT_EXCEEDED (err u107))
(define-constant ERR_INVALID_LOCATION (err u108))

;; Product Status Constants
(define-constant STATUS_CREATED u0)
(define-constant STATUS_IN_PRODUCTION u1)
(define-constant STATUS_MANUFACTURED u2)
(define-constant STATUS_IN_TRANSIT u3)
(define-constant STATUS_DELIVERED u4)
(define-constant STATUS_RECALLED u5)
(define-constant STATUS_DISPOSED u6)

;; Participant Role Constants
(define-constant ROLE_MANUFACTURER u0)
(define-constant ROLE_DISTRIBUTOR u1)
(define-constant ROLE_RETAILER u2)
(define-constant ROLE_CONSUMER u3)
(define-constant ROLE_AUDITOR u4)

;; Data Variables
(define-data-var product-counter uint u0)
(define-data-var batch-counter uint u0)
(define-data-var max-sustainability-metrics uint u20)
(define-data-var max-location-updates uint u100)

;; Data Maps

;; Product registry with comprehensive details
(define-map products
  uint
  {
    name: (string-utf8 256),
    description: (string-utf8 1024),
    manufacturer: principal,
    current-owner: principal,
    batch-id: (string-ascii 64),
    status: uint,
    created-at: uint,
    last-updated: uint,
    authenticity-hash: (buff 32),
    total-transfers: uint,
    sustainability-score: uint
  }
)

;; Product ownership history
(define-map ownership-history
  { product-id: uint, transfer-id: uint }
  {
    from-owner: principal,
    to-owner: principal,
    transferred-at: uint,
    location: (string-utf8 128),
    transfer-reason: (string-utf8 256),
    verification-hash: (buff 32)
  }
)

;; Batch information for products
(define-map batch-info
  (string-ascii 64)
  {
    batch-creator: principal,
    created-at: uint,
    total-products: uint,
    batch-status: uint,
    quality-metrics: (string-utf8 512),
    expiry-date: uint
  }
)

;; Sustainability metrics per product
(define-map sustainability-metrics
  { product-id: uint, metric-id: uint }
  {
    metric-type: (string-ascii 32),
    value: uint,
    unit: (string-ascii 16),
    recorded-by: principal,
    recorded-at: uint,
    verification-status: bool
  }
)

;; Location history for products
(define-map location-history
  { product-id: uint, location-id: uint }
  {
    latitude: int,
    longitude: int,
    location-name: (string-utf8 128),
    updated-by: principal,
    updated-at: uint,
    temperature: int,
    humidity: uint
  }
)

;; Product authentication certificates
(define-map authenticity-certificates
  uint
  {
    certificate-hash: (buff 32),
    issuer: principal,
    issued-at: uint,
    valid-until: uint,
    certificate-type: (string-ascii 32),
    verification-data: (string-utf8 512)
  }
)

;; Participant registry
(define-map participants
  principal
  {
    role: uint,
    company-name: (string-utf8 256),
    registered-at: uint,
    is-verified: bool,
    certification-level: uint,
    total-products-handled: uint
  }
)

;; Product recall information
(define-map product-recalls
  uint
  {
    recall-reason: (string-utf8 512),
    recalled-by: principal,
    recalled-at: uint,
    affected-batches: (list 10 (string-ascii 64)),
    recall-severity: uint,
    resolution-status: uint
  }
)

;; Private Functions

(define-private (is-valid-participant (address principal))
  (is-some (map-get? participants address))
)

(define-private (is-product-owner (product-id uint) (address principal))
  (match (map-get? products product-id)
    product-info (is-eq (get current-owner product-info) address)
    false
  )
)

(define-private (increment-product-counter)
  (let (
    (current-counter (var-get product-counter))
  )
    (var-set product-counter (+ current-counter u1))
    (+ current-counter u1)
  )
)

(define-private (increment-batch-counter)
  (let (
    (current-counter (var-get batch-counter))
  )
    (var-set batch-counter (+ current-counter u1))
    (+ current-counter u1)
  )
)

(define-private (generate-authenticity-hash (product-id uint) (manufacturer principal) (batch-id (string-ascii 64)))
  (sha256 (concat 
    (concat 
      (unwrap-panic (to-consensus-buff? product-id))
      (unwrap-panic (to-consensus-buff? manufacturer))
    )
    (unwrap-panic (to-consensus-buff? batch-id))
  ))
)

(define-private (update-participant-stats (participant principal))
  (match (map-get? participants participant)
    participant-info
      (begin
        (map-set participants participant
          (merge participant-info
            { total-products-handled: (+ (get total-products-handled participant-info) u1) }
          )
        )
        true
      )
    true
  )
)

;; Public Functions

;; Register a new participant in the supply chain
(define-public (register-participant 
  (participant-address principal) 
  (role uint) 
  (company-name (string-utf8 256))
  (certification-level uint))
  (begin
    ;; Check if participant doesn't already exist
    (asserts! (not (is-valid-participant participant-address)) ERR_ALREADY_EXISTS)
    
    ;; Validate role
    (asserts! (<= role ROLE_AUDITOR) ERR_INVALID_STATUS)
    
    ;; Register participant
    (map-set participants participant-address {
      role: role,
      company-name: company-name,
      registered-at: block-height,
      is-verified: false,
      certification-level: certification-level,
      total-products-handled: u0
    })
    
    (ok true)
  )
)

;; Create a new product with batch information
(define-public (create-product 
  (name (string-utf8 256)) 
  (description (string-utf8 1024)) 
  (batch-id (string-ascii 64))
  (quality-metrics (string-utf8 512))
  (expiry-date uint))
  (let (
    (product-id (increment-product-counter))
    (authenticity-hash (generate-authenticity-hash product-id tx-sender batch-id))
  )
    ;; Check if sender is registered participant
    (asserts! (is-valid-participant tx-sender) ERR_UNAUTHORIZED)
    
    ;; Create or update batch info
    (match (map-get? batch-info batch-id)
      existing-batch
        (map-set batch-info batch-id
          (merge existing-batch
            { total-products: (+ (get total-products existing-batch) u1) }
          )
        )
      ;; Create new batch
      (map-set batch-info batch-id {
        batch-creator: tx-sender,
        created-at: block-height,
        total-products: u1,
        batch-status: STATUS_CREATED,
        quality-metrics: quality-metrics,
        expiry-date: expiry-date
      })
    )
    
    ;; Create product
    (map-set products product-id {
      name: name,
      description: description,
      manufacturer: tx-sender,
      current-owner: tx-sender,
      batch-id: batch-id,
      status: STATUS_CREATED,
      created-at: block-height,
      last-updated: block-height,
      authenticity-hash: authenticity-hash,
      total-transfers: u0,
      sustainability-score: u0
    })
    
    ;; Create authenticity certificate
    (map-set authenticity-certificates product-id {
      certificate-hash: authenticity-hash,
      issuer: tx-sender,
      issued-at: block-height,
      valid-until: (+ block-height u525600), ;; Valid for ~1 year
      certificate-type: "PRODUCT_CREATION",
      verification-data: name
    })
    
    ;; Update participant stats
    (update-participant-stats tx-sender)
    
    (ok product-id)
  )
)

;; Transfer product ownership
(define-public (transfer-ownership 
  (product-id uint) 
  (new-owner principal)
  (location (string-utf8 128))
  (transfer-reason (string-utf8 256)))
  (let (
    (product-info (unwrap! (map-get? products product-id) ERR_NOT_FOUND))
    (transfer-id (get total-transfers product-info))
    (verification-hash (sha256 (concat 
      (concat (unwrap-panic (to-consensus-buff? product-id)) (unwrap-panic (to-consensus-buff? tx-sender)))
      (unwrap-panic (to-consensus-buff? new-owner))
    )))
  )
    ;; Check if sender is current owner
    (asserts! (is-eq (get current-owner product-info) tx-sender) ERR_UNAUTHORIZED)
    
    ;; Check if new owner is registered participant
    (asserts! (is-valid-participant new-owner) ERR_INVALID_OWNER)
    
    ;; Record ownership transfer
    (map-set ownership-history
      { product-id: product-id, transfer-id: transfer-id }
      {
        from-owner: tx-sender,
        to-owner: new-owner,
        transferred-at: block-height,
        location: location,
        transfer-reason: transfer-reason,
        verification-hash: verification-hash
      }
    )
    
    ;; Update product ownership
    (map-set products product-id
      (merge product-info {
        current-owner: new-owner,
        last-updated: block-height,
        total-transfers: (+ transfer-id u1),
        status: STATUS_IN_TRANSIT
      })
    )
    
    ;; Update participant stats for both parties
    (update-participant-stats tx-sender)
    (update-participant-stats new-owner)
    
    (ok transfer-id)
  )
)

;; Update product location and environmental conditions
(define-public (update-location 
  (product-id uint) 
  (latitude int) 
  (longitude int)
  (location-name (string-utf8 128))
  (temperature int)
  (humidity uint))
  (let (
    (product-info (unwrap! (map-get? products product-id) ERR_NOT_FOUND))
    (location-id (get total-transfers product-info)) ;; Use transfers as location counter
  )
    ;; Check if sender is current owner or authorized participant
    (asserts! 
      (or 
        (is-eq (get current-owner product-info) tx-sender)
        (is-valid-participant tx-sender)
      ) 
      ERR_UNAUTHORIZED
    )
    
    ;; Record location update
    (map-set location-history
      { product-id: product-id, location-id: location-id }
      {
        latitude: latitude,
        longitude: longitude,
        location-name: location-name,
        updated-by: tx-sender,
        updated-at: block-height,
        temperature: temperature,
        humidity: humidity
      }
    )
    
    ;; Update product last-updated timestamp
    (map-set products product-id
      (merge product-info { last-updated: block-height })
    )
    
    (ok true)
  )
)

;; Add sustainability metrics to a product
(define-public (add-sustainability-metric 
  (product-id uint) 
  (metric-type (string-ascii 32))
  (value uint)
  (unit (string-ascii 16)))
  (let (
    (product-info (unwrap! (map-get? products product-id) ERR_NOT_FOUND))
    (metric-id (get sustainability-score product-info))
  )
    ;; Check if sender is authorized (owner or verified participant)
    (asserts! 
      (or 
        (is-eq (get current-owner product-info) tx-sender)
        (and (is-valid-participant tx-sender) 
             (default-to false (get is-verified (map-get? participants tx-sender))))
      ) 
      ERR_UNAUTHORIZED
    )
    
    ;; Check metric limit
    (asserts! (< metric-id (var-get max-sustainability-metrics)) ERR_METRIC_LIMIT_EXCEEDED)
    
    ;; Add sustainability metric
    (map-set sustainability-metrics
      { product-id: product-id, metric-id: metric-id }
      {
        metric-type: metric-type,
        value: value,
        unit: unit,
        recorded-by: tx-sender,
        recorded-at: block-height,
        verification-status: true
      }
    )
    
    ;; Update product sustainability score
    (map-set products product-id
      (merge product-info {
        sustainability-score: (+ metric-id u1),
        last-updated: block-height
      })
    )
    
    (ok metric-id)
  )
)

;; Update product status
(define-public (update-product-status (product-id uint) (new-status uint))
  (let (
    (product-info (unwrap! (map-get? products product-id) ERR_NOT_FOUND))
  )
    ;; Check if sender is current owner
    (asserts! (is-eq (get current-owner product-info) tx-sender) ERR_UNAUTHORIZED)
    
    ;; Validate status
    (asserts! (<= new-status STATUS_DISPOSED) ERR_INVALID_STATUS)
    
    ;; Update product status
    (map-set products product-id
      (merge product-info {
        status: new-status,
        last-updated: block-height
      })
    )
    
    (ok true)
  )
)

;; Initiate product recall
(define-public (initiate-recall 
  (product-id uint) 
  (reason (string-utf8 512))
  (severity uint)
  (affected-batches (list 10 (string-ascii 64))))
  (let (
    (product-info (unwrap! (map-get? products product-id) ERR_NOT_FOUND))
  )
    ;; Check if sender is manufacturer or authorized auditor
    (asserts! 
      (or 
        (is-eq (get manufacturer product-info) tx-sender)
        (and (is-valid-participant tx-sender)
             (is-eq (default-to u5 (get role (map-get? participants tx-sender))) ROLE_AUDITOR))
      ) 
      ERR_UNAUTHORIZED
    )
    
    ;; Record recall
    (map-set product-recalls product-id {
      recall-reason: reason,
      recalled-by: tx-sender,
      recalled-at: block-height,
      affected-batches: affected-batches,
      recall-severity: severity,
      resolution-status: u0
    })
    
    ;; Update product status to recalled
    (map-set products product-id
      (merge product-info {
        status: STATUS_RECALLED,
        last-updated: block-height
      })
    )
    
    (ok true)
  )
)

;; Read-Only Functions

;; Get complete product information
(define-read-only (get-product-info (product-id uint))
  (map-get? products product-id)
)

;; Get product ownership history
(define-read-only (get-ownership-history (product-id uint) (transfer-id uint))
  (map-get? ownership-history { product-id: product-id, transfer-id: transfer-id })
)

;; Get batch information
(define-read-only (get-batch-info (batch-id (string-ascii 64)))
  (map-get? batch-info batch-id)
)

;; Get sustainability metric
(define-read-only (get-sustainability-metric (product-id uint) (metric-id uint))
  (map-get? sustainability-metrics { product-id: product-id, metric-id: metric-id })
)

;; Get location history
(define-read-only (get-location-history (product-id uint) (location-id uint))
  (map-get? location-history { product-id: product-id, location-id: location-id })
)

;; Get authenticity certificate
(define-read-only (get-authenticity-certificate (product-id uint))
  (map-get? authenticity-certificates product-id)
)

;; Get participant information
(define-read-only (get-participant-info (participant-address principal))
  (map-get? participants participant-address)
)

;; Verify product authenticity
(define-read-only (verify-product-authenticity (product-id uint))
  (match (map-get? products product-id)
    product-info
      (let (
        (expected-hash (generate-authenticity-hash 
          product-id 
          (get manufacturer product-info) 
          (get batch-id product-info)
        ))
      )
        (is-eq (get authenticity-hash product-info) expected-hash)
      )
    false
  )
)

;; Get current product owner
(define-read-only (get-current-owner (product-id uint))
  (match (map-get? products product-id)
    product-info (some (get current-owner product-info))
    none
  )
)

;; Get product recall information
(define-read-only (get-product-recall (product-id uint))
  (map-get? product-recalls product-id)
)

;; Get total products count
(define-read-only (get-total-products)
  (var-get product-counter)
)

;; Check if product exists
(define-read-only (product-exists (product-id uint))
  (is-some (map-get? products product-id))
)


;; title: product-registry
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

