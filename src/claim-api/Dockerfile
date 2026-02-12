FROM node:20-alpine

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY . .
RUN addgroup -g 1001 app && adduser -S -u 1001 -G app app
USER 1001

EXPOSE 3000
CMD ["npm", "start"]
