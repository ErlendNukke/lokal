import { Component, OnInit } from '@angular/core';
import { AlertController, ToastController } from '@ionic/angular';
import { AuthService } from '../core/auth.service';
import { MarketplaceService } from '../core/marketplace.service';
import { Order, OrderStatus } from '../core/models';

@Component({
  selector: 'app-orders',
  templateUrl: './orders.page.html',
  styleUrls: ['./orders.page.scss'],
  standalone: false,
})
export class OrdersPage implements OnInit {
  segment: 'buying' | 'selling' = 'buying';
  buying: Order[] = [];
  selling: Order[] = [];
  loading = true;

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
      this.buying = await this.marketplace.myOrders();
      if (this.auth.isProducer) {
        this.selling = await this.marketplace.producerOrders();
      }
    } catch {
      this.buying = [];
      this.selling = [];
    } finally {
      this.loading = false;
    }
  }

  list(): Order[] {
    return this.segment === 'buying' ? this.buying : this.selling;
  }

  statusClass(status: OrderStatus): string {
    return status.toLowerCase();
  }

  async update(order: Order, status: OrderStatus): Promise<void> {
    try {
      await this.marketplace.updateOrderStatus(order.id, status);
      await this.reload();
      const t = await this.toast.create({ message: `Staatus: ${status}`, duration: 1600, color: 'primary' });
      await t.present();
    } catch (e) {
      const a = await this.alert.create({
        header: 'Viga',
        message: e instanceof Error ? e.message : 'Uuendamine ebaõnnestus',
        buttons: ['OK'],
      });
      await a.present();
    }
  }

  async review(order: Order): Promise<void> {
    const a = await this.alert.create({
      header: 'Hinda tootjat',
      inputs: [
        { name: 'rating', type: 'number', placeholder: 'Hinne 1–5', min: 1, max: 5, value: 5 },
        { name: 'comment', type: 'textarea', placeholder: 'Kommentaar' },
      ],
      buttons: [
        { text: 'Tühista', role: 'cancel' },
        {
          text: 'Saada',
          handler: async (data) => {
            try {
              await this.marketplace.createReview({
                orderId: order.id,
                rating: Number(data.rating),
                comment: data.comment,
              });
              await this.reload();
            } catch (e) {
              const err = await this.alert.create({
                header: 'Viga',
                message: e instanceof Error ? e.message : 'Arvustus ebaõnnestus',
                buttons: ['OK'],
              });
              await err.present();
            }
          },
        },
      ],
    });
    await a.present();
  }
}
