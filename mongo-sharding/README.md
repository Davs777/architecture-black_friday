# Настройка шардированного кластера MongoDB

## Описание архитектуры

Проект разворачивает шардированный кластер MongoDB со следующей структурой:

- **Config Server** (`configSrv:27017`) - сервер конфигурации
- **Mongos Router** (`mongos_router:27020`) - маршрутизатор запросов
- **Шарды**:
  - `shard1:27018`
  - `shard2:27019`
- **API сервис** (`pymongo_api:8080`) - приложение для работы с БД

Основные компоненты:
- База данных: `somedb`
- Коллекция: `helloDoc`

## Быстрый старт

1. Соберите и запустите сервисы:
```bash
docker-compose up -d --build
```

2. Инициализация Config Server
```shell
docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate({
  _id: "config_server",
  configsvr: true,
  members: [{ _id: 0, host: "configSrv:27017" }]
});
EOF
```

3. Инициализация шардов
```
Shard 1:
shell
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
rs.initiate({
  _id: "shard1",
  members: [{ _id: 0, host: "shard1:27018" }]
});
EOF
```
```
Shard 2:
shell
docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
rs.initiate({
  _id: "shard2",
  members: [{ _id: 1, host: "shard2:27019" }]
});
EOF
```



4. Настройка Mongos Router
```
shell
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard("shard1/shard1:27018");
sh.addShard("shard2/shard2:27019");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name": "hashed" });
EOF
```
