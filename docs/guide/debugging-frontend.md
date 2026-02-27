# Vue Frontend Debugging Checklist

This guide covers debugging errors in the Vue UI itself (component errors, state management, rendering issues) — complementing backend debugging guides which focus on the backend API stack (nginx/envoy/gRPC/database).

---

## 🔍 Phase 1: Error Identification

### ☑️ Capture Initial State
- [ ] Open F12 Developer Tools
- [ ] Check **Console** tab for errors with line numbers
- [ ] Check **Network** tab for API responses
- [ ] Take screenshot of error state
- [ ] Take screenshot of UI state
- [ ] Note exact user actions to reproduce

### ☑️ Locate Source of Error
```bash
# Find all files with matching name
find src/components -name "componentName.vue"

# Search for error context
grep -rn "function name" src/components/

# Check error line numbers match file content
head -200 src/components/.../file.vue | tail -50
```

### ⚠️ Critical: Verify Correct File
- [ ] Match error line number to actual file content
- [ ] Check if multiple versions exist (VPOS vs VPOS2, different modules)
- [ ] Verify which version is actually imported/used
- [ ] **Don't assume first search result is correct file**

---

## 🔎 Phase 2: Data Flow Analysis

### ☑️ API Layer
```javascript
// F12 Network tab: Check actual API response
// Verify response structure matches code expectations
{
  "record_count": "X",
  "items": [...],  // Or different property name?
  "next_page_token": ""
}
```

### ☑️ Vuex Store Layer
```javascript
// Check store module structure
state['module/submodule'].property

// Verify action response handling
commit('mutation', response.items)  // Correct property?

// Test getter in F12 console
$vm0.$store.getters.getterName
```

### ☑️ Component Layer
```javascript
// Check computed property source
computed(() => store.getters.correctGetter)  // Right getter?

// Verify data access pattern
currentObject.value.property  // Needs .value for refs?

// Check null safety
object && object.property ? object.property : defaultValue
```

### ⚠️ Common Data Flow Issues
- [ ] API returns `response.items` but code expects `response.records`
- [ ] Store module has data but component uses different module
- [ ] Multiple store modules have similar data (component uses wrong one)
- [ ] Component expects nested structure but API returns flat

---

## 🛠️ Phase 3: Fix Implementation

### ☑️ Property Access Safety
```javascript
// ❌ Unsafe
return object.property.nested

// ✅ Safe with ternary
return object && object.property ? object.property.nested : ''

// ✅ Safe with optional chaining (if babel supports it)
return object?.property?.nested ?? ''

// ✅ Safe with explicit checks
if (!isEmptyValue(object) && !isEmptyValue(object.property)) {
  return object.property.nested
}
return ''
```

### ☑️ Logic Verification
```javascript
// Common mistake: Inverted logic
isDisabled: () => {
  return amount !== 0  // ❌ Disabled when HAS amount
  return amount === 0  // ✅ Disabled when NO amount
}

// Boolean logic double-check
enabled when X → disabled = !X
disabled when X → disabled = X
```

### ☑️ Template vs Script
```vue
<template>
  <!-- ❌ Displays raw object -->
  {{ currencyObject }}

  <!-- ✅ Displays property -->
  {{ currencyObject ? currencyObject.iso_code : '' }}

  <!-- ✅ Use computed property -->
  {{ displayCurrency }}
</template>

<script>
const displayCurrency = computed(() => {
  return currentCurrency.value?.iso_code || ''
})
</script>
```

### ⚠️ Syntax Compatibility
- [ ] Optional chaining `?.` - check if babel config supports it
- [ ] Nullish coalescing `??` - check if babel config supports it
- [ ] Use ternary operator as fallback: `obj ? obj.prop : default`
- [ ] Test in actual browser, not just IDE

---

## 🧪 Phase 4: Testing & Verification

### ☑️ Development Server Setup (Yarn)

**What is Yarn?**

