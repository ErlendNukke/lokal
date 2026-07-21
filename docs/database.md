# Database schema

## ER overview

```text
users 1──1 producer_profiles 1──* products 1──* product_photos
  │                              │
  │                              └──* orders *──1 users (buyer)
  │                                    │
  │                                    └──1 reviews
  └── (buyer on orders / reviewer on reviews)
```

## Tables

### users
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| name | varchar(120) | |
| email | varchar(255) unique | |
| password_hash | varchar | nullable for Google |
| role | BUYER/PRODUCER/BOTH | |
| latitude, longitude | double | user home pin |
| city | varchar | |
| avatar_url | varchar | |
| auth_provider | LOCAL/GOOGLE | |
| created_at, updated_at | timestamp | |

### producer_profiles
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| user_id | UUID FK unique | |
| farm_name | varchar | |
| description | varchar | |
| rating_avg | decimal(3,2) | |
| rating_count | int | |
| pickup_available | bool | |
| delivery_available | bool | |
| delivery_radius_km | int | |
| created_at | timestamp | |

### products
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| producer_id | UUID FK | |
| name, description | | |
| category | FOOD/PLANTS/FARM/HANDMADE/OTHER | |
| price | decimal(10,2) | |
| unit | kg/piece/jar/box | |
| quantity | decimal | available stock |
| latitude, longitude | double | listing location |
| location_label | varchar | |
| pickup_available, delivery_available | bool | |
| active | bool | soft delete |
| created_at, updated_at | timestamp | |

### product_photos
| id | product_id | url | sort_order |

### orders
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| buyer_id, product_id, producer_id | UUID FK | |
| quantity, unit_price | decimal | |
| fulfillment | PICKUP/DELIVERY | |
| message | varchar | |
| status | PENDING/ACCEPTED/REJECTED/COMPLETED/CANCELLED | |
| created_at, updated_at | timestamp | |

### reviews
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| order_id | UUID unique | one review per order |
| reviewer_id, producer_id | UUID FK | |
| rating | int 1–5 | |
| comment | varchar | |
| created_at | timestamp | |

## Migrations

Liquibase:
- `001-schema.yaml` — tables + indexes
- `002-sample-data.yaml` — Estonia demo producers/products
