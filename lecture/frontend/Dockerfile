# --- बिल्ड का चरण ---
FROM node:22-slim AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .
RUN npm run build

# --- चलाने का चरण ---
# nginx की हल्की इमेज से बिल्ड की गई स्थिर फ़ाइलें सर्व करें.
FROM nginx:alpine AS runner

# केवल vite के बिल्ड परिणाम (dist) को nginx की सार्वजनिक डायरेक्टरी में रखें.
COPY --from=builder /app/dist /usr/share/nginx/html

# /app/api को backend कंटेनर पर रिवर्स प्रॉक्सी करने की सेटिंग
COPY nginx.conf /etc/nginx/conf.d/default.conf

# पोर्ट 80 पर अनुरोध सुनें (nginx इमेज की डिफ़ॉल्ट सेटिंग).
EXPOSE 80