Yarn is a JavaScript package manager and task runner. For Vue development, `yarn start` launches a **development server with hot module replacement (HMR)** - allowing you to test code changes instantly without rebuilding Docker containers.

**Why use Yarn for testing?**

- **Hot Replacement**: Changes appear in browser within 1-2 seconds after saving
- **No Docker rebuilds**: Test fixes immediately using repository code
- **Source maps**: F12 shows original source code with proper line numbers
- **Fast iteration**: Edit → Save → Test (2 seconds) vs Build → Deploy → Restart (5+ minutes)

**Installation**

```bash
# Check if Node.js is installed
node --version  # Should be v20.x or similar

# If Node.js not installed, use nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20

# Install Yarn globally
npm install -g yarn

# Verify installation
yarn --version
```

**Starting the Development Server**

```bash
# Navigate to Vue repository
cd /path/to/adempiere-vue

# Set Node options (required for Node.js 20 with older webpack)
export NODE_OPTIONS=--openssl-legacy-provider

# Start development server
yarn start

# Wait for: "Compiled successfully in XXXXms"
# Access at: http://localhost:9527/vue (or server IP:9527/vue)
```

**Note:** The development server proxies API calls to your production backend (port 80), so you need the backend Docker stack running separately.

---

### ☑️ Compilation Check
```bash
# Watch terminal where yarn start runs
# Wait for message:
Compiled successfully in XXXXms

# If errors, fix them before testing
Compiled with warnings - check and fix
Failed to compile - must fix before proceeding
```

### ☑️ Browser Testing
- [ ] **Clear cache**: Use incognito window OR Ctrl+Shift+R
- [ ] **Verify change loaded**: Check source in F12 Sources tab
- [ ] **Check console**: Should have no errors
- [ ] **Test user flow**: Complete full scenario
- [ ] **Verify data**: Use console to inspect Vue store state

### ☑️ Console Debugging
```javascript
// Access Vue instance (click element first, then in console:)
$vm0

// Check store state
$vm0.$store.state

// Check specific module
$vm0.$store.state['module/path']

// Test getter
$vm0.$store.getters.getterName

// Check computed property
$vm0.computedPropertyName
```

### ⚠️ Cache Issues
- [ ] Hard refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
- [ ] Incognito window: Guaranteed clean slate
- [ ] F12 → Network tab → "Disable cache" checkbox (while DevTools open)
- [ ] Clear webpack cache: `rm -rf node_modules/.cache`

---

## 🔧 Phase 5: Common Fix Patterns

### Pattern 1: Undefined Property Access
```javascript
// Error: Cannot read properties of undefined (reading 'property')

// Find all occurrences
grep -n "object.property" file.vue

// Fix each with null check
object && object.property ? object.property : defaultValue
```

### Pattern 2: Wrong Store Module
```javascript
// Symptom: Getter returns empty/undefined but API has data

// Check all store modules in console
$vm0.$store.state

// Find where data actually is
grep -rn "commit.*MutationName" src/store/

// Update component to use correct getter
computed(() => store.getters['correctModule/getter'])
```

### Pattern 3: Inverted Boolean Logic
```javascript
// Symptom: Button disabled when should be enabled

// Find isDisabled/disabled logic
grep -n "isDisabled\|:disabled" file.vue

// Check logic makes sense
disabled = condition  // When condition is TRUE, button disabled
disabled = !condition // When condition is FALSE, button disabled

// Common fix: flip === and !==
return value !== 0  // Wrong if should enable when value exists
return value === 0  // Right - disabled when no value
```

### Pattern 4: Raw Object Display
```vue
<!-- Symptom: Shows [object Object] or JSON in UI -->

<!-- Find in template -->
{{ objectVariable }}

<!-- Fix: Access specific property -->
{{ objectVariable ? objectVariable.displayProperty : '' }}

<!-- Or create computed property -->
<script>
const displayValue = computed(() => {
  return objectVariable.value?.displayProperty || 'N/A'
})
</script>
```

---

## 📊 Phase 6: Database Verification

