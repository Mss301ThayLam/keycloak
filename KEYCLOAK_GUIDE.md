# Hướng Dẫn Sử Dụng Keycloak cho Dự Án Microservice

> Tài liệu này được biên soạn dựa trên repo keycloak của dự án **PC Components Store**, giúp toàn bộ team hiểu và áp dụng Keycloak vào hệ thống microservice một cách hiệu quả.

---

## Mục Lục

1. [Keycloak là gì?](#1-keycloak-là-gì)
2. [Các Khái Niệm Cốt Lõi](#2-các-khái-niệm-cốt-lõi)
3. [Kiến Trúc Hệ Thống](#3-kiến-trúc-hệ-thống)
4. [Cài Đặt và Khởi Chạy](#4-cài-đặt-và-khởi-chạy)
5. [Cấu Hình Realm](#5-cấu-hình-realm)
6. [Quản Lý Client (Ứng Dụng)](#6-quản-lý-client-ứng-dụng)
7. [Quản Lý Users, Roles và Groups](#7-quản-lý-users-roles-và-groups)
8. [Luồng Xác Thực (Authentication Flows)](#8-luồng-xác-thực-authentication-flows)
9. [Tích Hợp vào Microservice](#9-tích-hợp-vào-microservice)
10. [Custom Theme (Giao Diện Tùy Chỉnh)](#10-custom-theme-giao-diện-tùy-chỉnh)
11. [Social Login (Google, Facebook)](#11-social-login-google-facebook)
12. [Bảo Mật và Best Practices](#12-bảo-mật-và-best-practices)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Keycloak là gì?

**Keycloak** là một giải pháp **Identity and Access Management (IAM)** mã nguồn mở do Red Hat phát triển. Nó cung cấp:

- **Single Sign-On (SSO)**: Đăng nhập một lần, sử dụng được tất cả ứng dụng
- **Xác thực tập trung**: Quản lý toàn bộ logic đăng nhập tại một nơi
- **Phân quyền (Authorization)**: Kiểm soát ai được truy cập vào tài nguyên nào
- **Hỗ trợ chuẩn mở**: OAuth 2.0, OpenID Connect (OIDC), SAML 2.0

### Tại sao dùng Keycloak cho Microservice?

Trong kiến trúc microservice, mỗi service đều cần xác thực và phân quyền. Nếu không có Keycloak:

```
❌ Không dùng Keycloak:
User → Service A (tự xử lý login)
User → Service B (tự xử lý login riêng)
User → Service C (tự xử lý login riêng)
→ Logic trùng lặp, khó bảo trì, bảo mật không đồng nhất
```

```
✅ Dùng Keycloak:
User → Keycloak (đăng nhập 1 lần)
     ↓ nhận JWT Token
User → Service A (verify token)
User → Service B (verify token)
User → Service C (verify token)
→ Tập trung, nhất quán, bảo mật cao
```

---

## 2. Các Khái Niệm Cốt Lõi

### 2.1 Realm

**Realm** là không gian làm việc độc lập trong Keycloak, giống như một "tenant" hoặc "organization".

```
Keycloak Instance
├── master realm (realm quản trị hệ thống)
├── micropc realm (realm cho PC Components Store)
│   ├── Users
│   ├── Clients
│   ├── Roles
│   └── Groups
└── another-project realm (realm cho project khác - hoàn toàn tách biệt)
```

**Nguyên tắc:**
- Mỗi dự án nên có **1 realm riêng**
- Realm `master` chỉ dùng để quản trị Keycloak, **không** dùng cho ứng dụng
- Dữ liệu giữa các realm hoàn toàn tách biệt

### 2.2 Client

**Client** là ứng dụng hoặc service đăng ký với Keycloak để sử dụng dịch vụ xác thực.

| Loại Client | Mô tả | Ví dụ |
|-------------|-------|-------|
| **Public** | Không có client secret, dùng cho frontend | React app, Mobile app |
| **Confidential** | Có client secret, dùng cho backend | Spring Boot API, Node.js service |
| **Bearer-only** | Chỉ verify token, không thực hiện login | Microservice nội bộ |

### 2.3 Token

Keycloak sử dụng **JWT (JSON Web Token)** với 3 loại token:

```
Access Token  → Dùng để truy cập API (thời hạn ngắn: 5-15 phút)
Refresh Token → Dùng để lấy Access Token mới (thời hạn dài: 30 phút - vài ngày)
ID Token      → Chứa thông tin user (dùng trong OIDC)
```

**Cấu trúc JWT:**
```
Header.Payload.Signature
eyJhbGc...  .eyJ1c2Vy... .signature
```

Payload chứa các **claims** (thông tin):
```json
{
  "sub": "user-id-123",
  "name": "Nguyen Van A",
  "email": "a@example.com",
  "realm_access": {
    "roles": ["user", "admin"]
  },
  "resource_access": {
    "my-app": {
      "roles": ["product-manager"]
    }
  },
  "exp": 1710000000,
  "iat": 1709996400
}
```

### 2.4 Roles

**Role** định nghĩa quyền hạn trong hệ thống. Có 2 loại:

**Realm Roles** - Áp dụng toàn bộ realm:
```
realm_access.roles: ["user", "admin", "moderator"]
```

**Client Roles** - Áp dụng cho từng client cụ thể:
```
resource_access.my-app.roles: ["product-manager", "order-viewer"]
```

**Composite Roles** - Role tổng hợp gồm nhiều role khác:
```
"super-admin" = "admin" + "moderator" + "product-manager"
```

### 2.5 Groups

**Group** là tập hợp user, dùng để gán role hàng loạt:
```
Groups/
├── Customers
│   └── Roles: [user]
├── Staff
│   └── Roles: [user, staff]
└── Admins
    └── Roles: [user, staff, admin]
```

### 2.6 Identity Provider (IdP)

**Identity Provider** cho phép đăng nhập bằng tài khoản bên ngoài (Google, Facebook, v.v.). Keycloak đóng vai trò **broker** kết nối với các IdP.

```
User → Click "Login with Google"
     → Keycloak chuyển hướng sang Google
     → Google xác thực user
     → Google trả về token cho Keycloak
     → Keycloak tạo/liên kết user trong realm
     → Keycloak trả JWT cho ứng dụng
```

### 2.7 Authentication Flows

**Authentication Flow** định nghĩa các bước xác thực. Ví dụ flow đăng nhập thông thường:
```
1. User nhập username/password
2. Kiểm tra credentials
3. (Tùy chọn) Xác thực 2 yếu tố (OTP)
4. Tạo session và cấp token
```

---

## 3. Kiến Trúc Hệ Thống

### Kiến trúc trong repo này

```
Internet
    │
    ▼
┌─────────────────────────────────────────┐
│           Nginx (Port 80/443)           │
│   • SSL/TLS Termination                 │
│   • HTTP → HTTPS Redirect               │
│   • Reverse Proxy                       │
│   Domain: micropc-keycloak.duckdns.org  │
└─────────────────┬───────────────────────┘
                  │ http://keycloak:8080
                  ▼
┌─────────────────────────────────────────┐
│         Keycloak v26.0 (Port 8080)      │
│   • Identity Provider                   │
│   • Admin Console                       │
│   • Custom Theme: MicroPC               │
└─────────────────┬───────────────────────┘
                  │ JDBC
                  ▼
┌─────────────────────────────────────────┐
│       PostgreSQL 16 (Port 5432)         │
│   • Lưu trữ Users, Realms, Clients      │
│   • Persistent Volume: kc_pgdata        │
└─────────────────────────────────────────┘
```

### Kiến trúc tích hợp Microservice

```
                    ┌─────────────────┐
                    │    Keycloak     │
                    │   (Auth Server) │
                    └────────┬────────┘
                             │ JWT Token
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
┌─────────────────┐ ┌──────────────┐ ┌──────────────┐
│  Frontend App   │ │ API Gateway  │ │ Microservice │
│  (React/Vue)    │ │ (Verify JWT) │ │   (Verify)   │
└─────────────────┘ └──────┬───────┘ └──────────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
    ┌─────────────┐ ┌───────────┐ ┌───────────┐
    │  User Svc   │ │Product Svc│ │ Order Svc │
    │(bearer-only)│ │(bearer-   │ │(bearer-   │
    │             │ │  only)    │ │  only)    │
    └─────────────┘ └───────────┘ └───────────┘
```

---

## 4. Cài Đặt và Khởi Chạy

### Yêu cầu hệ thống

- Docker >= 20.10
- Docker Compose >= 2.0
- 2GB RAM tối thiểu (khuyến nghị 4GB)

### Bước 1: Clone và chuẩn bị

```bash
git clone <repo-url>
cd keycloak
```

### Bước 2: Chuẩn bị SSL Certificate

Nginx yêu cầu `ssl/cert.pem` và `ssl/key.pem`. Để test local, tạo self-signed certificate:

```bash
# Tạo thư mục ssl nếu chưa có
mkdir -p ssl

# Tạo self-signed certificate (cho môi trường dev/test)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/key.pem \
  -out ssl/cert.pem \
  -subj "/CN=micropc-keycloak.duckdns.org"
```

> **Production**: Dùng Let's Encrypt với Certbot để có certificate miễn phí và được tin cậy.

### Bước 3: Khởi chạy

```bash
# Khởi chạy toàn bộ stack
docker compose up -d

# Xem logs
docker compose logs -f

# Xem logs riêng từng service
docker compose logs -f keycloak
docker compose logs -f nginx
docker compose logs -f kc-postgres
```

### Bước 4: Truy cập Admin Console

```
URL: https://micropc-keycloak.duckdns.org/admin
     (hoặc http://localhost:8080/admin nếu test local)

Username: admin
Password: admin123
```

> **Lưu ý bảo mật**: Đổi password admin ngay sau lần đăng nhập đầu tiên trong môi trường production!

### Bước 5: Kiểm tra health

```bash
# Kiểm tra Keycloak đang chạy
curl http://localhost:8080/health

# Kiểm tra OIDC Discovery endpoint
curl http://localhost:8080/realms/master/.well-known/openid-configuration
```

### Quản lý Container

```bash
# Dừng tất cả services
docker compose down

# Dừng và xóa volumes (XÓA TOÀN BỘ DỮ LIỆU)
docker compose down -v

# Restart Keycloak sau khi thay đổi theme
docker compose restart keycloak

# Xem trạng thái containers
docker compose ps
```

---

## 5. Cấu Hình Realm

### Tạo Realm mới cho dự án

1. Đăng nhập Admin Console
2. Click menu dropdown ở góc trên trái (đang hiển thị "master")
3. Click **"Create Realm"**
4. Điền thông tin:
   - **Realm name**: `micropc` (hoặc tên dự án của bạn)
   - **Display name**: `PC Components Store`
   - **Enabled**: ON

### Cấu hình Realm Settings quan trọng

**Tab General:**
```
Realm name: micropc
Display name: PC Components Store
Frontend URL: https://micropc-keycloak.duckdns.org/realms/micropc
```

**Tab Login:**
```
✅ User registration      → Cho phép user tự đăng ký
✅ Forgot password        → Cho phép reset mật khẩu
✅ Remember me            → Tính năng "nhớ đăng nhập"
✅ Email as username      → Dùng email thay vì username
✅ Login with email       → Đăng nhập bằng email
✅ Verify email           → Yêu cầu xác thực email
```

**Tab Email:**
Cấu hình SMTP để gửi email (xác thực, reset password):
```
Host: smtp.gmail.com
Port: 587
From: noreply@micropc.com
Enable StartTLS: ON
Username: your-email@gmail.com
Password: your-app-password
```

**Tab Tokens:**
```
Access Token Lifespan:          15 minutes
Refresh Token Lifespan:         30 minutes (hoặc lâu hơn tùy yêu cầu)
SSO Session Idle:               30 minutes
SSO Session Max:                10 hours
```

### OIDC Discovery Endpoint

Sau khi tạo realm, Keycloak tự động expose endpoint:
```
https://<keycloak-domain>/realms/<realm-name>/.well-known/openid-configuration
```

Endpoint này chứa tất cả URLs cần thiết để integrate:
```json
{
  "issuer": "https://micropc-keycloak.duckdns.org/realms/micropc",
  "authorization_endpoint": "https://.../realms/micropc/protocol/openid-connect/auth",
  "token_endpoint": "https://.../realms/micropc/protocol/openid-connect/token",
  "userinfo_endpoint": "https://.../realms/micropc/protocol/openid-connect/userinfo",
  "jwks_uri": "https://.../realms/micropc/protocol/openid-connect/certs"
}
```

---

## 6. Quản Lý Client (Ứng Dụng)

### Tạo Client cho Frontend (React/Vue)

1. Vào **Clients** → **Create client**
2. Điền thông tin:

```
Client type:       OpenID Connect
Client ID:         micropc-frontend
Name:              MicroPC Frontend App
```

3. Cấu hình:
```
Client authentication:  OFF  (Public client - không có secret)
Authorization:          OFF
Authentication flow:
  ✅ Standard flow       (Authorization Code Flow - dùng cho web app)
  ✅ Direct access grants (Cho phép dùng username/password trực tiếp)
```

4. **Valid redirect URIs** (quan trọng):
```
http://localhost:3000/*
https://micropc.duckdns.org/*
```

5. **Web origins** (CORS):
```
http://localhost:3000
https://micropc.duckdns.org
```

### Tạo Client cho Backend Service

```
Client type:       OpenID Connect
Client ID:         micropc-api-gateway
Client authentication: ON  (Confidential - có client secret)
Authorization:         ON  (Nếu cần fine-grained authorization)
Authentication flow:
  ✅ Standard flow
  ✅ Service accounts roles  (Cho phép machine-to-machine auth)
```

Sau khi tạo, vào tab **Credentials** để lấy **Client Secret**.

### Tạo Client cho Microservice nội bộ

```
Client type:           OpenID Connect
Client ID:             product-service
Client authentication: ON
Authentication flow:
  ✅ Bearer-only  (Chỉ verify token, không login)
```

> **Bearer-only** service không có trang login, chỉ nhận token từ request và verify.

### Lấy Token (Testing với curl)

**Authorization Code Flow (Frontend):**
```bash
# Bước 1: Lấy authorization code (thực hiện qua browser)
https://<keycloak>/realms/micropc/protocol/openid-connect/auth
  ?client_id=micropc-frontend
  &redirect_uri=http://localhost:3000/callback
  &response_type=code
  &scope=openid profile email

# Bước 2: Đổi code lấy token
curl -X POST \
  https://<keycloak>/realms/micropc/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "client_id=micropc-frontend" \
  -d "code=<authorization-code>" \
  -d "redirect_uri=http://localhost:3000/callback"
```

**Direct Access Grant (Testing/Development):**
```bash
curl -X POST \
  https://<keycloak>/realms/micropc/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=micropc-frontend" \
  -d "username=testuser@example.com" \
  -d "password=TestPass123!" \
  -d "scope=openid profile email"
```

**Client Credentials (Service-to-Service):**
```bash
curl -X POST \
  https://<keycloak>/realms/micropc/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=micropc-api-gateway" \
  -d "client_secret=<your-client-secret>"
```

---

## 7. Quản Lý Users, Roles và Groups

### Tạo Roles

**Tạo Realm Role:**
1. Vào **Realm roles** → **Create role**
2. Tạo các roles:
   - `user` - Khách hàng thông thường
   - `staff` - Nhân viên
   - `admin` - Quản trị viên

**Tạo Client Role:**
1. Vào **Clients** → chọn client → **Roles** → **Create role**
2. Tạo roles cụ thể cho từng service:
   - `product:read`, `product:write`, `product:delete`
   - `order:read`, `order:write`
   - `user:read`, `user:write`

### Tạo Groups

1. Vào **Groups** → **Create group**
2. Tạo cấu trúc:

```
Groups/
├── Customers
│   └── Role Mappings: [user]
├── Staff
│   └── Role Mappings: [user, staff]
└── Administrators
    └── Role Mappings: [user, staff, admin]
```

3. Cấu hình **Default Group**: Tất cả user đăng ký mới tự động vào group này
   - Vào **Realm Settings** → **User registration** → **Default groups**: `Customers`

### Tạo User thủ công

1. Vào **Users** → **Create new user**
2. Điền thông tin:
   ```
   Username: admin@micropc.com
   Email:    admin@micropc.com
   First name: Admin
   Last name:  User
   Email verified: ON
   ```
3. Tab **Credentials**: Set password
4. Tab **Role mapping**: Assign roles

### Quản lý User qua Admin API

```bash
# Lấy admin token
ADMIN_TOKEN=$(curl -s -X POST \
  http://localhost:8080/realms/master/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=admin-cli" \
  -d "username=admin" \
  -d "password=admin123" | jq -r '.access_token')

# Lấy danh sách users
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://localhost:8080/admin/realms/micropc/users

# Tạo user mới
curl -X POST \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  http://localhost:8080/admin/realms/micropc/users \
  -d '{
    "username": "newuser@example.com",
    "email": "newuser@example.com",
    "firstName": "New",
    "lastName": "User",
    "enabled": true,
    "emailVerified": true,
    "credentials": [{
      "type": "password",
      "value": "Password123!",
      "temporary": false
    }]
  }'
```

---

## 8. Luồng Xác Thực (Authentication Flows)

### Authorization Code Flow (Khuyến nghị cho Web App)

```
┌────────┐          ┌────────────┐          ┌──────────┐
│Frontend│          │  Keycloak  │          │  Browser │
└───┬────┘          └─────┬──────┘          └────┬─────┘
    │                     │                      │
    │ User clicks Login    │                      │
    │─────────────────────►│                      │
    │                     │ Redirect to Keycloak  │
    │◄────────────────────┤─────────────────────►│
    │                     │                      │ User nhập credentials
    │                     │◄─────────────────────┤
    │                     │ Verify credentials    │
    │                     │ Return auth code      │
    │                     │─────────────────────►│
    │                     │ Redirect + code       │
    │◄────────────────────┤◄─────────────────────┤
    │ Exchange code        │                      │
    │─────────────────────►│                      │
    │  JWT Tokens          │                      │
    │◄────────────────────┤                      │
```

### Refresh Token Flow

```javascript
// Khi access token hết hạn, dùng refresh token để lấy token mới
const response = await fetch('/realms/micropc/protocol/openid-connect/token', {
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  body: new URLSearchParams({
    grant_type: 'refresh_token',
    client_id: 'micropc-frontend',
    refresh_token: storedRefreshToken
  })
});
const { access_token, refresh_token } = await response.json();
```

### Logout

```bash
# Single Sign-Out (logout khỏi tất cả ứng dụng)
GET https://<keycloak>/realms/micropc/protocol/openid-connect/logout
  ?post_logout_redirect_uri=https://micropc.duckdns.org
  &id_token_hint=<id_token>

# Logout qua API (backchannel)
curl -X POST \
  https://<keycloak>/realms/micropc/protocol/openid-connect/logout \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=micropc-frontend" \
  -d "refresh_token=<refresh_token>"
```

---

## 9. Tích Hợp vào Microservice

### 9.1 Spring Boot Integration

**Thêm dependency:**
```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

**Cấu hình application.yml:**
```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://micropc-keycloak.duckdns.org/realms/micropc
          jwk-set-uri: https://micropc-keycloak.duckdns.org/realms/micropc/protocol/openid-connect/certs
```

**Security Config:**
```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/public/**").permitAll()
                .requestMatchers("/admin/**").hasRole("admin")
                .requestMatchers("/api/**").hasRole("user")
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthConverter()))
            );
        return http.build();
    }

    @Bean
    public JwtAuthenticationConverter jwtAuthConverter() {
        JwtGrantedAuthoritiesConverter converter = new JwtGrantedAuthoritiesConverter();
        // Đọc roles từ realm_access.roles trong JWT
        converter.setAuthoritiesClaimName("realm_access.roles");
        converter.setAuthorityPrefix("ROLE_");

        JwtAuthenticationConverter jwtConverter = new JwtAuthenticationConverter();
        jwtConverter.setJwtGrantedAuthoritiesConverter(converter);
        return jwtConverter;
    }
}
```

**Sử dụng trong Controller:**
```java
@RestController
@RequestMapping("/api/products")
public class ProductController {

    // Chỉ user có role "staff" mới xem được
    @GetMapping
    @PreAuthorize("hasRole('staff')")
    public List<Product> getProducts() { ... }

    // Chỉ admin mới xóa được
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('admin')")
    public void deleteProduct(@PathVariable Long id) { ... }

    // Lấy thông tin user từ JWT
    @GetMapping("/my-orders")
    public List<Order> getMyOrders(@AuthenticationPrincipal Jwt jwt) {
        String userId = jwt.getSubject();
        String email = jwt.getClaimAsString("email");
        return orderService.findByUserId(userId);
    }
}
```

### 9.2 Node.js / Express Integration

**Cài đặt packages:**
```bash
npm install express-jwt jwks-rsa
```

**Middleware xác thực:**
```javascript
// middleware/auth.js
const { expressjwt: jwt } = require('express-jwt');
const jwksRsa = require('jwks-rsa');

const KEYCLOAK_URL = 'https://micropc-keycloak.duckdns.org';
const REALM = 'micropc';

// Middleware kiểm tra JWT
const authenticate = jwt({
  secret: jwksRsa.expressJwtSecret({
    jwksUri: `${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/certs`
  }),
  audience: 'micropc-api-gateway',
  issuer: `${KEYCLOAK_URL}/realms/${REALM}`,
  algorithms: ['RS256']
});

// Middleware kiểm tra role
const requireRole = (role) => (req, res, next) => {
  const roles = req.auth?.realm_access?.roles || [];
  if (!roles.includes(role)) {
    return res.status(403).json({ error: 'Insufficient permissions' });
  }
  next();
};

module.exports = { authenticate, requireRole };
```

**Sử dụng trong routes:**
```javascript
const { authenticate, requireRole } = require('./middleware/auth');

// Route công khai
app.get('/public/products', getPublicProducts);

// Route cần đăng nhập
app.get('/api/products', authenticate, getProducts);

// Route cần role cụ thể
app.delete('/api/products/:id', authenticate, requireRole('admin'), deleteProduct);

// Lấy thông tin user
app.get('/api/profile', authenticate, (req, res) => {
  const { sub: userId, email, name } = req.auth;
  res.json({ userId, email, name });
});
```

### 9.3 API Gateway Pattern

Trong microservice, nên verify JWT tại **API Gateway**, các service downstream nhận thông tin user qua HTTP headers:

```javascript
// API Gateway middleware
app.use(async (req, res, next) => {
  try {
    // Verify JWT
    const token = req.headers.authorization?.split(' ')[1];
    const payload = await verifyJwt(token);

    // Inject user info vào headers cho downstream services
    req.headers['X-User-Id'] = payload.sub;
    req.headers['X-User-Email'] = payload.email;
    req.headers['X-User-Roles'] = JSON.stringify(payload.realm_access?.roles);

    next();
  } catch (error) {
    res.status(401).json({ error: 'Unauthorized' });
  }
});
```

### 9.4 Keycloak Admin SDK (quản lý users từ code)

```javascript
// Dùng keycloak-admin-client
const KcAdminClient = require('@keycloak/keycloak-admin-client').default;

const kcAdmin = new KcAdminClient({
  baseUrl: 'https://micropc-keycloak.duckdns.org',
  realmName: 'master'
});

// Authenticate
await kcAdmin.auth({
  username: 'admin',
  password: 'admin123',
  grantType: 'password',
  clientId: 'admin-cli'
});

kcAdmin.setConfig({ realmName: 'micropc' });

// Tạo user mới khi user đăng ký qua app riêng
await kcAdmin.users.create({
  username: email,
  email,
  firstName,
  lastName,
  enabled: true,
  emailVerified: false,
  credentials: [{ type: 'password', value: password, temporary: false }]
});
```

---

## 10. Custom Theme (Giao Diện Tùy Chỉnh)

Repo này đã có sẵn theme **MicroPC** với giao diện tùy chỉnh cho PC Components Store.

### Cấu trúc theme

```
themes/MicroPC/
├── theme.properties          # Khai báo theme, locales
└── login/                    # Module đăng nhập
    ├── theme.properties      # Khai báo parent theme, CSS
    ├── login.ftl             # Template trang đăng nhập
    ├── register.ftl          # Template trang đăng ký
    ├── login-reset-password.ftl  # Template quên mật khẩu
    ├── messages/
    │   ├── messages_en.properties  # Tiếng Anh
    │   └── messages_vi.properties  # Tiếng Việt
    └── resources/
        ├── css/styles.css    # CSS tùy chỉnh
        └── img/              # Logo, icons
```

### Kích hoạt theme

1. Vào **Realm Settings** → **Themes**
2. Đặt **Login theme**: `MicroPC`
3. Đặt **Account theme**: `keycloak` (hoặc tạo riêng)

### Phát triển theme

Theme đã được mount dưới dạng volume trong `docker-compose.yml`:
```yaml
volumes:
  - ./themes/MicroPC:/opt/keycloak/themes/MicroPC
```

Và cache đã được tắt để phát triển:
```yaml
environment:
  - KC_SPI_THEME_STATIC_MAX_AGE=-1
  - KC_SPI_THEME_CACHE_THEMES=false
  - KC_SPI_THEME_CACHE_TEMPLATES=false
```

→ Chỉnh sửa file CSS/FTL, **refresh browser** là thấy thay đổi ngay!

### Thêm ngôn ngữ mới

1. Tạo file `messages/messages_<locale>.properties`
2. Thêm locale vào `theme.properties`:
   ```
   locales=en,vi,fr
   ```
3. Trong Admin Console: **Realm Settings** → **Localization** → thêm locale

---

## 11. Social Login (Google, Facebook)

### Cấu hình Google OAuth

1. **Tạo OAuth App trên Google Cloud Console:**
   - Vào https://console.cloud.google.com
   - APIs & Services → Credentials → Create OAuth Client ID
   - Application type: Web application
   - Authorized redirect URIs:
     ```
     https://micropc-keycloak.duckdns.org/realms/micropc/broker/google/endpoint
     ```
   - Lưu **Client ID** và **Client Secret**

2. **Cấu hình trong Keycloak:**
   - Vào **Identity Providers** → **Add provider** → **Google**
   - Điền **Client ID** và **Client Secret** từ bước trên
   - **First login flow**: `first broker login`
   - **Sync mode**: `IMPORT`

3. **Cấu hình mapper** (tùy chọn):
   - Tự động gán role khi user đăng nhập lần đầu qua Google
   - Vào Identity Provider → **Mappers** → **Create**
   - Mapper type: `Hardcoded Role`
   - Role: `user`

### Cấu hình Facebook

Tương tự Google nhưng:
- Tạo app tại: https://developers.facebook.com
- Redirect URI:
  ```
  https://micropc-keycloak.duckdns.org/realms/micropc/broker/facebook/endpoint
  ```
- Trong Keycloak: **Identity Providers** → **Add provider** → **Facebook**

---

## 12. Bảo Mật và Best Practices

### Checklist Bảo Mật

**Môi trường Production:**
```
✅ Đổi mật khẩu admin mặc định
✅ Sử dụng HTTPS (đã có Nginx + SSL)
✅ Cấu hình đúng redirect URIs (không dùng wildcard *)
✅ Đặt token lifetime hợp lý (access: 5-15 phút)
✅ Bật brute force protection
✅ Cấu hình email verification
✅ Disable direct access grants nếu không cần
✅ Dùng client secrets đủ mạnh
✅ Không expose admin console ra ngoài internet
```

**Bật Brute Force Protection:**
1. **Realm Settings** → **Security defenses** → **Brute Force Detection**
2. Cấu hình:
   ```
   Enabled: ON
   Permanent Lockout: OFF
   Max Login Failures: 5
   Wait Increment: 30 seconds
   Max Wait: 900 seconds (15 phút)
   Failure Reset Time: 12 hours
   ```

**Giới hạn Redirect URIs (Bảo mật OAuth):**
```
❌ Xấu:   Valid Redirect URIs: *
✅ Tốt:   Valid Redirect URIs: https://micropc.duckdns.org/callback
                               https://micropc.duckdns.org/silent-check-sso.html
```

**Bảo vệ Admin Console:**
Thêm vào nginx.conf để chặn truy cập /admin từ ngoài:
```nginx
location /admin {
    allow 10.0.0.0/8;    # Chỉ cho phép internal network
    allow 192.168.0.0/16;
    deny all;
}
```

### Quản lý Secrets

**Không** commit secrets vào git. Dùng environment variables hoặc secret manager:

```bash
# .env file (KHÔNG commit file này)
KC_DB_PASSWORD=strong_random_password
KC_ADMIN_PASSWORD=another_strong_password
GOOGLE_CLIENT_SECRET=your_google_secret
```

```yaml
# docker-compose.yml - đọc từ .env
environment:
  - KC_DB_PASSWORD=${KC_DB_PASSWORD}
  - KEYCLOAK_ADMIN_PASSWORD=${KC_ADMIN_PASSWORD}
```

---

## 13. Troubleshooting

### Vấn đề thường gặp

**1. Không kết nối được Database**
```bash
# Kiểm tra postgres đang chạy
docker compose ps kc-postgres

# Xem logs postgres
docker compose logs kc-postgres

# Test kết nối
docker compose exec kc-postgres psql -U keycloak -d keycloak -c "\l"
```

**2. Theme không hiển thị**
```bash
# Kiểm tra theme đã mount đúng chưa
docker compose exec keycloak ls /opt/keycloak/themes/

# Restart Keycloak
docker compose restart keycloak

# Đảm bảo cache đã tắt trong docker-compose.yml
KC_SPI_THEME_CACHE_THEMES=false
KC_SPI_THEME_CACHE_TEMPLATES=false
```

**3. CORS Error khi gọi từ Frontend**
- Kiểm tra **Web Origins** trong Client settings
- Thêm đúng origin của frontend: `https://micropc.duckdns.org`
- Kiểm tra headers từ Nginx có `Access-Control-Allow-Origin` không

**4. JWT Token không hợp lệ (401 Unauthorized)**
```bash
# Decode JWT để kiểm tra (không cần secret)
echo "eyJ..." | cut -d'.' -f2 | base64 -d | python3 -m json.tool

# Kiểm tra issuer trong token có khớp với config không
# Token: "iss": "https://micropc-keycloak.duckdns.org/realms/micropc"
# Config: issuer-uri: https://micropc-keycloak.duckdns.org/realms/micropc
```

**5. Keycloak khởi động chậm**
```bash
# Keycloak v26 cần ~30-60s để khởi động
# Kiểm tra health
curl http://localhost:8080/health/ready

# Xem logs để biết trạng thái
docker compose logs -f keycloak | grep -E "(started|error|WARN)"
```

**6. SSL Certificate lỗi**
```bash
# Kiểm tra cert.pem tồn tại
ls -la ssl/

# Kiểm tra cert còn hạn
openssl x509 -in ssl/cert.pem -noout -dates

# Test HTTPS
curl -v https://micropc-keycloak.duckdns.org/health
```

### Logs hữu ích

```bash
# Tất cả logs
docker compose logs -f

# Chỉ xem errors
docker compose logs keycloak 2>&1 | grep -i "error\|exception\|fatal"

# Xem authentication events trong Admin Console
# Realm → Events → Login Events
```

---

## Tổng Kết

Với setup trong repo này, team có thể:

| Tính năng | Trạng thái |
|-----------|------------|
| Đăng nhập/Đăng ký | ✅ Sẵn sàng (custom theme MicroPC) |
| Quên mật khẩu | ✅ Sẵn sàng |
| Social Login | ✅ Cấu hình Google/Facebook |
| JWT Token | ✅ RS256, auto-rotate keys |
| HTTPS | ✅ Nginx + SSL |
| Đa ngôn ngữ | ✅ Tiếng Anh + Tiếng Việt |
| Microservice Integration | ✅ Spring Boot, Node.js |
| Admin Console | ✅ https://micropc-keycloak.duckdns.org/admin |

**Luồng tích hợp khuyến nghị:**
```
1. Frontend → Keycloak (Authorization Code Flow)
2. Frontend → API Gateway (Bearer JWT Token)
3. API Gateway → Microservices (X-User headers)
4. Microservices → Keycloak JWKS (Verify token signature)
```

---

*Tài liệu này được tạo cho dự án PC Components Store. Cập nhật lần cuối: 2026-03-14*
