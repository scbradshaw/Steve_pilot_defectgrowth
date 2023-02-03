PROJECT := ConditionAnalyzer
COMPONENT := ui
USER    := $(shell whoami)
IMAGE=$(PROJECT)-$(COMPONENT)
DEV_IMAGE := $(IMAGE):$(USER)
ACR=azprdacrdra1
REPO=$(ACR).azurecr.io
IMAGE_TAG?=Dev
NAMESPACE=aurizon-data-science
IMAGE_NAME?= $(REPO)/$(NAMESPACE)/$(IMAGE)

# Build the production docker image
image: 
	DOCKER_BUILDKIT=1 docker build \
		--target prd \
		--tag $(IMAGE_NAME):$(IMAGE_TAG) \
		--build-arg VERSION=$(IMAGE_TAG) \
		.

# Run the production docker image locally and view app on localhost:3838
run:
	docker run --rm \
		--publish 3838:3838 \
		$(IMAGE_NAME):$(IMAGE_TAG)

# Run unit tests (for use in Azure DevOps pipeline)
test:
	apt-get update
	apt-get install libxml2-dev
	CODE="testthat::test_package('CA')"
	R -e 'install.packages(c("remotes","covr","xml2"))'
	R -e 'remotes::install_local("CA/", dependencies=TRUE, upgrade="never")'
	R -e 'covr::to_cobertura(covr::package_coverage(path="CA/"), filename = "coverage.xml")' 
	R -e 'covr::to_cobertura(covr::package_coverage(path="CA/", type = "none", code = "${CODE}"), filename = "unit-testresults.xml")'

# Stop devcontainer - TODO(jayde): Find less hacky solution
dev-stop:
	sudo kill 1