### ☑️ When to Check Database
- [ ] API returns unexpected values
- [ ] Configuration seems wrong
- [ ] Limits/settings not matching expectations
- [ ] Backend error suggests data issue

### ☑️ Database Access
```bash
# Connect to postgres container
docker exec <postgres-container> psql -U adempiere -d adempiere

# Or via SSH (if on remote server)
ssh <server>
docker exec -it <postgres-container> psql -U adempiere -d adempiere
```

### ☑️ Common Queries
```sql
-- Find POS configuration
SELECT * FROM c_pos WHERE c_pos_id = 1000005;

-- Find payment method allocation
SELECT * FROM c_pospaymenttypeallocation
WHERE c_pos_id = 1000005;

-- Update configuration
UPDATE c_pospaymenttypeallocation
SET maximumrefundallowed = 1000,
    maximumdailyrefundallowed = 500
WHERE c_pospaymenttypeallocation_id = XXXXX;
```

---

## 📝 Phase 7: Documentation

### ☑️ What to Document
- [ ] **Problem**: Clear description with screenshots
- [ ] **Root cause**: Technical explanation of why it failed
- [ ] **Solution**: Exact changes made (file, line, before/after)
- [ ] **Testing**: How to verify fix works
- [ ] **Commands**: Copy-paste ready commands for replication

### ☑️ Files to Keep
- [ ] Screenshots: Before/after states
- [ ] Console logs: Error messages and stack traces
- [ ] Network responses: API data structures
- [ ] Database queries: Configuration verification
- [ ] Git diff: Exact code changes

### ☑️ Solution Documentation Template
```markdown
# Problem Description
- Symptom
- Error messages
- Business impact

# Root Causes
- Technical analysis
- Code locations
- Why it failed

# Solution
- Changes made
- File locations
- Before/after code

# Testing
- Test scenario
- Expected results
- Verification steps

# Implementation
- Commands to run
- Order of operations
- Verification queries
```

---

## ⚡ Quick Commands Reference

### Why Use Yarn Dev Server?

The yarn development server (`yarn start`) provides significant advantages for debugging and development:

**🔄 Hot Module Replacement (HMR)**
- Changes reflect **instantly** in browser (1-2 seconds)
- No manual refresh needed
- State preserved during updates
- See fixes immediately without restarting

**🔍 Enhanced Debugging**
- **Source maps**: F12 shows original source code with proper line numbers
- **Development mode**: Detailed error messages with full stack traces
- **Vue DevTools**: Full component inspection and state debugging
- **Console warnings**: Helpful hints about common mistakes

**⚡ Fast Iteration Cycle**
```
Edit code → Save → See result (2 seconds)
vs
Edit code → Build Docker image → Deploy → Restart container (5+ minutes)
```

**💾 No Container Rebuilds**
- Test changes without Docker image builds
- Verify fixes before committing
- Experiment freely without affecting production containers

**🎯 Development vs Production**
- Dev server uses repository code (your latest changes)
- Production Docker uses baked-in code (last image build)
- Perfect for testing fixes before publishing new image versions

**Example Workflow:**
```bash
# 1. Make code change in ComponentName.vue
# 2. Save file
# 3. Browser auto-refreshes (2 seconds)
# 4. Test immediately
# 5. Fix works? Commit to git
# 6. Later: Build new Docker image with fix
```

### Development Workflow
```bash
# Start dev server (on Mini PC)
cd /path/to/adempiere-vue
export NODE_OPTIONS=--openssl-legacy-provider
yarn start

# Watch for: "Compiled successfully in XXXXms"
# Access: http://localhost:9527/vue (or http://<server-ip>:9527/vue)
```

### File Search
```bash
# Find component files
find src/components -name "*.vue" -type f | grep componentName

# Search for text in files
grep -rn "searchText" src/components/

# Show file content with line numbers
cat -n src/components/path/file.vue | grep -A 5 -B 5 "pattern"
```

