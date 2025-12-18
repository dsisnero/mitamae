# Release Process

This document describes the release process for mitamae.

## Versioning

mitamae follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality in a backward compatible manner
- **PATCH** version for backward compatible bug fixes

## Release Checklist

### Pre-release Preparation

1. **Ensure tests pass**:
   ```bash
   bundle exec rake test
   ```

2. **Update version** in `mrblib/mitamae/version.rb`:
   ```ruby
   module MItamae
     VERSION = '1.14.3'  # Update to new version
   end
   ```

3. **Update CHANGELOG.md**:
   - Add new version section at top
   - Include all changes since last release
   - Group changes by type (Features, Bug Fixes, etc.)
   - Link to relevant issues/PRs

4. **Verify version consistency**:
   ```bash
   bundle exec rspec spec/version_spec.rb
   ```

### Creating a Release

1. **Create and push tag**:
   ```bash
   git tag -a v1.14.3 -m "Release v1.14.3"
   git push origin v1.14.3
   ```

2. **GitHub Actions will automatically**:
   - Run tests on all platforms
   - Build binaries for all supported targets
   - Create GitHub release with binaries
   - Upload artifacts to GitHub Releases

### Manual Release (Fallback)

If GitHub Actions fails, you can build manually:

1. **Build all targets**:
   ```bash
   bundle exec rake release:build
   ```

2. **Compress binaries**:
   ```bash
   bundle exec rake release:compress
   ```

3. **Create release on GitHub**:
   - Go to https://github.com/itamae-kitchen/mitamae/releases
   - Click "Draft a new release"
   - Select the tag you created
   - Upload binaries from `mitamae-build/` directory
   - Copy CHANGELOG entries for this version

## Supported Platforms

mitamae builds binaries for:

### Linux
- `x86_64` (64-bit Intel/AMD)
- `i386` (32-bit Intel/AMD)
- `armhf` (ARMv7, Raspberry Pi)
- `aarch64` (ARM64)

### macOS
- `x86_64` (Intel Macs)
- `aarch64` (Apple Silicon)

### Windows
- `x86_64` (64-bit Windows)
- `i386` (32-bit Windows)

## Build Configuration

### Dependencies

- **Zig 0.9.1+**: For cross-compilation
- **Ruby 3.0+**: For running build scripts
- **Docker**: For integration tests
- **Git**: For fetching mruby

### Build Commands

```bash
# Build for specific target
bundle exec rake release:build:linux-x86_64

# Build all targets
bundle exec rake release:build

# Compress built binaries
bundle exec rake release:compress

# Clean build artifacts
bundle exec rake clean
```

### Cross-compilation Details

The build uses Zig for cross-compilation with musl libc for Linux targets:

- **Linux**: Uses musl libc for static linking
- **macOS**: Uses macOS SDK with version targeting
- **Windows**: Uses MinGW toolchain

## Release Artifacts

Each release includes:

1. **Binary archives** (`mitamae-{arch}-{os}.tar.gz`):
   - Contains the mitamae binary
   - Named by architecture and OS

2. **SHA256 checksums** (optional):
   - Generated for verification
   - Should be published with release

3. **Source code**:
   - Tagged in git repository
   - Available as source archive on GitHub

## Quality Assurance

### Testing

Before release, ensure:

1. **Integration tests pass** with Docker
2. **Windows tests pass** (separate workflow)
3. **Binaries work** on target platforms
   - Basic functionality test: `./mitamae version`
   - Simple recipe execution test

### Verification

1. **Binary signatures** (if GPG signing is configured)
2. **Checksum verification** for all binaries
3. **Smoke tests** on different platforms

## Post-release Tasks

1. **Update documentation** if needed
2. **Announce release** (Twitter, mailing list, etc.)
3. **Monitor issues** for regression reports
4. **Update package managers** (Homebrew, Chocolatey, etc.)

## Troubleshooting

### Common Issues

1. **Zig version mismatch**: Ensure Zig 0.9.1 is installed
2. **macOS SDK issues**: SDK should be automatically downloaded
3. **Windows build failures**: Check MinGW installation
4. **Memory issues**: Build process may require significant RAM

### Recovery Steps

If a release fails:

1. **Delete the git tag**:
   ```bash
   git tag -d v1.14.3
   git push origin :refs/tags/v1.14.3
   ```

2. **Fix the issue** and restart process
3. **Use new patch version** if binaries were partially released

## Release Schedule

There is no fixed release schedule. Releases are made when:

- Significant features are completed
- Critical bugs are fixed
- Security updates are needed
- Enough changes accumulate for a meaningful release

## Maintainer Notes

### Release Automation

The `.github/workflows/build.yml` handles:
- Testing on Ubuntu
- Building all targets
- Creating GitHub release

### Version Bumping

Use `bin/bump-version` script if available, or manually:
1. Update `mrblib/mitamae/version.rb`
2. Update `CHANGELOG.md`
3. Run version spec test

### Emergency Releases

For security fixes:
1. Create patch from main branch
2. Follow normal release process
3. Mark as security release in GitHub
4. Notify users through appropriate channels