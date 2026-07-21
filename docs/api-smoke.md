# API smoke checklist

```bash
# Health
curl -s http://localhost:8080/actuator/health

# List nearby products (Tallinn, 20km)
curl -s "http://localhost:8080/api/products?lat=59.437&lng=24.7536&radiusKm=20" | jq '.[].name'

# Login as buyer
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"anna@kodukraam.ee","password":"password123"}' | jq -r .token)

# Place order
curl -s -X POST http://localhost:8080/api/orders \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"productId":"33333333-3333-3333-3333-333333333304","quantity":1,"fulfillment":"PICKUP","message":"Tere!"}' | jq .
```
