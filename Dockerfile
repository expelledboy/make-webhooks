FROM alpine:3.9 as build

RUN apk add --no-cache make nodejs npm

WORKDIR /root
COPY package*.json ./
RUN npm set progress=false && npm config set depth 0
RUN npm install --only=production

COPY src /root/src
EXPOSE 3000
CMD ["npm", "start"]
