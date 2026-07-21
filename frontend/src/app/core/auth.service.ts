import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { ApiService } from './api.service';
import { AuthResponse, User, UserRole } from './models';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly userSubject = new BehaviorSubject<User | null>(this.readUser());
  readonly user$ = this.userSubject.asObservable();

  constructor(private api: ApiService) {}

  get user(): User | null {
    return this.userSubject.value;
  }

  get token(): string | null {
    return localStorage.getItem('kk_token');
  }

  get isLoggedIn(): boolean {
    return !!this.token && !!this.user;
  }

  get isProducer(): boolean {
    const role = this.user?.role;
    return role === 'PRODUCER' || role === 'BOTH';
  }

  async register(payload: {
    name: string;
    email: string;
    password: string;
    role: UserRole;
    city?: string;
    latitude?: number;
    longitude?: number;
  }): Promise<User> {
    const res = await this.api.request<AuthResponse>('/api/auth/register', {
      method: 'POST',
      body: JSON.stringify(payload),
    }, false);
    this.persist(res);
    return res.user;
  }

  async login(email: string, password: string): Promise<User> {
    const res = await this.api.request<AuthResponse>('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }, false);
    this.persist(res);
    return res.user;
  }

  /** MVP Google login stub — wire Firebase/Google Identity later */
  async googleLogin(payload: { idToken: string; email: string; name: string; role?: UserRole }): Promise<User> {
    const res = await this.api.request<AuthResponse>('/api/auth/google', {
      method: 'POST',
      body: JSON.stringify(payload),
    }, false);
    this.persist(res);
    return res.user;
  }

  async refreshMe(): Promise<User> {
    const user = await this.api.request<User>('/api/auth/me');
    localStorage.setItem('kk_user', JSON.stringify(user));
    this.userSubject.next(user);
    return user;
  }

  async updateProfile(payload: Record<string, unknown>): Promise<User> {
    const user = await this.api.request<User>('/api/auth/me', {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
    localStorage.setItem('kk_user', JSON.stringify(user));
    this.userSubject.next(user);
    return user;
  }

  logout(): void {
    localStorage.removeItem('kk_token');
    localStorage.removeItem('kk_user');
    this.userSubject.next(null);
  }

  private persist(res: AuthResponse): void {
    localStorage.setItem('kk_token', res.token);
    localStorage.setItem('kk_user', JSON.stringify(res.user));
    this.userSubject.next(res.user);
  }

  private readUser(): User | null {
    const raw = localStorage.getItem('kk_user');
    if (!raw) {
      return null;
    }
    try {
      return JSON.parse(raw) as User;
    } catch {
      return null;
    }
  }
}
