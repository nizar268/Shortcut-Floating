#!/bin/bash
set -e

# ProjectDeck Automated Backup Script
# Overwrites the existing backup in ./backup/latest

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$PROJECT_DIR/backup/latest"
ZIP_BACKUP="$PROJECT_DIR/backup/projectdeck_backup_latest.zip"

echo "📦 Starting ProjectDeck source code backup..."

# Create backup directory structure
mkdir -p "$BACKUP_DIR"

# Clean previous mirror backup
rm -rf "$BACKUP_DIR"/*

# Copy source code and configuration files
echo "📂 Copying project files..."
cp -R "$PROJECT_DIR/Package.swift" "$BACKUP_DIR/"
cp -R "$PROJECT_DIR/ProjectDeck" "$BACKUP_DIR/"
cp -R "$PROJECT_DIR/scripts" "$BACKUP_DIR/"
[ -f "$PROJECT_DIR/README.md" ] && cp -R "$PROJECT_DIR/README.md" "$BACKUP_DIR/"
[ -d "$PROJECT_DIR/ProjectDeck.xcodeproj" ] && cp -R "$PROJECT_DIR/ProjectDeck.xcodeproj" "$BACKUP_DIR/"

# Exclude build artifacts if any accidentally got copied
rm -rf "$BACKUP_DIR/ProjectDeck/.build" "$BACKUP_DIR/ProjectDeck/build"

# Write Backup Info & Manifest
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
cat <<EOF > "$BACKUP_DIR/BACKUP_INFO.txt"
ProjectDeck Source Backup
Created At: $TIMESTAMP
Status: Ready for restore
Included Components:
- Package.swift
- ProjectDeck/ (All Models, Views, Controllers, Managers, Settings, Resources)
- scripts/
- README.md
- ProjectDeck.xcodeproj (if present)
EOF

# Create ZIP archive backup
echo "🗜️  Creating backup ZIP archive..."
cd "$BACKUP_DIR"
rm -f "$ZIP_BACKUP"
zip -r -q "$ZIP_BACKUP" . -x "*.DS_Store"

echo "✅ Backup successfully created at:"
echo "   - Directory: $BACKUP_DIR"
echo "   - Archive  : $ZIP_BACKUP"
echo "   - Timestamp: $TIMESTAMP"
