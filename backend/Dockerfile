# Orquestador MelodAI — Cloud Run / Render / cualquier host con Node 20
FROM node:20-alpine

WORKDIR /app

ENV NODE_ENV=production

COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY src ./src

# Cloud Run inyecta PORT (p. ej. 8080)
EXPOSE 8080

CMD ["node", "--use-system-ca", "src/index.js"]
