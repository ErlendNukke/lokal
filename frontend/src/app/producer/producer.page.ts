import { Component, OnInit } from '@angular/core';
import { AlertController, ToastController } from '@ionic/angular';
import { AuthService } from '../core/auth.service';
import { MarketplaceService } from '../core/marketplace.service';
import { Product, ProductCategory, ProductUnit } from '../core/models';
import { environment } from '../../environments/environment';

@Component({
  selector: 'app-producer',
  templateUrl: './producer.page.html',
  styleUrls: ['./producer.page.scss'],
  standalone: false,
})
export class ProducerPage implements OnInit {
  products: Product[] = [];
  loading = true;
  showForm = false;
  saving = false;

  name = '';
  description = '';
  category: ProductCategory = 'FOOD';
  price = 5;
  unit: ProductUnit = 'piece';
  quantity = 10;
  locationLabel = 'Tallinn';
  pickupAvailable = true;
  deliveryAvailable = false;
  photoUrl = '';

  categories: ProductCategory[] = ['FOOD', 'PLANTS', 'FARM', 'HANDMADE', 'OTHER'];
  units: ProductUnit[] = ['kg', 'piece', 'jar', 'box'];

  constructor(
    public auth: AuthService,
    private marketplace: MarketplaceService,
    private toast: ToastController,
    private alert: AlertController,
  ) {}

  async ngOnInit(): Promise<void> {
    await this.reload();
  }

  async ionViewWillEnter(): Promise<void> {
    await this.reload();
  }

  async reload(): Promise<void> {
    this.loading = true;
    try {
      this.products = await this.marketplace.myProducts();
    } catch {
      this.products = [];
    } finally {
      this.loading = false;
    }
  }

  async save(): Promise<void> {
    this.saving = true;
    try {
      await this.marketplace.createProduct({
        name: this.name.trim(),
        description: this.description.trim(),
        category: this.category,
        price: Number(this.price),
        unit: this.unit,
        quantity: Number(this.quantity),
        latitude: this.auth.user?.latitude ?? environment.defaultLat,
        longitude: this.auth.user?.longitude ?? environment.defaultLng,
        locationLabel: this.locationLabel,
        pickupAvailable: this.pickupAvailable,
        deliveryAvailable: this.deliveryAvailable,
        photoUrls: this.photoUrl ? [this.photoUrl] : [],
      });
      this.showForm = false;
      this.resetForm();
      await this.reload();
      const t = await this.toast.create({ message: 'Toode lisatud', duration: 1600, color: 'success' });
      await t.present();
    } catch (e) {
      const a = await this.alert.create({
        header: 'Viga',
        message: e instanceof Error ? e.message : 'Salvestamine ebaõnnestus',
        buttons: ['OK'],
      });
      await a.present();
    } finally {
      this.saving = false;
    }
  }

  async onFile(event: Event): Promise<void> {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) {
      return;
    }
    try {
      this.photoUrl = await this.marketplace.uploadImage(file);
    } catch (e) {
      const a = await this.alert.create({
        header: 'Üleslaadimine ebaõnnestus',
        message: e instanceof Error ? e.message : 'Proovi uuesti',
        buttons: ['OK'],
      });
      await a.present();
    }
  }

  async remove(product: Product): Promise<void> {
    const a = await this.alert.create({
      header: 'Eemalda toode?',
      message: product.name,
      buttons: [
        { text: 'Tühista', role: 'cancel' },
        {
          text: 'Eemalda',
          role: 'destructive',
          handler: async () => {
            await this.marketplace.deleteProduct(product.id);
            await this.reload();
          },
        },
      ],
    });
    await a.present();
  }

  private resetForm(): void {
    this.name = '';
    this.description = '';
    this.category = 'FOOD';
    this.price = 5;
    this.unit = 'piece';
    this.quantity = 10;
    this.photoUrl = '';
  }
}
