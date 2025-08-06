# Use official Node.js Alpine image
FROM node:22.0-alpine AS Base

# Set working directory
WORKDIR /app

# Copy dependency files and tsconfig
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm install

# Copy all source code
COPY . .

# ✅ Create necessary directories for file uploads (including /tmp/tmp/products)
RUN mkdir -p \
    /tmp/user \
    /tmp/products \
    /tmp/description-blocks \
    /tmp/reviews \
    /app/uploads \
    /tmp/tmp/products \
    && chmod -R 755 /tmp /app/uploads

# Compile TypeScript to JavaScript
RUN npm run build

# Expose backend port
EXPOSE 5000

# Start server
CMD ["npm", "start"]
