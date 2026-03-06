#!/bin/bash
set -e
echo "=== Conti Design Token Lint ==="

# Count raw SizedBox gaps in screens
RAW_H=$(grep -r "SizedBox(height: [0-9]" lib/screens/ 2>/dev/null | wc -l | tr -d ' ')
echo "Raw SizedBox(height:) in screens: $RAW_H"

RAW_W=$(grep -r "SizedBox(width: [0-9]" lib/screens/ 2>/dev/null | grep -v "CircularProgressIndicator" | wc -l | tr -d ' ')
echo "Raw SizedBox(width:) in screens: $RAW_W"

RAW_BR=$(grep -r "BorderRadius.circular([0-9]" lib/screens/ 2>/dev/null | wc -l | tr -d ' ')
echo "Raw BorderRadius.circular() in screens: $RAW_BR"

RAW_COLOR=$(grep -r "Color(0x" lib/screens/ 2>/dev/null | wc -l | tr -d ' ')
echo "Raw Color(0x) in screens: $RAW_COLOR"

echo ""
echo "=== Baseline (pre-Slice 1): SizedBox(h)=79, SizedBox(w)=38, BorderRadius=46, Color=6 ==="
echo "=== Target (post-Slice 1): SizedBox(h)<=73, BorderRadius<=36, Color<=2 ==="
