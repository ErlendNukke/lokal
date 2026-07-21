export type UserRole = 'BUYER' | 'PRODUCER' | 'BOTH';
export type ProductCategory = 'FOOD' | 'PLANTS' | 'FARM' | 'HANDMADE' | 'OTHER';
export type ProductUnit = 'kg' | 'piece' | 'jar' | 'box';
export type FulfillmentType = 'PICKUP' | 'DELIVERY';
export type OrderStatus = 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'COMPLETED' | 'CANCELLED';

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  latitude?: number;
  longitude?: number;
  city?: string;
  avatarUrl?: string;
  producerProfileId?: string;
  farmName?: string;
}

export interface AuthResponse {
  token: string;
  user: User;
}

export interface ProducerSummary {
  id: string;
  farmName: string;
  ownerName: string;
  ratingAvg: number;
  ratingCount: number;
}

export interface Product {
  id: string;
  name: string;
  description?: string;
  category: ProductCategory;
  price: number;
  unit: ProductUnit;
  quantity: number;
  latitude: number;
  longitude: number;
  locationLabel?: string;
  pickupAvailable: boolean;
  deliveryAvailable: boolean;
  photos: string[];
  distanceKm?: number;
  producer: ProducerSummary;
  createdAt: string;
}

export interface Order {
  id: string;
  productId: string;
  productName: string;
  productPhoto?: string;
  buyerId: string;
  buyerName: string;
  producerId: string;
  farmName: string;
  quantity: number;
  unit: ProductUnit;
  unitPrice: number;
  totalPrice: number;
  fulfillment: FulfillmentType;
  message?: string;
  status: OrderStatus;
  createdAt: string;
  canReview: boolean;
}

export interface Review {
  id: string;
  orderId: string;
  producerId: string;
  reviewerName: string;
  rating: number;
  comment?: string;
  createdAt: string;
}

export interface Producer {
  id: string;
  userId: string;
  farmName: string;
  description?: string;
  ownerName: string;
  ratingAvg: number;
  ratingCount: number;
  pickupAvailable: boolean;
  deliveryAvailable: boolean;
  deliveryRadiusKm: number;
  latitude?: number;
  longitude?: number;
  city?: string;
}

export const CATEGORIES: { key: ProductCategory | 'ALL'; label: string; icon: string }[] = [
  { key: 'ALL', label: 'Kõik', icon: '🏡' },
  { key: 'FOOD', label: 'Toit', icon: '🍎' },
  { key: 'PLANTS', label: 'Taimed', icon: '🌱' },
  { key: 'FARM', label: 'Talutooted', icon: '🍯' },
  { key: 'HANDMADE', label: 'Käsitöö', icon: '🎨' },
  { key: 'OTHER', label: 'Muu', icon: '✨' },
];

export const RADIUS_OPTIONS = [5, 20, 50];
