PROJECT_DOMAIN := $(or $(shell if [ -f .env ]; then grep -E '^PROJECT_DOMAIN=' .env | tail -n 1 | cut -d '=' -f2- | tr -d '"' | tr -d "'" | tr -d '\r'; fi),localhost)

.PHONY: up build down restart ps logs nginx-test cert check-https clear-cache fix-perms post-up-cert

up:
	docker compose up -d
	$(MAKE) post-up-cert

build:
	docker compose up -d --build
	$(MAKE) post-up-cert

down:
	docker compose down

restart:
	docker compose restart
	$(MAKE) post-up-cert

ps:
	docker compose ps

logs:
	docker compose logs -f

nginx-test:
	docker compose exec nginx nginx -t

cert:
	bash docker/scripts/install-mkcert-ca-to-php.sh

check-https:
	docker compose exec php php -d display_errors=1 -r "\$$fp=@fsockopen('ssl://$(PROJECT_DOMAIN)',443,\$$e,\$$s,10); var_dump((bool)\$$fp,\$$e,\$$s);"

clear-cache:
	docker compose exec php sh -lc 'rm -rf /var/www/html/bitrix/cache/css/* /var/www/html/bitrix/cache/js/* /var/www/html/bitrix/managed_cache/* /var/www/html/bitrix/stack_cache/* /var/www/html/bitrix/html_pages/* && echo OK'

fix-perms:
	bash docker/scripts/fix-install-permissions.sh

post-up-cert:
	@if [ -f docker/scripts/install-mkcert-ca-to-php.sh ]; then \
		bash docker/scripts/install-mkcert-ca-to-php.sh || \
		echo "mkcert CA was not installed. Run make cert after generating certificates."; \
	fi