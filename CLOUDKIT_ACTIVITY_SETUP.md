# CloudKit Activity Record Type Setup Guide

## Quick Steps to Add "Activity" Record Type

### Step 1: Open CloudKit Dashboard
1. Go to: https://icloud.developer.apple.com/dashboard
2. Sign in with your Apple Developer account
3. Select your container: **`iCloud.cc.crackheadclub.CCApp`**

### Step 2: Navigate to Schema
1. Click on **"Schema"** in the left sidebar
2. Click on **"Record Types"** tab

### Step 3: Create New Record Type
1. Click the **"+"** button (or "Add Record Type" button)
2. In the "Record Type Name" field, type exactly: **`Activity`** (capital A, lowercase rest)
3. Click **"Create"** or **"Save"**

### Step 4: Add Fields
Add these fields one by one (click "Add Field" for each):

#### Field 1: `id`
- **Field Name**: `id`
- **Type**: **String**
- **Required**: ✅ Yes
- **Indexes**: None needed

#### Field 2: `name`
- **Field Name**: `name`
- **Type**: **String**
- **Required**: ✅ Yes
- **Indexes**: 
  - ✅ **Queryable** (IMPORTANT - check this box!)
  - ❌ Sortable (leave unchecked)

#### Field 3: `createdAt`
- **Field Name**: `createdAt`
- **Type**: **Date/Time** (NOT String!)
- **Required**: ✅ Yes
- **Indexes**: None needed

#### Field 4: `userCloudKitID`
- **Field Name**: `userCloudKitID`
- **Type**: **String**
- **Required**: ❌ No (optional)
- **Indexes**: 
  - ✅ **Queryable** (IMPORTANT - check this box!)
  - ❌ Sortable (leave unchecked)

### Step 5: Deploy Schema
1. After adding all fields, look for a button that says **"Deploy Schema Changes"** or **"Deploy"**
2. Click it
3. Confirm the deployment
4. Wait for it to complete (usually takes a few seconds)

### Step 6: Verify
1. You should now see **"Activity"** in your list of Record Types alongside "Entry" and "UserProfile"
2. Click on "Activity" to verify all 4 fields are there:
   - ✅ `id` (String)
   - ✅ `name` (String) - with Queryable index
   - ✅ `createdAt` (Date/Time) - NOT String!
   - ✅ `userCloudKitID` (String) - with Queryable index

## That's It! 🎉

Once deployed, your app will be able to save and sync activities across all devices via CloudKit.

## Troubleshooting

If you see errors when saving activities:
- Make sure "Activity" is spelled exactly (capital A)
- Verify both `name` and `userCloudKitID` have "Queryable" checked
- Make sure you clicked "Deploy Schema Changes"
