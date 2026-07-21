import { Component } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { ToastController } from '@ionic/angular';
import { AuthService } from '../core/auth.service';
import { UserRole } from '../core/models';
import { environment } from '../../environments/environment';

@Component({
  selector: 'app-auth',
  templateUrl: './auth.page.html',
  styleUrls: ['./auth.page.scss'],
  standalone: false,
})
export class AuthPage {
  mode: 'login' | 'register' = 'login';
  name = '';
  email = '';
  password = '';
  role: UserRole = 'BUYER';
  loading = false;
  error = '';
  returnUrl = '/tabs/browse';

  constructor(
    private auth: AuthService,
    private router: Router,
    private route: ActivatedRoute,
    private toast: ToastController,
  ) {
    this.returnUrl = this.route.snapshot.queryParamMap.get('returnUrl') || '/tabs/browse';
  }

  async submit(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      if (this.mode === 'login') {
        await this.auth.login(this.email.trim(), this.password);
      } else {
        await this.auth.register({
          name: this.name.trim(),
          email: this.email.trim(),
          password: this.password,
          role: this.role,
          city: environment.defaultCity,
          latitude: environment.defaultLat,
          longitude: environment.defaultLng,
        });
      }
      const t = await this.toast.create({ message: 'Tere tulemast Kodukraami!', duration: 1800, color: 'success' });
      await t.present();
      this.router.navigateByUrl(this.returnUrl);
    } catch (e) {
      this.error = e instanceof Error ? e.message : 'Autentimine ebaõnnestus';
    } finally {
      this.loading = false;
    }
  }

  async googleDemo(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      await this.auth.googleLogin({
        idToken: 'demo-google-token',
        email: `google.user.${Date.now()}@gmail.com`,
        name: 'Google Kasutaja',
        role: 'BUYER',
      });
      this.router.navigateByUrl(this.returnUrl);
    } catch (e) {
      this.error = e instanceof Error ? e.message : 'Google login ebaõnnestus';
    } finally {
      this.loading = false;
    }
  }

  fillDemo(email: string): void {
    this.mode = 'login';
    this.email = email;
    this.password = 'password123';
  }
}
