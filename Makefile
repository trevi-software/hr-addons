UID = "$(shell id -u)"
GID = "$(shell id -g $$USER)"
UMASK = "$(shell umask)"

init:
	chmod -R ug+rwX odoo/auto
	touch init

build: init
	export UID=$(UID) GID=$(GID) UMASK=$(UMASK); \
	docker-compose -f $(YML) build --pull; \
	touch build

setup-devel: build
	export UID=$(UID) GID=$(GID) UMASK=$(UMASK); \
	docker-compose -f setup-devel.yaml run --rm odoo; \
	touch setup-devel

initdb: setup-devel
	export UID=$(UID) GID=$(GID) UMASK=$(UMASK); \
	docker-compose -f $(YML) run --rm odoo odoo -i base --stop-after-init; \
	touch initdb

run: setup-devel initdb
	export UID=$(UID) GID=$(GID) UMASK=$(UMASK); \
	docker-compose -f $(YML) up

initprod:
	export UID=$(UID) GID=$(GID) UMASK=$(UMASK); \
	docker-compose -f prod.yaml run --rm odoo odoo -i base,trevi_et --stop-after-init
	touch initprod

prod: initprod
	export UID=$(UID) GID=$(GID) UMASK=$(UMASK); \
	docker-compose -f prod.yaml up

stop:
	export UID=$(UID) GID=$(GID) UMASK=$(UMASK); \
	docker-compose -f $(YML) down

restart:
	export UID=$(UID) GID=$(GID) UMASK=$(UMASK)
	docker-compose -f $(YML) restart odoo odoo_proxy

update:
	export UID=$(UID) GID=$(GID) UMASK=$(UMASK)
	docker-compose -f $(YML) run --rm odoo addons update -w $(ADDONS)
	docker-compose -f $(YML) restart odoo odoo_proxy`

test:
	export UID=$(UID) GID=$(GID) UMASK=$(UMASK)
	docker-compose -f $(YML) run --rm odoo odoo --stop-after-init --init $(ADDONS)
	docker-compose -f $(YML) run --rm odoo unittest $(ADDONS) --log-level=error

clean:
	rm init build setup-devel initdb initprod

start-proxy:
	docker-compose -p reverseproxy -f reverseproxy.yaml up

stop-proxy:
	docker-compose -p reverseproxy -f reverseproxy.yaml down -v

docker:
	sudo apt update
	sudo apt remove docker docker-engine docker.io containerd runc
	sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(shell lsb_release -cs) stable"
	sudo apt install docker-ce docker-ce-cli containerd.io
	sudo docker run hello-world

docker-compose:
	sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(shell uname -s)-$(shell uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
	sudo docker-compose -v
