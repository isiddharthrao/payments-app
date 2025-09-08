import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

export interface ChargeRequest {
  amount: number;
  currency: string;
  customerId: string;
}

export interface ChargeResponse {
  status: string;
  transactionId: string;
  amount: number;
  currency: string;
  customerId: string;
}

@Injectable({
  providedIn: 'root'
})
export class PaymentsService {
  private baseUrl = 'http://localhost:8080/api';

  constructor(private http: HttpClient) { }

  charge(request: ChargeRequest): Observable<ChargeResponse> {
    return this.http.post<ChargeResponse>(`${this.baseUrl}/charge`, request)
      .pipe(
        catchError(this.handleError)
      );
  }

  healthCheck(): Observable<string> {
    return this.http.get(`${this.baseUrl}/healthz`, { responseType: 'text' })
      .pipe(
        catchError(this.handleError)
      );
  }

  private handleError(error: HttpErrorResponse) {
    let errorMessage = 'An unknown error occurred!';
    if (error.error instanceof ErrorEvent) {
      // Client-side error
      errorMessage = `Error: ${error.error.message}`;
    } else {
      // Server-side error
      errorMessage = `Error Code: ${error.status}\nMessage: ${error.message}`;
      if (error.error && error.error.error) {
        errorMessage += `\nDetails: ${error.error.error}`;
      }
    }
    return throwError(() => errorMessage);
  }
}
