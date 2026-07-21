import { Component, Input, OnChanges, OnDestroy, SimpleChanges } from '@angular/core';
import * as L from 'leaflet';

export interface MapMarker {
  id: string;
  lat: number;
  lng: number;
  label: string;
}

@Component({
  selector: 'app-map-view',
  template: `<div class="kk-map" #mapHost id="kk-map-host"></div>`,
  styles: [`:host { display: block; }`],
  standalone: false,
})
export class MapViewComponent implements OnChanges, OnDestroy {
  @Input() lat = 59.437;
  @Input() lng = 24.7536;
  @Input() zoom = 11;
  @Input() markers: MapMarker[] = [];

  private map?: L.Map;
  private layer?: L.LayerGroup;
  private initialized = false;

  ngOnChanges(_changes: SimpleChanges): void {
    setTimeout(() => this.render(), 0);
  }

  ngOnDestroy(): void {
    this.map?.remove();
  }

  private render(): void {
    const host = document.getElementById('kk-map-host');
    if (!host) {
      return;
    }

    if (!this.initialized) {
      this.map = L.map(host, {
        zoomControl: false,
        attributionControl: true,
      }).setView([this.lat, this.lng], this.zoom);

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 18,
        attribution: '&copy; OpenStreetMap',
      }).addTo(this.map);

      L.control.zoom({ position: 'bottomright' }).addTo(this.map);
      this.layer = L.layerGroup().addTo(this.map);
      this.initialized = true;

      setTimeout(() => this.map?.invalidateSize(), 120);
    } else {
      this.map?.setView([this.lat, this.lng], this.zoom);
    }

    this.layer?.clearLayers();
    const icon = L.divIcon({
      className: 'kk-marker',
      html: `<div style="width:14px;height:14px;border-radius:50%;background:#2f5d50;border:2px solid #fff;box-shadow:0 2px 8px rgba(0,0,0,.25)"></div>`,
      iconSize: [14, 14],
      iconAnchor: [7, 7],
    });

    this.markers.forEach((m) => {
      L.marker([m.lat, m.lng], { icon })
        .bindPopup(`<strong>${m.label}</strong>`)
        .addTo(this.layer!);
    });

    if (this.markers.length > 1) {
      const bounds = L.latLngBounds(this.markers.map((m) => [m.lat, m.lng] as [number, number]));
      this.map?.fitBounds(bounds.pad(0.2));
    }
  }
}
