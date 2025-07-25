;; ExecutiveExpense - Multi-signature wallet for high-value corporate expenses
;; Requires multiple C-suite approvals for transactions

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_THRESHOLD (err u101))
(define-constant ERR_INVALID_SIGNER (err u102))
(define-constant ERR_ALREADY_SIGNED (err u103))
(define-constant ERR_INSUFFICIENT_SIGNATURES (err u104))
(define-constant ERR_TRANSACTION_NOT_FOUND (err u105))
(define-constant ERR_TRANSACTION_EXECUTED (err u106))
(define-constant ERR_INVALID_AMOUNT (err u107))

;; Data Variables
(define-data-var signature-threshold uint u3)
(define-data-var transaction-nonce uint u0)

;; Data Maps
(define-map authorized-signers principal bool)
(define-map transactions 
  uint 
  {
    recipient: principal,
    amount: uint,
    memo: (string-ascii 100),
    executed: bool,
    signatures-count: uint,
    created-by: principal
  }
)
(define-map transaction-signatures {tx-id: uint, signer: principal} bool)

;; Initialize contract with initial signers
(map-set authorized-signers CONTRACT_OWNER true)

;; Read-only functions
(define-read-only (get-signature-threshold)
  (var-get signature-threshold)
)

(define-read-only (is-authorized-signer (signer principal))
  (default-to false (map-get? authorized-signers signer))
)

(define-read-only (get-transaction (tx-id uint))
  (map-get? transactions tx-id)
)

(define-read-only (has-signed (tx-id uint) (signer principal))
  (default-to false (map-get? transaction-signatures {tx-id: tx-id, signer: signer}))
)

(define-read-only (get-current-nonce)
  (var-get transaction-nonce)
)

;; Private functions
(define-private (increment-nonce)
  (var-set transaction-nonce (+ (var-get transaction-nonce) u1))
)

;; Public functions

;; Add authorized signer (only contract owner)
(define-public (add-signer (new-signer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set authorized-signers new-signer true)
    (ok true)
  )
)

;; Remove authorized signer (only contract owner)
(define-public (remove-signer (signer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq signer CONTRACT_OWNER)) ERR_UNAUTHORIZED)
    (map-delete authorized-signers signer)
    (ok true)
  )
)

;; Update signature threshold (only contract owner)
(define-public (update-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> new-threshold u0) ERR_INVALID_THRESHOLD)
    (var-set signature-threshold new-threshold)
    (ok true)
  )
)

;; Create new expense transaction
(define-public (create-transaction (recipient principal) (amount uint) (memo (string-ascii 100)))
  (let ((current-nonce (var-get transaction-nonce)))
    (begin
      (asserts! (is-authorized-signer tx-sender) ERR_UNAUTHORIZED)
      (asserts! (> amount u0) ERR_INVALID_AMOUNT)
      
      ;; Create transaction
      (map-set transactions current-nonce {
        recipient: recipient,
        amount: amount,
        memo: memo,
        executed: false,
        signatures-count: u1,
        created-by: tx-sender
      })
      
      ;; Add creator's signature
      (map-set transaction-signatures {tx-id: current-nonce, signer: tx-sender} true)
      
      ;; Increment nonce
      (increment-nonce)
      
      (ok current-nonce)
    )
  )
)

;; Sign transaction
(define-public (sign-transaction (tx-id uint))
  (let ((transaction (unwrap! (map-get? transactions tx-id) ERR_TRANSACTION_NOT_FOUND)))
    (begin
      (asserts! (is-authorized-signer tx-sender) ERR_UNAUTHORIZED)
      (asserts! (not (get executed transaction)) ERR_TRANSACTION_EXECUTED)
      (asserts! (not (has-signed tx-id tx-sender)) ERR_ALREADY_SIGNED)
      
      ;; Add signature
      (map-set transaction-signatures {tx-id: tx-id, signer: tx-sender} true)
      
      ;; Update signature count
      (map-set transactions tx-id 
        (merge transaction {signatures-count: (+ (get signatures-count transaction) u1)})
      )
      
      (ok true)
    )
  )
)

;; Execute transaction (requires threshold signatures)
(define-public (execute-transaction (tx-id uint))
  (let ((transaction (unwrap! (map-get? transactions tx-id) ERR_TRANSACTION_NOT_FOUND)))
    (begin
      (asserts! (is-authorized-signer tx-sender) ERR_UNAUTHORIZED)
      (asserts! (not (get executed transaction)) ERR_TRANSACTION_EXECUTED)
      (asserts! (>= (get signatures-count transaction) (var-get signature-threshold)) ERR_INSUFFICIENT_SIGNATURES)
      
      ;; Mark as executed
      (map-set transactions tx-id (merge transaction {executed: true}))
      
      ;; Transfer STX to recipient
      (try! (stx-transfer? (get amount transaction) (as-contract tx-sender) (get recipient transaction)))
      
      (ok true)
    )
  )
)

;; Deposit STX to contract
(define-public (deposit (amount uint))
  (begin
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (stx-transfer? amount tx-sender (as-contract tx-sender))
  )
)

;; Get contract balance
(define-read-only (get-balance)
  (stx-get-balance (as-contract tx-sender))
)