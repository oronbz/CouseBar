.PHONY: release test build

release:
	@./scripts/release.sh $(VERSION)

test:
	@xcodebuild test \
		-project Cousebara.xcodeproj \
		-scheme Cousebara \
		-destination 'platform=macOS' \
		-skipMacroValidation \
		CODE_SIGNING_ALLOWED=NO \
		-quiet

build:
	@xcodebuild \
		-project Cousebara.xcodeproj \
		-scheme Cousebara \
		-configuration Debug \
		build \
		-quiet
