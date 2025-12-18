# Contributing to mitamae

Thank you for your interest in contributing to mitamae! This document provides guidelines and instructions for contributing.

## Development Environment

### Prerequisites

- Ruby 3.0+ (for running tests and building)
- Docker (for integration tests)
- Zig 0.9.1+ (for cross-compilation)
- Git

### Setup

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/your-username/mitamae.git
   cd mitamae
   ```

2. Install Ruby dependencies:
   ```bash
   bundle install
   ```

3. Install development tools:
   ```bash
   gem install rubocop rubocop-performance rubocop-rake rubocop-rspec
   ```

## Development Workflow

### Code Style

We use RuboCop to enforce code style. Please ensure your code passes linting:

```bash
# Run RuboCop
bundle exec rake rubocop

# Auto-correct fixable issues
bundle exec rake rubocop:autocorrect
```

### Pre-commit Hooks

We provide pre-commit hooks to help maintain code quality:

#### Using the simple script:
```bash
# Make the script executable
chmod +x scripts/pre-commit.sh

# Run manually before committing
./scripts/pre-commit.sh

# Or set as git hook
cp scripts/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

#### Using pre-commit framework:
```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run on all files
pre-commit run --all-files
```

### Pre-merge Hook

We provide a pre-merge hook to keep your fork up-to-date with upstream before merging:

```bash
# Install the pre-merge-upstream hook
cp scripts/pre-merge-upstream.sh .git/hooks/pre-merge-commit
chmod +x .git/hooks/pre-merge-commit
```

This hook will automatically fetch upstream and fast-forward the main branch (default: `master`) when you're on that branch and about to merge. If fast-forward is not possible, the merge will be aborted so you can manually resolve.

Environment variables:
- `UPSTREAM_REMOTE`: name of upstream remote (default: `upstream`)
- `MAIN_BRANCH`: name of main branch (default: `master`)
- `SKIP_PRE_MERGE_UPSTREAM`: set to `1` to skip the hook

### Code Quality Tools

We provide additional scripts to help maintain code quality:

#### Fix Trailing Whitespace

The `fix-trailing-whitespace.sh` script removes trailing whitespace from text files:

```bash
# Dry run to see what would be changed
./scripts/fix-trailing-whitespace.sh -d

# Fix trailing whitespace in specific files
./scripts/fix-trailing-whitespace.sh path/to/file1 path/to/file2

# Fix trailing whitespace in all tracked files
./scripts/fix-trailing-whitespace.sh

# Verbose output
./scripts/fix-trailing-whitespace.sh -v
```

The script is cross-platform and works on Linux, macOS, and Windows (with Git Bash or WSL). It automatically detects binary files and skips them.

### Testing

mitamae uses integration tests with Docker. To run tests:

```bash
# Run all tests (linting + integration tests)
bundle exec rake test

# Run only integration tests
bundle exec rake test:integration

# Run only RuboCop
bundle exec rake rubocop
```

### Building

To build mitamae binaries:

```bash
# Build for a specific target (e.g., linux-x86_64)
bundle exec rake release:build:linux-x86_64

# Build all release targets
bundle exec rake release:build

# Compress built binaries
bundle exec rake release:compress
```

### Cross-compilation Targets

Supported targets:
- `linux-x86_64`
- `linux-i386`
- `linux-armhf`
- `linux-aarch64`
- `darwin-x86_64`
- `darwin-aarch64`
- `windows-x86_64`
- `windows-i386`

## Pull Request Process

1. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the code style guidelines.

3. **Add tests** for new functionality or bug fixes.

4. **Run tests** to ensure everything passes:
   ```bash
   bundle exec rake test
   ```

5. **Commit your changes** with descriptive commit messages:
   ```bash
   git commit -m "Add feature: description of changes"
   ```

6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request** on GitHub with:
   - Clear description of changes
   - Reference to any related issues
   - Summary of testing performed

### Pull Request Guidelines

- Keep PRs focused on a single feature or bug fix
- Include tests for new functionality
- Update documentation if needed
- Ensure CI passes before requesting review
- Respond to review feedback promptly

## Code Organization

### Project Structure

- `mrblib/` - mruby source code (the core mitamae implementation)
- `spec/` - Integration tests
- `spec/recipes/` - Test recipes for integration tests
- `tools/` - C source code for the mitamae binary
- `build_config.rb` - mruby build configuration
- `Rakefile` - Build and test tasks

### mruby Considerations

mitamae uses mruby (a lightweight Ruby implementation) rather than standard Ruby. Keep in mind:

- Not all Ruby standard library features are available
- Code runs in a constrained environment
- Performance is critical (avoid unnecessary allocations)
- See [mruby features in README](../README.md#mruby-features) for available libraries

## Issue Reporting

When reporting issues, please include:

1. **Description** of the problem
2. **Steps to reproduce**
3. **Expected behavior**
4. **Actual behavior**
5. **Environment details** (OS, mitamae version, etc.)
6. **Relevant logs or error messages**

## Plugin Development

See [PLUGINS.md](./PLUGINS.md) for information on developing mitamae plugins.

## Release Process

Releases are managed by maintainers. The process includes:

1. Version bump in `mrblib/mitamae/version.rb`
2. Update `CHANGELOG.md`
3. Tag release with `vX.Y.Z`
4. CI automatically builds and publishes binaries

## Getting Help

- Check the [README](../README.md) for documentation
- Review existing issues and PRs
- Ask questions in discussions or issues

## Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](./CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

Thank you for contributing to mitamae!