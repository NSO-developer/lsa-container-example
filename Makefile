ENABLED_SERVICES=UPPER LOWER-1 LOWER-2 BUILD-NSO-PKGS
LOWER_NODES_DIR := LOWER_1 LOWER_2
NETSIM_HOSTS := nso_lower_1 nso_lower_2

# Default NSO version and Architecture, Alternatively you can explicitly provide an Image version and an Architecture of your choice
# by calling make build VER=<NSO version> ARCH=<CPU Architecture>
VER=6.2.3
ARCH=x86_64

# Build preparation of running environment
build:
	# Load both images
	docker load -i ./images/nso-${VER}.container-image-dev.linux.${ARCH}.tar.gz
	docker load -i ./images/nso-${VER}.container-image-prod.linux.${ARCH}.tar.gz
	docker build -t mod-nso-prod:${VER}  --no-cache --network=host --build-arg type="prod"  --build-arg ver=${VER}  --file Dockerfile .
	docker build -t mod-nso-dev:${VER}  --no-cache --network=host --build-arg type="dev"  --build-arg ver=${VER} --file Dockerfile .

	# Create and build file structure for Upper NSO container
	docker run -d --name nso-prod -e ADMIN_USERNAME=admin -e ADMIN_PASSWORD=admin -e EXTRA_ARGS=--with-package-reload-force -v ./NSO-log-vols/UPPER:/log:Z mod-nso-prod:${VER}
	bash check_nso_status.sh
	docker exec nso-prod bash -c 'chmod 777 -R /nso/*'
	docker exec nso-prod bash -c 'chmod 777 -R /log/*'
	docker exec nso-prod rm -rf /nso/run/cdb
	docker exec nso-prod rm -rf /nso/run/state/packages-in-use
	docker exec nso-prod mkdir /nso/run/cdb
	docker cp nso-prod:/nso/ NSO-vol/UPPER
	
	# Build and Prepare Lower NSO containers (Lower1 and Lower2) 
	$(MAKE) $(LOWER_NODES_DIR)
	cp -r package-store/rfs-vlan NSO-vol/UPPER/run/packages/
	cp -r package-store/cfs-vlan NSO-vol/UPPER/run/packages/
	cp util/Makefile NSO-vol/UPPER/run/packages/
	docker container stop nso-prod && docker rm nso-prod
	sleep 2

	# Build dev container for making 
	docker run -d --name nso-dev -e ADMIN_USERNAME=admin -e ADMIN_PASSWORD=admin -v ./NSO-vol/UPPER/run/packages:/nso/UPPER/packages:Z -v ./NSO-vol/LOWER_1/run/packages:/nso/LOWER_1/packages:Z -v ./NSO-vol/LOWER_2/run/packages:/nso/LOWER_2/packages:Z  mod-nso-dev:${VER}
	docker exec nso-dev bash ncs-make-package --no-netsim --no-java --no-python --lsa-netconf-ned /nso/UPPER/packages/rfs-vlan/src/yang --dest /nso/UPPER/packages/rfs-vlan-ned --build rfs-vlan-ned
	$(MAKE) compile_packages
	docker exec nso-dev bash -c 'chmod 777 -R /nso/*'
	docker container stop nso-dev && docker rm nso-dev
	rm -rf ./NSO-vol/UPPER/run/packages/rfs-vlan
	sleep 2

	cp UPPER/ncs.conf NSO-vol/UPPER/etc/
	cp UPPER/ncs-cdb/devs.xml NSO-vol/UPPER/run/cdb/

# Internal use target for building file structure for Lower NSO Nodes 
.PHONY: LOWER_1 LOWER_2
$(LOWER_NODES_DIR):
	-mkdir NSO-vol/$@
	-mkdir NSO-log-vols/$@
	cp -R NSO-vol/UPPER/* NSO-vol/$@/
	cp $@/ncs.conf NSO-vol/$@/etc/
	cp $@/ncs-cdb/devs.xml NSO-vol/$@/run/cdb/
	cp -r package-store/rfs-vlan NSO-vol/$@/run/packages/
	cp -r package-store/router NSO-vol/$@/run/packages/
	cp util/Makefile NSO-vol/$@/run/packages/
	sleep 2

# Start Containers for all nodes with docker-compose service
start:
	export VER=${VER} ; docker-compose up ${ENABLED_SERVICES} -d
	bash check_status.sh
	docker exec nso_upper bash -c 'chmod 777 -R /nso/*'
	docker exec nso_upper bash -c 'chmod 777 -R /log/*'
	docker exec nso_lower_1 bash -c 'chmod 777 -R /nso/*'
	docker exec nso_lower_1 bash -c 'chmod 777 -R /log/*'
	docker exec nso_lower_2 bash -c 'chmod 777 -R /nso/*'
	docker exec nso_lower_2 bash -c 'chmod 777 -R /log/*'


	# Creating Netsim devices on Lower Nodes
	docker exec nso_lower_1 bash ncs-netsim create-network /nso/run/packages/router/ 3 ex --dir /nso/netsim
	docker exec nso_lower_2 bash ncs-netsim create-network /nso/run/packages/router/ 3 fx --dir /nso/netsim

	# Starting Netsim devices on both lower nodes
	$(MAKE) $(NETSIM_HOSTS)
	sleep 3

	# Running startup Scripts
	sh UPPER/init.sh
	sh LOWER_1/init.sh
	sh LOWER_2/init.sh
	sleep 3
	sh UPPER/sync_from_expl.sh

# Internal use target to start NETSIM networks ex and fx on Lower Nodes nso_lower_1 and nso_lower_2 respectively
.PHONY: nso_lower_1 nso_lower_2
$(NETSIM_HOSTS):
	docker exec $@ bash ncs-netsim start --dir /nso/netsim

# Stop the demonstration environment
stop:
	export VER=${VER} ;docker-compose down  ${ENABLED_SERVICES}

# Internal use Target to compile packages of all production nodes using nso-dev container 
compile_packages:
	docker exec -it nso-dev make all -C /nso/UPPER/packages
	docker exec -it nso-dev make all -C /nso/LOWER_1/packages
	docker exec -it nso-dev make all -C /nso/LOWER_2/packages

# CLI provisioning targets
cli-c_nso_upper:
	docker exec -it nso_upper ncs_cli -C -u admin

cli-j_nso_upper:
	docker exec -it nso_upper ncs_cli -J -u admin

cli-c_nso_lower_1:
	docker exec -it nso_lower_1 ncs_cli -C -u admin

cli-j_nso_lower_1:
	docker exec -it nso_lower_1 ncs_cli -J -u admin

cli-c_nso_lower_2:
	docker exec -it nso_lower_2 ncs_cli -C -u admin

cli-j_nso_lower_2:
	docker exec -it nso_lower_2 ncs_cli -J -u admin


# Demonstration environment cleaning targets
deep_clean: stop clean_containers clean_log clean_run clean_images

clean_images:
	-docker image rm -f cisco-nso-dev:${VER}
	-docker image rm -f cisco-nso-prod:${VER}
	-docker image rm -f mod-nso-prod:${VER}
	-docker image rm -f mod-nso-dev:${VER}

clean_containers:
	-docker ps -a | grep -E 'nso-prod|nso-dev' | cut -d' ' -f1 | xargs docker container stop | xargs docker rm

clean_run:
	rm -rf ./NSO-vol/*

clean_log:
	rm -rf ./NSO-log-vols/*

clean_cdb:
	rm  ./NSO-vol/*/run/cdb/*.cdb