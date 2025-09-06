# qb Script Test Suite

This test suite provides comprehensive testing for the `qb` (Quick Build) script.

## Overview

The test suite covers all major functionality of the `qb` script:

- **Command line argument parsing** - Tests all options and flags
- **Project root detection** - Verifies Maven project discovery
- **Maven configuration** - Tests repository setup and build options
- **Git integration** - Tests branch/commit detection for Docker tagging
- **Docker retagging** - Tests the core retagging functionality
- **Error handling** - Tests various error conditions

## Running the Tests

```bash
./test_qb.sh
```

## Test Coverage

### Command Line Arguments
- `--help, -h` - Help text display
- `--dirty, -d` - Skip clean step
- `--test, -t` - Run tests (disable skipTests)
- `--default-repo, -r` - Use default Maven repository
- `--single-thread, -1` - Disable multi-threading
- `--no-retag, -n` - Skip Docker retagging
- Custom Maven goals and arguments

### Project Detection
- Finds `pom.xml` in current directory
- Finds `pom.xml` in parent directories
- Proper error handling when no `pom.xml` found

### Maven Configuration
- Project-specific vs default repository
- Multi-threading enabled by default (-T6)
- Skip tests by default (-DskipTests)
- Custom Maven arguments passed through

### Git Integration
- Branch and commit hash detection
- Proper handling when not in git repository
- Docker tag generation from git info

### Docker Retagging
- Retagging disabled with `--no-retag`
- Retagging attempted when enabled
- Proper registry filtering (octo-cx images only)

## Test Environment

The test suite creates a temporary environment with:
- Mock Maven project with `pom.xml`
- Mock Maven wrapper (`mvnw`)
- Mock git repository
- Isolated test directory

All test artifacts are cleaned up automatically.

## Output

The test suite provides:
- Colored output (green for pass, red for fail)
- Detailed test results
- Summary with pass/fail counts
- Clear error messages for failed tests

## Example Output

```
Starting qb script test suite
==================================
ℹ Testing --help option
✓ help_option: Help text displayed correctly
ℹ Testing project root detection
✓ project_root_from_root: Project root detected correctly from root
...

==================================
Test Summary
Total tests: 18
Passed: 18
Failed: 0
All tests passed!
```
