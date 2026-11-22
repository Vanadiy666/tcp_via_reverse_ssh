# TCP через reverse SSH

Server подключается по SSH к Client. Запрос к `Client:18080` попадает в приложение на Server.
На обоих узлах нужны Docker и Docker Compose v2.

## Настройка и запуск

1. Скопируйте `client/` на Client, `server/` на Server.
2. В соответствующей папке **на каждом узле** выполните:

   ```bash
   cp .env-example .env
   docker compose run --rm keygen
   ```

   Команда создаст ключ в `./keys` и выведет его публичную часть.

3. Заполните `.env`:

   | Файл | Переменная | Значение |
   |---|---|---|
   | `client/.env` | `SERVER_PUBLIC_KEY` | Публичный ключ с Server |
   | `server/.env` | `CLIENT_HOST_PUBLIC_KEY` | Публичный ключ с Client |
   | `server/.env` | `CLIENT_ADDRESS` | Доступный с Server DNS-адрес или IPv4 Client |

   Также задайте `TARGET_HOST` и `TARGET_PORT` в `server/.env` — адрес и порт вашего приложения (см. ниже).

   Ключи вставляйте целиком: `"ssh-ed25519 AAAA..."`. Приватные ключи не переносите.

4. На каждом узле запустите:

   ```bash
   docker compose up -d
   ```

5. Обращайтесь к `<адрес-Client>:18080` по протоколу вашего приложения.
   На Client должны быть доступны TCP-порт `2222` для Server и `18080` для ваших запросов.

## Своё приложение

В `server/.env` задайте `TARGET_HOST` и `TARGET_PORT`:

- **Контейнер:** имя сервиса и его порт, например `backend` и `8080`.
  Приложение и `tunnel` должны быть в общей Docker-сети.
- **Хост Server:** `host.docker.internal` и порт приложения.
  На Linux приложение должно слушать адрес, доступный из Docker, а не только `127.0.0.1`.

## Порты и обслуживание

- Внешний порт приложения: `FORWARD_PORT` в `client/.env`.
- Доступ только с самого Client: `FORWARD_BIND_ADDRESS=127.0.0.1` (по умолчанию — все интерфейсы).
- При смене `SSH_PORT` на Client обновите `CLIENT_SSH_PORT` на Server.
- После изменения `.env`: `docker compose up -d`.
- Логи: `docker compose logs -f`.
- Остановка: `docker compose down`.

Ключи и состояние хранятся в папках `keys/` и `client/config/`. Не удаляйте их и не публикуйте.
