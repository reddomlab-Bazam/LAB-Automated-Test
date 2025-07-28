# Contributing to LAB-Automated-Test

Thank you for your interest in contributing to the LAB-Automated-Test repository! This document provides guidelines and instructions for contributing.

## 🤝 How to Contribute

### 🐛 Reporting Bugs

1. **Check existing issues** first to avoid duplicates
2. **Use the bug report template** when creating new issues
3. **Provide detailed information** including:
   - Environment details (OS, shell, AWS region)
   - Steps to reproduce
   - Expected vs actual behavior
   - Error logs and screenshots

### 💡 Suggesting Features

1. **Use the feature request template**
2. **Describe the use case** clearly
3. **Explain the benefits** for the testing suite
4. **Consider implementation complexity**

### 🔧 Code Contributions

#### Getting Started

1. **Fork the repository**
   ```bash
   gh repo fork reddomlab-Bazam/LAB-Automated-Test
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR-USERNAME/LAB-Automated-Test.git
   cd LAB-Automated-Test
   ```

3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

#### Development Guidelines

1. **Script Standards**
   - Use `#!/bin/bash` shebang
   - Follow existing code style and patterns
   - Add comprehensive error handling
   - Include helpful comments and documentation
   - Use consistent variable naming (UPPER_CASE for globals)

2. **Testing Requirements**
   - Test your changes locally before submitting
   - Ensure scripts pass shellcheck validation
   - Verify functionality with `--dry-run` mode
   - Update documentation as needed

3. **Documentation**
   - Update README.md if adding new scripts
   - Add comments explaining complex logic
   - Include usage examples
   - Update CONSOLIDATED_TESTING_SUITE.md for major changes

#### Code Style

```bash
#!/bin/bash

# Function names: snake_case
function test_connectivity() {
    local url="$1"
    local timeout="${2:-10}"
    
    # Clear variable names and error handling
    if ! curl -s --max-time "$timeout" "$url" > /dev/null; then
        log_error "Failed to connect to $url"
        return 1
    fi
    
    log_success "Successfully connected to $url"
    return 0
}

# Constants: UPPER_CASE
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEFAULT_TIMEOUT=30

# Error handling
set -euo pipefail
```

#### Submitting Changes

1. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new connectivity test for X"
   ```

2. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create a Pull Request**
   - Use descriptive title and description
   - Reference related issues
   - Include testing evidence
   - Request review from maintainers

### 📋 Pull Request Guidelines

#### PR Requirements

- [ ] **Descriptive title** following conventional commits
- [ ] **Clear description** of what changed and why
- [ ] **Tests passing** (automated CI/CD checks)
- [ ] **Documentation updated** (if applicable)
- [ ] **No merge conflicts** with main branch

#### PR Types

Use these prefixes in your commit messages:

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style improvements
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

#### Review Process

1. **Automated checks** must pass (syntax, security, functionality)
2. **Maintainer review** for code quality and compatibility
3. **Testing verification** in development environment
4. **Documentation review** for completeness
5. **Final approval** and merge

## 🧪 Testing Infrastructure

### Local Testing

```bash
# Syntax checking
shellcheck *.sh

# Dry run testing
./master_consolidated_test.sh --dry-run quick

# Full local validation
./run_all_tests.sh --dry-run comprehensive
```

### CI/CD Pipeline

Our GitHub Actions automatically:
- ✅ Check shell script syntax
- ✅ Validate documentation
- ✅ Run security scans
- ✅ Test basic functionality
- ✅ Verify file permissions

## 🏗️ Repository Structure

```
LAB-Automated-Test/
├── .github/                          # GitHub-specific files
│   ├── workflows/ci.yml              # CI/CD pipeline
│   └── ISSUE_TEMPLATE/               # Issue templates
├── master_consolidated_test.sh       # Main testing script
├── run_all_tests.sh                 # Test coordinator
├── web_launcher.sh                   # Web API interface
├── infrastructure_testing_dashboard.html  # Web UI
├── README.md                         # Main documentation
├── CONSOLIDATED_TESTING_SUITE.md     # Detailed guide
├── CONTRIBUTING.md                   # This file
└── LICENSE                          # MIT License
```

## 📞 Getting Help

- **Documentation:** Check README.md and CONSOLIDATED_TESTING_SUITE.md
- **Issues:** Search existing issues or create new ones
- **Discussions:** Use GitHub Discussions for questions
- **Contact:** Reach out to repository maintainers

## 🎯 Contribution Areas

We welcome contributions in these areas:

1. **Test Scripts**
   - New infrastructure tests
   - Performance monitoring
   - Security validation
   - Error handling improvements

2. **Dashboard Enhancements**
   - UI/UX improvements
   - New features and functionality
   - Mobile responsiveness
   - Real-time monitoring

3. **Documentation**
   - Usage examples
   - Troubleshooting guides
   - Video tutorials
   - API documentation

4. **Automation**
   - CI/CD improvements
   - Deployment automation
   - Monitoring integration
   - Alerting systems

Thank you for contributing to the InfamousLab testing infrastructure! 🚀
