import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { AlertController, ToastController } from '@ionic/angular';
import { AuthService } from '../core/auth.service';
import { MarketplaceService } from '../core/marketplace.service';
import { FulfillmentType, Product, Review } from '../core/models';
import { environment } from '../../environments/environment';

@Component({
  selector: 'app-product',
  templateUrl: './product.page.html',
  styleUrls: ['./product.page.scss'],
  standalone: false,
})
export class ProductPage implements OnInit {
  product?: Product;
  reviews: Review[] = [];
  loading = true;
  ordering = false;
  quantity = 1;
  fulfillment: FulfillmentType = 'PICKUP';
  message = '';
  error = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private marketplace: MarketplaceService,
    public auth: AuthService,
    private toast: ToastController,
    private alert: AlertController,
  ) {}

  async ngOnInit(): Promise<void> {
    const id = this.route.snapshot.paramMap.get('id');
    if (!id) {
      this.router.navigate(['/tabs/browse']);
      return;
    }
    const lat = this.auth.user?.latitude ?? environment.defaultLat;
    const lng = this.auth.user?.longitude ?? environment.defaultLng;
    try {
      this.product = await this.marketplace.getProduct(id, lat, lng);
      this.fulfillment = this.product.pickupAvailable ? 'PICKUP' : 'DELIVERY';
      this.reviews = await this.marketplace.producerReviews(this.product.producer.id);
    } catch (e) {
      this.error = e instanceof Error ? e.message : 'Toodet ei leitud';
    } finally {
      this.loading = false;
    }
  }

  photo(): string {
    return this.product?.photos?.[0] || 'assets/icon/favicon.png';
  }

  async order(): Promise<void> {
    if (!this.product) {
      return;
    }
    if (!this.auth.isLoggedIn) {
      this.router.navigate(['/tabs/auth'], { queryParams: { returnUrl: `/tabs/product/${this.product.id}` } });
      return;
    }

    this.ordering = true;
    try {
      await this.marketplace.createOrder({
        productId: this.product.id,
        quantity: this.quantity,
        fulfillment: this.fulfillment,
        message: this.message || undefined,
      });
      const t = await this.toast.create({
        message: 'Tellimus saadetud tootjale',
        duration: 2200,
        color: 'success',
      });
      await t.present();
      this.router.navigate(['/tabs/orders']);
    } catch (e) {
      const a = await this.alert.create({
        header: 'Tellimus ebaõnnestus',
        message: e instanceof Error ? e.message : 'Proovi uuesti',
        buttons: ['OK'],
      });
      await a.present();
    } finally {
      this.ordering = false;
    }
  }
}
