import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { PaymentsService, ChargeRequest, ChargeResponse } from './payments.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  title = 'Payments App';
  
  // Form data
  chargeRequest: ChargeRequest = {
    amount: 100,
    currency: 'USD',
    customerId: 'customer-123'
  };
  
  // UI state
  isLoading = false;
  isHealthCheckLoading = false;
  response: string = '';
  responseType: 'success' | 'error' = 'success';
  healthStatus: 'online' | 'offline' | 'unknown' = 'unknown';
  
  currencies = ['USD', 'EUR', 'GBP', 'INR'];
  
  constructor(private paymentsService: PaymentsService) {
    this.checkHealth();
  }
  
  onCharge() {
    this.isLoading = true;
    this.response = '';
    
    this.paymentsService.charge(this.chargeRequest).subscribe({
      next: (result: ChargeResponse) => {
        this.response = JSON.stringify(result, null, 2);
        this.responseType = 'success';
        this.isLoading = false;
      },
      error: (error: string) => {
        this.response = error;
        this.responseType = 'error';
        this.isLoading = false;
      }
    });
  }
  
  checkHealth() {
    this.isHealthCheckLoading = true;
    this.healthStatus = 'unknown';
    
    this.paymentsService.healthCheck().subscribe({
      next: (result: string) => {
        this.healthStatus = 'online';
        this.isHealthCheckLoading = false;
      },
      error: (error: string) => {
        this.healthStatus = 'offline';
        this.isHealthCheckLoading = false;
      }
    });
  }
  
  onQuickCharge(amount: number, currency: string) {
    this.chargeRequest.amount = amount;
    this.chargeRequest.currency = currency;
    this.onCharge();
  }
}
