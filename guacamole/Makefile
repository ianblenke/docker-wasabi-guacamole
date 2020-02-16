multiarch:
	docker buildx inspect multiarch || docker buildx create --name multiarch
	docker buildx use multiarch
	docker buildx inspect --bootstrap
	docker buildx build --platform linux/amd64,linux/arm64 -t ianblenke/guacamole --push .

