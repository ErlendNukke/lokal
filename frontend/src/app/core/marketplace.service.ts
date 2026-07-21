import { Injectable } from '@angular/core';
import { ApiService } from './api.service';
import {
  FulfillmentType,
  Order,
  OrderStatus,
  Product,
  ProductCategory,
  ProductUnit,
  Review,
} from './models';

@Injectable({ providedIn: 'root' })
export class MarketplaceService {
  constructor(private api: ApiService) {}

  searchProducts(params: {
    lat?: number;
    lng?: number;
    radiusKm?: number;
    category?: ProductCategory;
    q?: string;
  }): Promise<Product[]> {
    const query = new URLSearchParams();
    if (params.lat != null) query.set('lat', String(params.lat));
    if (params.lng != null) query.set('lng', String(params.lng));
    if (params.radiusKm != null) query.set('radiusKm', String(params.radiusKm));
    if (params.category) query.set('category', params.category);
    if (params.q) query.set('q', params.q);
    const qs = query.toString();
    return this.api.request<Product[]>(`/api/products${qs ? `?${qs}` : ''}`, {}, false);
  }

  getProduct(id: string, lat?: number, lng?: number): Promise<Product> {
    const query = new URLSearchParams();
    if (lat != null) query.set('lat', String(lat));
    if (lng != null) query.set('lng', String(lng));
    const qs = query.toString();
    return this.api.request<Product>(`/api/products/${id}${qs ? `?${qs}` : ''}`, {}, false);
  }

  myProducts(): Promise<Product[]> {
    return this.api.request<Product[]>('/api/producer/products');
  }

  createProduct(payload: {
    name: string;
    description?: string;
    category: ProductCategory;
    price: number;
    unit: ProductUnit;
    quantity: number;
    latitude: number;
    longitude: number;
    locationLabel?: string;
    pickupAvailable?: boolean;
    deliveryAvailable?: boolean;
    photoUrls?: string[];
  }): Promise<Product> {
    return this.api.request<Product>('/api/producer/products', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  }

  deleteProduct(id: string): Promise<void> {
    return this.api.request<void>(`/api/producer/products/${id}`, { method: 'DELETE' });
  }

  createOrder(payload: {
    productId: string;
    quantity: number;
    fulfillment: FulfillmentType;
    message?: string;
  }): Promise<Order> {
    return this.api.request<Order>('/api/orders', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  }

  myOrders(): Promise<Order[]> {
    return this.api.request<Order[]>('/api/orders/mine');
  }

  producerOrders(): Promise<Order[]> {
    return this.api.request<Order[]>('/api/producer/orders');
  }

  updateOrderStatus(id: string, status: OrderStatus): Promise<Order> {
    return this.api.request<Order>(`/api/orders/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    });
  }

  createReview(payload: { orderId: string; rating: number; comment?: string }): Promise<Review> {
    return this.api.request<Review>('/api/reviews', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  }

  producerReviews(producerId: string): Promise<Review[]> {
    return this.api.request<Review[]>(`/api/producers/${producerId}/reviews`, {}, false);
  }

  async uploadImage(file: File): Promise<string> {
    const form = new FormData();
    form.append('file', file);
    const res = await this.api.request<{ url: string }>('/api/uploads', {
      method: 'POST',
      body: form,
    });
    return res.url;
  }
}
