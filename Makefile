.PHONY: clean build release

clean:
	rm -rf build/

# Build all the packages
build:		
	mkdir build;
	cd charts; find . -maxdepth 1 -type d -exec bash -c "helm package {} -d ../build" \;

# Build all the packages
lint:
	cd charts; find . -maxdepth 1 -type d -exec bash -c "cd {} && helm lint" \;

# Create index after building all the packages
index: build
	helm repo index build/

deploy: release
publish: release
release: clean lint build index
	cp README.md build/
	#cd build
	#git branch -D build
	#git checkout -b build
	git add .
	git commit -m "Publish repo"
	git push
	#git checkout release
	helm repo update
