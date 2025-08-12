# Настройка MongoDB Sharding с репликацией

## 1. Запуск кластера
```bash
docker compose up -d
```
## 2. Инициализация Config Server
```
bash
docker exec -it configSrv mongosh --port 27017 --eval 'rs.initiate({
  _id: "config_server",
  configsvr: true,
  members: [{ _id: 0, host: "configSrv:27017" }]
})'
```

## 3. Настройка репликации для шардов
Для Shard1:
```
bash
docker exec -it shard1_1 mongosh --port 27021 --eval 'rs.initiate({
  _id: "shard1",
  members: [
    { _id: 0, host: "shard1_1:27021", priority: 2 },
    { _id: 1, host: "shard1_2:27022", priority: 1 },
    { _id: 2, host: "shard1_3:27023", priority: 1 }
  ]
})'
```

Для Shard2:
```
bash
docker exec -it shard2_1 mongosh --port 27031 --eval 'rs.initiate({
  _id: "shard2",
  members: [
    { _id: 0, host: "shard2_1:27031", priority: 2 },
    { _id: 1, host: "shard2_2:27032", priority: 1 },
    { _id: 2, host: "shard2_3:27033", priority: 1 }
  ]
})'
```
## 4. Настройка Mongos Router
```
bash
docker exec -it mongos_router mongosh --port 27020 --eval '
sh.addShard("shard1/shard1_1:27021,shard1_2:27022,shard1_3:27023");
sh.addShard("shard2/shard2_1:27031,shard2_2:27032,shard2_3:27033");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "_id": "hashed" })'
```

## 5. Генерация тестовых данных
```
bash
docker exec -it mongos_router mongosh --port 27020 somedb --eval '
for (let i = 0; i < 1000; i++) {
  db.helloDoc.insertOne({
    name: "user_" + i,
    value: Math.floor(Math.random() * 1000),
    createdAt: new Date()
  })
}'
```

Проверка работы
Статус репликации Shard1:
```
bash
docker exec -it shard1_1 mongosh --port 27021 --eval 'rs.status()'
```

Статус репликации Shard2:
```
bash
docker exec -it shard2_1 mongosh --port 27031 --eval 'rs.status()'
```
Проверка распределения данных:
```
bash
curl http://localhost:8080/stats
```