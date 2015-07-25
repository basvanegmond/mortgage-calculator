SHELL = /bin/bash
MAKEFLAGS += --no-print-directory --silent
export PATH := ./node_modules/.bin:$(PATH):./bin
LINT_DIR = $(wildcard *.js test/*.js lib/*.js test/**/*.json spikes/*)

setup:
	npm install

# the default will run lint jscs and test
default: ci

path:
	echo $$PATH

# generates the test bundle file for mocha test.html
test/%:
	mkdir -p test/bundle

test/bundle/test_bundle.js: test/%
	browserify test/*.js > $@
	echo "test_bundle.js file generated."

test-browser: test/bundle/test_bundle.js
	open test/bundle/test.html

testem:
	testem

# run test with dependencies lint and jscs
test: setup lint style
	echo "Test started"
	mocha test/

# For coveralls integration on Travis-ci
test-coveralls:
	test -d node_modules/nyc/ || npm install nyc
	nyc mocha && nyc report --reporter=text-lcov | coveralls

# Dev mode for continuous testing
dev:
	mocha --watch test

lint:
	echo "Linting started..."
	jshint $(LINT_DIR)
	echo "Linting finished without errors"
	echo

style:
	echo "Checking style..."
	jscs $(LINT_DIR)
	echo

# Continuous Integration Test Runner
ci: lint style test
	echo "1. Make sure 'git status' is clean."
	echo "2. 'git checkout -b (release-x.x.x || hotfix-x.x.x) master"
	echo "3. 'git merge development --no-ff --log'"
	echo "4. 'Make release'"

release: lint style test
	echo "1. 'git checkout master'"
	echo "2. 'git merge (release-x.x.x || hotfix-x.x.x) --no-ff --log'"
	echo "3. 'release-it'"
	echo "4. 'git checkout development'"
	echo "5. 'git merge (release-x.x.x || hotfix-x.x.x) --no-ff --log'"
	echo "6. 'git tag tag-feature-wxyz feature-wxyz'"
	echo "6. 'git branch -d (release-x.x.x || hotfix-x.x.x)'"

test-coverage-report:
	echo "Generating coverage report, please stand by"
	test -d node_modules/nyc/ || npm install nyc
	nyc mocha && nyc report --reporter=html

clean:
	test -d node_modules/nyc/ && rm -r node_modules/nyc* && echo "nyc module removed" || echo "no nyc module found"
	test -d coverage/ && rm -r coverage* && echo "coverage folder removed" || echo "no coverage folder found"
	test -d .nyc_output/ && rm -r .nyc_output* && echo "nyc output files removed" || echo "no nyc output files found"
	test -f test_bundle.js && rm test_bundle.js && echo "test_bundle.js file removed" || echo "no test_bundle file found"
	echo "finished."

.PHONY: test ci