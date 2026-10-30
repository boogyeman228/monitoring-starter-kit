# Monitoring Starter Kit

[English](README.md) | [Русский](README.ru.md)

Мониторинг доступности сайтов и серверов с **уведомлениями в Telegram** одной командой `docker compose up`. Стек: Prometheus, Blackbox Exporter, Alertmanager, Grafana. Достаточно лёгкий для VPS за $5.

- Проверка HTTP(S) и ping (ICMP) каждые 30 секунд
- Алерты в Telegram: сайт недоступен, медленный ответ, скоро истекает SSL-сертификат, нестабильная работа (flapping)
- К каждому алерту есть ссылка на краткий runbook (`runbooks/`) с первыми шагами диагностики
- Готовый дашборд Grafana: статус, время ответа, дней до окончания SSL, uptime за 24ч / 7д
- Наружу открыт только Grafana

<!-- TODO: добавить реальный скриншот дашборда в docs/dashboard.png -->

## Быстрый старт (5 минут)

Нужен VPS с Docker Engine и плагином Compose.

```bash
git clone https://github.com/boogyeman228/monitoring-starter-kit.git
cd monitoring-starter-kit

cp .env.example .env
# впишите токен и chat id Telegram и надёжный пароль Grafana

# только если сделали форк: ссылки на runbooks — на ваш форк
# sed -i 's/boogyeman228/<ваш-github-логин>/' prometheus/alerts.yml

./scripts/add-target.sh https://your-site.com   # затем удалите example.com из targets/http.yml
docker compose up -d
```

Откройте `http://<ip-сервера>:3000`, войдите с данными из `.env` и откройте дашборд **Website Uptime & SSL**.

Проверка алертов: добавьте несуществующий адрес (`./scripts/add-target.sh https://does-not-exist.invalid`), через ~3 минуты придёт `EndpointDown`. Потом удалите строку из `targets/http.yml`.

## Telegram-бот и chat_id

1. В Telegram откройте [@BotFather](https://t.me/BotFather), отправьте `/newbot`, скопируйте **токен** в `TELEGRAM_BOT_TOKEN`.
2. Напишите вашему боту любое сообщение (для группы: добавьте бота в группу и напишите в ней).
3. Откройте в браузере `https://api.telegram.org/bot<ТОКЕН>/getUpdates`.
4. Найдите `"chat":{"id": ...}` - это `TELEGRAM_CHAT_ID` (у групп он отрицательный, например `-1001234567890`).

Токен храните в секрете и не коммитьте `.env`.

## Добавление сайтов

```bash
./scripts/add-target.sh https://shop.example.com        # Linux / macOS / Git Bash
.\scripts\add-target.ps1 https://shop.example.com        # Windows PowerShell
```

Prometheus перечитывает `targets/http.yml` раз в минуту, перезапуск не нужен. Ping-цели - в `targets/icmp.yml`. После правки `alerts.yml`: `docker compose kill -s SIGHUP prometheus`.

## Проверка конфигурации

Команды `promtool` / `amtool` через `docker run` приведены в английском README (раздел "Validate the configuration").

## Безопасность

- **Смените пароль Grafana** в `.env` до первого запуска (потом - через интерфейс или `grafana cli admin reset-admin-password`).
- Настройте файрвол (например, ufw: разрешить 22 и 3000). Docker обходит правила ufw для опубликованных портов - надёжнее задать `GRAFANA_BIND=127.0.0.1` и поставить перед Grafana reverse proxy с HTTPS (Caddy, nginx) либо ограничить доступ файрволом провайдера.
- У Prometheus, Alertmanager и Blackbox нет авторизации и нет открытых портов - так и должно оставаться.
- Не коммитьте `.env`.

## Стоимость

VPS 1 vCPU / 1 ГБ - около $4-6 в месяц; домен для HTTPS (по желанию) - около $10-15 в год; Telegram-бот бесплатен. Лимит памяти контейнеров - около 700 МБ суммарно; на 1 ГБ VPS добавьте swap 1-2 ГБ. Данные хранятся 30 дней.

## Нужна помощь с настройкой?

Настрою мониторинг под ключ: сервер, цели, алерты в Telegram/e-mail, дашборды и документация.

- Контакт: [LinkedIn](https://www.linkedin.com/in/bogdansalvador)

## Лицензия

MIT - см. [LICENSE](LICENSE).
