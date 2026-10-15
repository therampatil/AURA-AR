# Node.js LTS lightweight container for WebAR Server
FROM node:20-alpine

WORKDIR /app

# Install dependencies first for Docker caching
COPY package*.json ./
RUN npm ci --only=production

# Copy application files
COPY . .

# Ensure storage directories exist
RUN mkdir -p uploads public/models

EXPOSE 8080

ENV PORT=8080
ENV NODE_ENV=production

CMD ["node", "server.js"]
