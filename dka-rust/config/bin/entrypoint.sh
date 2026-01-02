#!/bin/sh

HOSTNAME=$(hostname)

# ==============================================================================
# BANNER START
# ==============================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
echo ""
echo -e "${CYAN}======================================================================${NC}"
echo -e "${GREEN}   RUST APPLICATION CONTAINER${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo "   Author   : Yovangga Anandhika"
echo "   Email    : dka.tech.dev@gmail.com"
echo "   GitHub   : https://github.com/YovanggaAnandhika"
echo -e "${CYAN}======================================================================${NC}"
echo ""
# ==============================================================================
# BANNER END
# ==============================================================================
# 1. Cek apakah ada argumen dari command line (docker run ...)
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    # --------------------------------------------------------------------------
    # 2. MODE DEVELOPMENT (Prioritas Utama)
    # --------------------------------------------------------------------------
    # Cek apakah ada file Cargo.toml DAN perintah 'cargo' terinstall
    if [ -f "Cargo.toml" ] && command -v cargo > /dev/null 2>&1; then
        echo -e "${GREEN}[INFO] Development Environment detected (Cargo.toml found).${NC}"
        # Cek apakah 'cargo-watch' sudah terinstall
        if cargo watch --version > /dev/null 2>&1; then
            echo -e "${GREEN}[INFO] Using 'cargo watch' to auto-reload on change...${NC}"
            exec cargo watch -x run
        else
            echo -e "${GREEN}[INFO] 'cargo-watch' not found. Fallback to 'cargo run'...${NC}"
            exec cargo run
        fi
    # --------------------------------------------------------------------------
    # 3. MODE PRODUCTION / BINARY ONLY (Fallback)
    # --------------------------------------------------------------------------
    # Jika tidak ada Cargo.toml, cari file binary yang sudah di-compile
    # Prioritas 1: Cek folder RELEASE
    elif [ -f "./target/release/app" ]; then
        echo -e "${GREEN}[INFO] Found Release Binary. Starting application...${NC}"
        exec ./target/release/app
    # Prioritas 2: Cek folder DEBUG
    elif [ -f "./target/debug/app" ]; then
        echo -e "${GREEN}[INFO] Found Debug Binary. Starting application...${NC}"
        exec ./target/debug/app
    # Prioritas 3: Cek folder Root (Legacy/Manual copy)
    elif [ -f "./app" ]; then
        echo -e "${GREEN}[INFO] Found Root Binary. Starting application...${NC}"
        exec ./app
    # --------------------------------------------------------------------------
    # 4. ERROR HANDLING
    # --------------------------------------------------------------------------
    else
        echo -e "\033[0;31m[ERROR] Start Failed!${NC}"
        echo -e "\033[0;31m        Tidak ditemukan Cargo.toml (Source) maupun binary 'app'.${NC}"
        exit 1
    fi
fi