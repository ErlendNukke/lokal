import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { ToastController } from '@ionic/angular';
import { AuthService } from '../core/auth.service';
import { UserRole } from '../core/models';

@Component({
  selector: 'app-profile',
  templateUrl: './profile.page.html',
  styleUrls: ['./profile.page.scss'],
  standalone: false,
})
export class ProfilePage implements OnInit {
  name = '';
  role: UserRole = 'BUYER';
  city = '';
  farmName = '';
  farmDescription = '';
  pickupAvailable = true;
  deliveryAvailable = false;
  saving = false;

  constructor(
    public auth: AuthService,
    private router: Router,
    private toast: ToastController,
  ) {}

  ngOnInit(): void {
    this.syncFromUser();
  }

  ionViewWillEnter(): void {
    if (!this.auth.isLoggedIn) {
      this.router.navigate(['/tabs/auth']);
      return;
    }
    this.syncFromUser();
  }

  syncFromUser(): void {
    const u = this.auth.user;
    if (!u) {
      return;
    }
    this.name = u.name;
    this.role = u.role;
    this.city = u.city || '';
    this.farmName = u.farmName || '';
  }

  async save(): Promise<void> {
    this.saving = true;
    try {
      await this.auth.updateProfile({
        name: this.name,
        role: this.role,
        city: this.city,
        farmName: this.farmName,
        farmDescription: this.farmDescription,
        pickupAvailable: this.pickupAvailable,
        deliveryAvailable: this.deliveryAvailable,
        latitude: this.auth.user?.latitude,
        longitude: this.auth.user?.longitude,
      });
      const t = await this.toast.create({ message: 'Profiil salvestatud', duration: 1500, color: 'success' });
      await t.present();
    } finally {
      this.saving = false;
    }
  }

  logout(): void {
    this.auth.logout();
    this.router.navigate(['/tabs/browse']);
  }
}
