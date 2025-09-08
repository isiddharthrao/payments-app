package com.example.payments.controller;

import com.example.payments.model.ChargeRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "http://localhost:4200")
public class PaymentController {

    @GetMapping("/healthz")
    public ResponseEntity<String> healthz() {
        return ResponseEntity.ok("OK");
    }

    @PostMapping("/charge")
    public ResponseEntity<?> charge(@Valid @RequestBody ChargeRequest req) {
        try {
            // Minimal fake processing; insert real gateway calls here
            // Reject unsupported currency as an example 400 case
            if (!req.getCurrency().matches("(?i)^(INR|USD|EUR|GBP)$")) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(Map.of("error", "Unsupported currency"));
            }

            String txnId = UUID.randomUUID().toString();
            return ResponseEntity.ok(Map.of(
                    "status", "succeeded",
                    "transactionId", txnId,
                    "amount", req.getAmount(),
                    "currency", req.getCurrency(),
                    "customerId", req.getCustomerId()
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Processing failed"));
        }
    }
}
