# Mayora Firestore Migration Helper Script
# This script helps you migrate your Firestore data to the new hierarchical structure

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  Mayora Firestore Data Migration Helper" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$ORG_ID = "pWiofGzlPXMfoBNoMbP6"
$SCRIPTS_DIR = "scripts"
$SERVICE_ACCOUNT_KEY = "$SCRIPTS_DIR\serviceAccountKey.json"

# Check if we're in the right directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "ERROR: Please run this script from the project root directory!" -ForegroundColor Red
    exit 1
}

# Check if scripts directory exists
if (-not (Test-Path $SCRIPTS_DIR)) {
    Write-Host "ERROR: Scripts directory not found!" -ForegroundColor Red
    exit 1
}

# Check for service account key
if (-not (Test-Path $SERVICE_ACCOUNT_KEY)) {
    Write-Host ""
    Write-Host "[!] SERVICE ACCOUNT KEY NOT FOUND" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You need to download your Firebase service account key:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://console.firebase.google.com" -ForegroundColor White
    Write-Host "2. Select your project" -ForegroundColor White
    Write-Host "3. Go to: Project Settings > Service Accounts" -ForegroundColor White
    Write-Host "4. Click 'Generate New Private Key'" -ForegroundColor White
    Write-Host "5. Save the file as: $SERVICE_ACCOUNT_KEY" -ForegroundColor White
    Write-Host ""
    
    $response = Read-Host "Do you have the service account key ready? (y/n)"
    if ($response -ne "y") {
        Write-Host "Please download the key first, then run this script again." -ForegroundColor Yellow
        exit 0
    }
}

# Set environment variable
$env:GOOGLE_APPLICATION_CREDENTIALS = (Resolve-Path $SERVICE_ACCOUNT_KEY).Path
Write-Host "[OK] Firebase credentials configured" -ForegroundColor Green

# Check if node_modules exists
Push-Location $SCRIPTS_DIR
if (-not (Test-Path "node_modules")) {
    Write-Host ""
    Write-Host "[*] Installing dependencies..." -ForegroundColor Cyan
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to install dependencies!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Write-Host "[OK] Dependencies installed" -ForegroundColor Green
}
Pop-Location

Write-Host ""
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  Organization ID: $ORG_ID" -ForegroundColor White
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""

