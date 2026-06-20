```text
tien@LAPTOP-TUJDR4JT:~/work/devops-training-lehoangtien$ curl -v https://example.com
*   Trying 172.66.147.243:443...
* Connected to example.com (172.66.147.243) port 443 (#0) 
* ALPN, offering h2
* ALPN, offering http/1.1
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: /etc/ssl/certs
* TLSv1.0 (OUT), TLS header, Certificate Status (22):
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS header, Certificate Status (22):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS header, Finished (20):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.2 (OUT), TLS header, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: CN=example.com
*  start date: May 31 21:39:12 2026 GMT
*  expire date: Aug 29 21:41:26 2026 GMT
*  subjectAltName: host "example.com" matched cert's "example.com"
*  issuer: C=US; O=SSL Corporation; CN=Cloudflare TLS Issuing ECC CA 3
*  SSL certificate verify ok.
* Using HTTP2, server supports multiplexing
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
* Using Stream ID: 1 (easy handle 0x5ce914425a30)
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
> GET / HTTP/2
> Host: example.com
> user-agent: curl/7.81.0
> accept: */*
> 
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
< HTTP/2 200 
< date: Sat, 20 Jun 2026 03:30:03 GMT
< content-type: text/html
< server: cloudflare
< last-modified: Fri, 19 Jun 2026 18:46:03 GMT
< allow: GET, HEAD
< accept-ranges: bytes
< age: 10634
< cf-cache-status: HIT
< cf-ray: a0e7b156f9b60470-HKG
< 
* TLSv1.2 (IN), TLS header, Supplemental data (23):
<!doctype html><html lang="en"><head><title>Example Domain</title><link rel="icon" href="data:,"><meta name="viewport" content="width=device-width, initial-scale=1"><style>body{background:#eee;width:60vw;margin:15vh auto;font-family:system-ui,sans-serif}h1{font-size:1.5em}div{opacity:0.8}a:link,a:visited{color:#348}</style></head><body><div><h1>Example Domain</h1><p>This domain is for use in documentation examples without needing permission. Avoid use in operations.</p><p><a href="https://iana.org/domains/example">Learn more</a></p></div></body></html>
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* Connection #0 to host example.com left intact
```

DNS resolution: 
*   Trying 172.66.147.243:443...
* Connected to example.com (172.66.147.243) port 443 (#0) 

TCP connect: * Connected to example.com (172.66.147.243) port 443 (#0) 

TLS handshake: Từ ALPN, offering h2 ---> SSL certificate verify ok.

HTTP request: > GET / HTTP/2 ------> > accept: */*

response headers: < HTTP/2 200 ------> < cf-ray: a0e7b156f9b60470-HKG

```text
Client                                Server
  |                                     |
  | ------ Client Hello --------------> | (Chứa: Cipher Suites hỗ trợ, 
  |        Key Share (Client)           |  Key Share dự đoán trước)
  |                                     |
  | <----- Server Hello --------------- | (Chọn Cipher Suite, 
  |        Key Share (Server)           |  Gửi Key Share của Server)
  | <----- Encrypted Extensions ------- | (Các tham số mở rộng được mã hóa)
  | <----- Certificate ---------------- | (Chứng chỉ số của Server)
  | <----- Certificate Verify --------- | (Chữ ký số để xác thực Cert)
  | <----- Finished ------------------- | (Kết thúc phía Server)
  |                                     |
  | ------ Finished ------------------> | (Kết thúc phía Client)
  |                                     |
  v       [Kênh dữ liệu đã được mã hóa]  v

SNI (Server Name Indication): Giúp Client gửi tên miền muốn truy cập ngay trong gói tin mở đầu (Client Hello), cho phép một địa chỉ IP chạy nhiều website với các chứng chỉ SSL/TLS khác nhau.

ALPN (Application-Layer Protocol Negotiation): Cho phép Client và Server thỏa thuận phiên bản giao thức ứng dụng (HTTP/1.1, HTTP/2, HTTP/3) ngay khi bắt tay TLS để tiết kiệm thời gian kết nối.

OCSP (Online Certificate Status Protocol): Giao thức giúp trình duyệt truy vấn trực tiếp máy chủ của bên cấp phát (CA) để kiểm tra xem chứng chỉ số còn hiệu lực hay đã bị thu hồi.

SAN (Subject Alternative Name): Trường mở rộng trong chứng chỉ số TLS cho phép một chứng chỉ duy nhất bảo mật hợp pháp cho nhiều tên miền hoặc subdomain khác nhau. Ví dụ: một cert áp dụng được cho cả example.com, [www.example.com](https://www.example.com), m.example.com và example.net.