#!/bin/bash

echo "========================================"
echo "  PUBG Mobile v4.3.0 Offset Güncelleme"
echo "========================================"
echo ""

# Yedek al
cp metalbiew.mm metalbiew.mm.backup.v4.2.0
echo "✅ Yedek alındı: metalbiew.mm.backup.v4.2.0"

# Eski offsetleri göster
echo ""
echo "📋 ESKİ OFFSETLER (v4.2.0):"
grep -n "#define gName\|#define gObject" metalbiew.mm

# Yeni offsetleri güncelle
sed -i '' 's/#define gName 0x[0-9A-Fa-f]*/#define gName 0x104bd8740/' metalbiew.mm
sed -i '' 's/#define gObject 0x[0-9A-Fa-f]*/#define gObject 0x10A34E980/' metalbiew.mm

echo ""
echo "📋 YENİ OFFSETLER (v4.3.0):"
grep -n "#define gName\|#define gObject" metalbiew.mm

echo ""
echo "✅ GÜNCELLEME TAMAMLANDI!"
echo ""
echo "📦 Şimdi derleyin:"
echo "   cd /tmp"
echo "   make clean package"
echo ""
