#!/bin/bash
# SessionStart hook - ensures beads (bd) is available in every Claude Code web session

set -e

# Add Go bin to PATH for this session
if [ -n "$CLAUDE_ENV_FILE" ]; then
    echo "export PATH=\"\$PATH:/root/go/bin\"" >> "$CLAUDE_ENV_FILE"
fi

# Check if bd is installed
if ! command -v /root/go/bin/bd &> /dev/null; then
    echo "⚙️  Installing beads (bd command)..."
    go install github.com/steveyegge/beads/cmd/bd@latest
    echo "✓ Beads installed successfully"
else
    echo "✓ Beads already installed"
fi

# Verify installation
if [ -x "/root/go/bin/bd" ]; then
    BD_VERSION=$(/root/go/bin/bd version 2>/dev/null | head -n1 || echo "unknown")
    echo "✓ Beads ready: $BD_VERSION"
else
    echo "⚠️  Warning: beads installation may have failed"
fi
