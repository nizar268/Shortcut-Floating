#!/bin/bash
set -e

# ProjectDeck Automated Restore Script
# Restores all project files from ./backup/latest

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$PROJECT_DIR/backup/latest"

if [ ! -d "$BACKUP_DIR" ] || [ ! -f "$BACKUP_DIR/Package.swift" ]; then
    echo "❌ Error: No valid backup found in $BACKUP_DIR"
    exit 1
fi

echo "🔄 Restoring ProjectDeck from backup..."
[ -f "$BACKUP_DIR/BACKUP_INFO.txt" ] && cat "$BACKUP_DIR/BACKUP_INFO.txt"
echo ""

# Restore files
cp -R "$BACKUP_DIR/Package.swift" "$PROJECT_DIR/"
cp -R "$BACKUP_DIR/ProjectDeck" "$PROJECT_DIR/"
cp -R "$BACKUP_DIR/scripts" "$PROJECT_DIR/"
[ -f "$BACKUP_DIR/README.md" ] && cp -R "$BACKUP_DIR/README.md" "$PROJECT_DIR/"
[ -d "$BACKUP_DIR/ProjectDeck.xcodeproj" ] && cp -R "$BACKUP_DIR/ProjectDeck.xcodeproj" "$PROJECT_DIR/"

chmod +x "$PROJECT_DIR/scripts"/*.sh

echo "✅ Restore completed successfully."
echo "💡 You can re-build the app now using: ./scripts/build_app.sh"
