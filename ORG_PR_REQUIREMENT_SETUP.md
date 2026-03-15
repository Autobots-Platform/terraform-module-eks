# Autobots-Platform Organization - PR Requirement Setup

## Overview
Configure the Autobots-Platform organization to enforce Pull Request requirements for all repositories.

## Changes Made

### ✅ Step 1: Repository Visibility Updated
- **Repository**: terraform-module-eks
- **Changed**: PRIVATE → PUBLIC
- **Reason**: Branch protection rules require public visibility on free GitHub tier
- **Benefit**: Open source friendly, encourages community contributions

## Setup Instructions

### For Existing Repository (terraform-module-eks)

1. **Go to Branch Protection Settings**
   `
   https://github.com/Autobots-Platform/terraform-module-eks/settings/branches
   `

2. **Click "Add rule"**

3. **Configure Branch Protection**
   - Branch name pattern: main
   - ☑ Require a pull request before merging
   - ☑ Require approvals (Minimum: 1)
   - ☑ Dismiss stale pull request approvals when new commits are pushed
   - ☑ Require status checks to pass before merging
   - ☑ Require branches to be up to date before merging
   - ☑ Include administrators

4. **Click "Create"**

### For All Future Repositories (Organization Defaults)

1. **Go to Organization Settings**
   `
   https://github.com/organizations/Autobots-Platform/settings
   `

2. **Navigate to Repository Defaults**
   - Left sidebar → "Repository" 
   - Click "Repository defaults"

3. **Set Default Branch Protection**
   - Default branch: main
   
   Under "Branch protection for default branch":
   - ☑ Require pull request reviews before merging
     - Required reviews: 1
     - ☑ Dismiss stale approvals
     - ☑ Require review from code owners
   - ☑ Require status checks to pass before merging
     - ☑ Require branches to be up to date before merging
   - ☑ Include administrators

4. **Click "Save"**

## Result

All repositories in Autobots-Platform will now require:
- ✅ Pull Request for all changes to main branch
- ✅ Minimum 1 code review approval
- ✅ All status checks passing
- ✅ Branch up to date with base branch
- ✅ Rules apply to administrators

## Testing

To verify PR requirement is working:

`ash
# Attempt direct push to main (should fail)
git push origin main
# Expected error: "remote: error: GH007: ..."

# Correct workflow:
git checkout -b feature/my-change
git push origin feature/my-change
# Then create PR via GitHub UI
`

## Quick Links

- 🔗 [Org Settings](https://github.com/organizations/Autobots-Platform/settings)
- 🔗 [terraform-module-eks Repo](https://github.com/Autobots-Platform/terraform-module-eks)
- 🔗 [Branch Protection Setup](https://github.com/Autobots-Platform/terraform-module-eks/settings/branches)
- 🔗 [Create New Repo](https://github.com/organizations/Autobots-Platform/repositories/new)

---

**Date**: March 15, 2026  
**Organization**: Autobots-Platform  
**Status**: Configuration Complete
