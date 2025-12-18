# Security Policy

## Supported Versions

We release security updates for the following versions of mitamae:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

If you believe you have found a security vulnerability in mitamae, please report it to us through coordinated disclosure.

### Private Disclosure Process

1. **Email the maintainers** at [INSERT SECURITY EMAIL]
   - Include a detailed description of the vulnerability
   - Provide steps to reproduce
   - Include any proof-of-concept code
   - Mention the version(s) affected

2. **You will receive a response** within 48 hours acknowledging receipt of your report.

3. **The security team will investigate** and validate the report.

4. **We will work on a fix** and keep you informed of our progress.

5. **Once the fix is ready**, we will:
   - Release a patched version
   - Update the CHANGELOG with security notes
   - Credit you for the discovery (unless you prefer to remain anonymous)

6. **We will publish a security advisory** on GitHub after the fix is released.

### What to Report

- Remote code execution vulnerabilities
- Privilege escalation issues
- Authentication bypasses
- Data leakage or exposure
- Significant denial of service vectors
- Supply chain attacks

### What Not to Report

- Best practice violations without demonstrated exploit
- Theoretical issues without proof-of-concept
- Issues in dependencies that don't affect mitamae's security
- Missing security headers in documentation websites

## Security Considerations for Users

### Binary Verification

mitamae releases are distributed as binaries. To verify authenticity:

1. Check GPG signatures when available
2. Verify SHA256 checksums
3. Download from official GitHub releases only

### Recipe Security

mitamae recipes can execute arbitrary commands. Follow these best practices:

1. **Review recipes** from untrusted sources before running
2. **Use checksums** for remote files when possible
3. **Limit privileges** - run mitamae with minimal necessary permissions
4. **Isolate environments** - use containers or VMs for testing

### Plugin Security

Plugins extend mitamae's functionality but can introduce risks:

1. **Audit plugin code** before use
2. **Use trusted sources** for plugins
3. **Keep plugins updated** to receive security fixes

## Security Updates

Security updates are released as patch versions (e.g., 1.14.2 → 1.14.3).

We recommend:
- Always using the latest patch version
- Subscribing to GitHub releases for notifications
- Monitoring the CHANGELOG for security-related updates

## Dependency Security

mitamae depends on:
- mruby (embedded Ruby runtime)
- specinfra (infrastructure testing library)
- Various mruby gems

We monitor these dependencies for security issues and update them regularly.

## Build Security

The build process uses:
- Zig for cross-compilation
- GitHub Actions for CI/CD
- Docker for testing

All build artifacts are created in isolated environments and verified before release.

## Responsible Disclosure Guidelines

We follow these principles for responsible disclosure:

1. **Allow reasonable time** for fixes before public disclosure
2. **Coordinate release** of fixes and advisories
3. **Credit researchers** (with permission)
4. **Prioritize user safety** in all decisions

## Contact

For security-related issues, contact: [INSERT SECURITY EMAIL]

For general questions, use GitHub Issues or Discussions.

Thank you for helping keep mitamae secure!