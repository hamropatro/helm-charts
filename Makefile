.PHONY: clean release

clean:
	rm -rf build/

# Build all the packages
build:
	mkdir build;
	find charts -type d -depth 1 -exec helm package {} -d build \;

# Build all the packages
lint:
	find charts -type d -depth 1 -exec bash -c "cd {} && helm lint" \;

# Create index after building all the packages
index: build
	helm repo index build/

release: clean lint build index
	cp README.md build/
	cd build
	git checkout build
	git add -f build/
	git commit -m "Publish repo"
	git push -fu origin build
	git checkout release
	helm repo update