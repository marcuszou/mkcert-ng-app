# Stage 1
FROM node:alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2
FROM nginx:alpine
COPY --from=builder /app/dist/my-ng-app/browser /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
COPY ./devcerts /etc/nginx/certs
EXPOSE 80