#!/bin/bash
set -e

echo "Running pre-commit checks..."

# Check for trailing whitespace
echo "Checking for trailing whitespace..."
if git diff --cached --check --word-diff-regex='[^[:space:]]' > /dev/null; then
  echo "✓ No trailing whitespace"
else
  echo "✗ Found trailing whitespace"
  exit 1
fi

# Run RuboCop on staged Ruby files
echo "Running RuboCop..."
if command -v rubocop > /dev/null; then
  if bundle exec rubocop --force-exclusion; then
    echo "✓ RuboCop passed"
  else
    echo "✗ RuboCop failed"
    exit 1
  fi
else
  echo "⚠ RuboCop not installed, skipping"
fi

# Run RSpec tests
echo "Running RSpec tests..."
if command -v rspec > /dev/null; then
  if bundle exec rspec --pattern 'spec/**/*_spec.rb'; then
    echo "✓ RSpec tests passed"
  else
    echo "✗ RSpec tests failed"
    exit 1
  fi
else
  echo "⚠ RSpec not installed, skipping"
fi

echo "All pre-commit checks passed! ✅"