### Database Quick Check
```bash
# List tables
docker exec <postgres-container> psql -U adempiere -d adempiere -c "\dt"

# Quick query
docker exec <postgres-container> psql -U adempiere -d adempiere -c "SELECT * FROM table WHERE condition;"
```

### Git Operations
```bash
# Check what changed
git diff

# Show specific file diff
git diff src/components/path/file.vue

# Stage and commit
git add src/components/path/file.vue
git commit -m "Fix: description of fix"
```

---

## 🎯 Success Criteria Checklist

### Fix is Complete When:
- [ ] No errors in F12 Console
- [ ] UI displays correctly (no raw JSON, proper formatting)
- [ ] User can complete intended action (button enabled, form works)
- [ ] Changes tested in incognito window (no cache)
- [ ] Webpack compiled successfully with no warnings
- [ ] Solution documented with screenshots and commands
- [ ] Changes committed to git with clear message

---

## 🚨 Red Flags - Stop and Verify

### 🛑 Warning Signs

**Making same fix multiple times without effect**
→ Probably editing wrong file (check for multiple versions: ComponentName vs ComponentName2, different modules)

**Fix works locally but not in browser**
→ Cache issue or webpack not recompiling

**Error line numbers don't match file content**
→ Wrong component version being edited

**API has data but component shows empty**
→ Wrong store module or getter

**Logic seems backwards**
→ Check boolean operators (!==, ===, !, etc.)

---

## 📚 Example Debugging Scenario Template

### Problem
You encounter an error: **"Cannot read properties of undefined (reading 'PROPERTY_NAME')"** when performing **ACTION_DESCRIPTION** (e.g., clicking a button, opening a dialog, processing a form).

**Symptoms:**
- Error message: `TypeError: Cannot read properties of undefined (reading 'PROPERTY_NAME')`
- UI element: Button/dialog/form is **STATE_DESCRIPTION** (e.g., disabled, crashed, shows wrong data)
- User action: **USER_ACTION** (e.g., clicks submit, selects option, enters amount)

### Root Causes Found

Common patterns to investigate:

1. **Unsafe property access**: `object.property.nested` without null check → TypeError
   - Check: Does the object exist before accessing nested properties?

2. **Inverted logic**: `return value !== 0` when logic should be `return value === 0`
   - Check: Does the boolean condition match the intended behavior?

3. **Wrong data source**: Getting data from `sourceA` instead of `sourceB`
   - Check: Is the component using the correct Vuex getter/store module?

4. **Raw object display**: Template showing `{{ objectVariable }}` instead of `{{ objectVariable.displayProperty }}`
   - Check: Are you accessing a specific property or displaying the whole object?

### Files Modified
- `src/components/PATH/TO/ComponentName.vue`
  - Lines: XX, YY, ZZ
- `src/components/PATH/TO/RelatedComponent.vue`
  - Lines: NN

### Key Lesson
Initially edited **ComponentNameV1** version but app actually used **ComponentNameV2** version. **Always verify which component version is actually loaded by matching error line numbers exactly!**

### Solution Summary
```javascript
// ComponentName.vue Line XX - Display property not object
{{ object.property ? object.property.nested : "" }}

// ComponentName.vue Lines YY-ZZ - Add null check
if (!isEmptyValue(object) && !isEmptyValue(object.property)) {
  return object.property.nested
}
return defaultValue

// ComponentName.vue Line NN - Add null check
return property ? property.value : ''

// ComponentName.vue Line MM - Use correct data source
const { data_field_1, data_field_2 } = correctDataSource.value

// RelatedComponent.vue Line PP - Fix inverted logic
return value === expectedCondition  // was !== expectedCondition
```

---

## Related Documentation

- **Backend debugging**: See backend debugging guides for tracing errors through nginx/envoy/gRPC/database stack
- **Vue dev setup**: See project README for configuring development environment
- **API reference**: Check project documentation for endpoint specifications

---

**Keep this checklist handy for all Vue frontend debugging sessions!**