# Menu
while ($true) {
    Write-Host ""
    Write-Host "Select an option:" -ForegroundColor Cyan
    Write-Host "  1) Dry run - see what will be migrated" -ForegroundColor White
    Write-Host "  2) Run actual migration" -ForegroundColor White
    Write-Host "  3) Deploy new Firestore rules" -ForegroundColor White
    Write-Host "  4) Run Flutter app to test" -ForegroundColor White
    Write-Host "  5) Scan for duplicate users (by email)" -ForegroundColor White
    Write-Host "  6) Merge duplicate users (org scope)" -ForegroundColor White
    Write-Host "  7) Exit" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1-7)"
    
    switch ($choice) {
        "1" {
            Write-Host ""
            Write-Host "[RUN] Running DRY RUN migration..." -ForegroundColor Cyan
            Write-Host "This will show what would be migrated WITHOUT changing data" -ForegroundColor Yellow
            Write-Host ""
            
            Push-Location $SCRIPTS_DIR
            npm run migrate-org -- --org-id=$ORG_ID --dry-run
            Pop-Location
            
            Write-Host ""
            Write-Host "Press Enter to continue..."
            Read-Host
        }
        
        "2" {
            Write-Host ""
            Write-Host "[WARNING] This will ACTUALLY migrate your data!" -ForegroundColor Yellow
            Write-Host "Make sure you've run the dry run first - option 1" -ForegroundColor Yellow
            Write-Host ""
            
            $confirm = Read-Host "Are you sure you want to proceed? (yes/no)"
            if ($confirm -eq "yes") {
                Write-Host ""
                Write-Host "[RUN] Running ACTUAL migration..." -ForegroundColor Cyan
                Write-Host ""
                
                Push-Location $SCRIPTS_DIR
                npm run migrate-org -- --org-id=$ORG_ID
                Pop-Location
                
                Write-Host ""
                Write-Host "[SUCCESS] Migration complete!" -ForegroundColor Green
                Write-Host "Next: Choose option 3 to deploy new Firestore rules" -ForegroundColor Cyan
            } else {
                Write-Host "Migration cancelled." -ForegroundColor Yellow
            }
            
            Write-Host ""
            Write-Host "Press Enter to continue..."
            Read-Host
        }
        
        "3" {
            Write-Host ""
            Write-Host "[DEPLOY] Deploying new Firestore rules..." -ForegroundColor Cyan
            Write-Host ""
            
            # Check if firestore.rules.new exists
            if (-not (Test-Path "firestore.rules.new")) {
                Write-Host "ERROR: firestore.rules.new not found!" -ForegroundColor Red
            } else {
                # Backup old rules
                if (Test-Path "firestore.rules") {
                    Copy-Item "firestore.rules" "firestore.rules.backup" -Force
                    Write-Host "[OK] Backed up old rules to firestore.rules.backup" -ForegroundColor Green
                }
                
                # Copy new rules
                Copy-Item "firestore.rules.new" "firestore.rules" -Force
                Write-Host "[OK] Updated firestore.rules" -ForegroundColor Green
                
                # Deploy rules and indexes
                Write-Host ""
                Write-Host "Deploying Firestore rules and indexes to Firebase..." -ForegroundColor Cyan
                firebase deploy --only firestore
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host ""
                    Write-Host "[SUCCESS] Firestore rules and indexes deployed successfully!" -ForegroundColor Green
                } else {
                    Write-Host ""
                    Write-Host "ERROR: Failed to deploy rules/indexes. Check Firebase CLI is installed and you're logged in." -ForegroundColor Red
                }
            }
            
            Write-Host ""
            Write-Host "Press Enter to continue..."
            Read-Host
        }
        
        "4" {
            Write-Host ""
            Write-Host "[RUN] Starting Flutter app..." -ForegroundColor Cyan
            Write-Host ""
            
            flutter run -d chrome
            
            Write-Host ""
            Write-Host "Press Enter to continue..."
            Read-Host
        }
        
        "5" {
            Write-Host "" 
            Write-Host "[SCAN] Looking for duplicate users by email in organizations/$ORG_ID/users ..." -ForegroundColor Cyan
            Write-Host ""

            Push-Location $SCRIPTS_DIR
            node scan_duplicate_org_users.cjs --org-id=$ORG_ID
            Pop-Location

            Write-Host ""
            Write-Host "Press Enter to continue..."
            Read-Host
        }

        "6" {
            Write-Host ""
            Write-Host "[MERGE] Merge two user docs within organization scope" -ForegroundColor Cyan
            Write-Host "This will copy top-level fields and subcollections (schedules/leaves/etc.) from SOURCE -> TARGET" -ForegroundColor Yellow
            Write-Host ""

            $source = Read-Host "Enter SOURCE userId (to merge FROM)"
            $target = Read-Host "Enter TARGET userId (to merge INTO)"
            $dry = Read-Host "Dry run first? (y/n)"
            $noDel = Read-Host "Keep source after copy (no delete)? (y/n)"

            $dryFlag = if ($dry -eq "y") { "--dry-run" } else { "" }
            $noDelFlag = if ($noDel -eq "y") { "--no-delete" } else { "" }

            Push-Location $SCRIPTS_DIR
            node merge_org_user_docs.cjs --org-id=$ORG_ID --source=$source --target=$target $dryFlag $noDelFlag
            Pop-Location

            Write-Host ""
            Write-Host "Press Enter to continue..."
            Read-Host
        }

        "7" {
            Write-Host ""
            Write-Host "Goodbye!" -ForegroundColor Cyan
            exit 0
        }
        
        default {
            Write-Host ""
            Write-Host "Invalid choice. Please enter 1-7." -ForegroundColor Red
        }
    }
}
