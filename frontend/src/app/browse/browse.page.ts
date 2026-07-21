import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../core/auth.service';
import { MarketplaceService } from '../core/marketplace.service';
import { CATEGORIES, Product, ProductCategory, RADIUS_OPTIONS } from '../core/models';
import { environment } from '../../environments/environment';
import { MapMarker } from '../shared/map-view.component';

@Component({
  selector: 'app-browse',
  templateUrl: './browse.page.html',
  styleUrls: ['./browse.page.scss'],
  standalone: false,
})
export class BrowsePage implements OnInit {
  categories = CATEGORIES;
  radiusOptions = RADIUS_OPTIONS;
  products: Product[] = [];
  markers: MapMarker[] = [];
  loading = true;
  error = '';
  selectedCategory: ProductCategory | 'ALL' = 'ALL';
  radiusKm = 20;
  search = '';
  lat = environment.defaultLat;
  lng = environment.defaultLng;

  constructor(
    private marketplace: MarketplaceService,
    public auth: AuthService,
    private router: Router,
  ) {}

  ngOnInit(): void {
    if (this.auth.user?.latitude && this.auth.user?.longitude) {
      this.lat = this.auth.user.latitude;
      this.lng = this.auth.user.longitude;
    }
    this.load();
  }

  async load(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      this.products = await this.marketplace.searchProducts({
        lat: this.lat,
        lng: this.lng,
        radiusKm: this.radiusKm,
        category: this.selectedCategory === 'ALL' ? undefined : this.selectedCategory,
        q: this.search.trim() || undefined,
      });
      this.markers = this.products.map((p) => ({
        id: p.id,
        lat: p.latitude,
        lng: p.longitude,
        label: `${p.name} · ${p.price.toFixed(2)} €`,
      }));
    } catch (e) {
      this.error = e instanceof Error ? e.message : 'Failed to load products';
      this.products = [];
      this.markers = [];
    } finally {
      this.loading = false;
    }
  }

  selectCategory(key: ProductCategory | 'ALL'): void {
    this.selectedCategory = key;
    this.load();
  }

  setRadius(km: number): void {
    this.radiusKm = km;
    this.load();
  }

  openProduct(id: string): void {
    this.router.navigate(['/tabs/product', id]);
  }

  photo(product: Product): string {
    return product.photos?.[0] || 'assets/icon/favicon.png';
  }
}
