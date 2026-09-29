#!/usr/bin/env bash

# Detener el script si falla cualquier comando o variable no definida
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

log_info "Iniciando instalación optimizada de Anaconda/Jupyter para Ubuntu..."

# 1. Comprobar que es un sistema basado en Debian/Ubuntu
if [ ! -f /etc/debian_version ]; then
    log_warn "Este script está optimizado para Ubuntu/Debian."
fi

# 2. Actualizar repositorios e instalar librerías nativas requeridas por Anaconda y compiladores
log_info "Actualizando repositorios e instalando dependencias del sistema Ubuntu..."
sudo apt-get update -y
sudo apt-get install -y \
    curl \
    wget \
    bzip2 \
    ca-certificates \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxrender1 \
    mercurial \
    subversion \
    build-essential \
    libgl1-mesa-glx \
    git

# 3. Detectar la URL de la última versión de Anaconda Linux x86_64
log_info "Buscando la versión más reciente de Anaconda..."
ANACONDA_URL=$(curl -s https://repo.anaconda.com/archive/ | grep -oP 'Anaconda3-[0-9\.]+-Linux-x86_64\.sh' | head -n 1)

if [ -z "$ANACONDA_URL" ]; then
    log_warn "No se pudo obtener la versión dinámicamente. Utilizando versión fallback..."
    ANACONDA_URL="Anaconda3-2024.06-1-Linux-x86_64.sh"
fi

DOWNLOAD_URL="https://repo.anaconda.com/archive/${ANACONDA_URL}"
INSTALLER_PATH="/tmp/${ANACONDA_URL}"

# 4. Descargar el instalador
log_info "Descargando ${ANACONDA_URL}..."
wget --quiet --show-progress "${DOWNLOAD_URL}" -O "${INSTALLER_PATH}"

# 5. Ejecutar la instalación silenciosa
INSTALL_DIR="$HOME/anaconda3"

if [ -d "$INSTALL_DIR" ]; then
    log_warn "El directorio $INSTALL_DIR ya existe. Se procederá con la actualización/reinstalación..."
    bash "${INSTALLER_PATH}" -b -u -p "${INSTALL_DIR}"
else
    log_info "Instalando en ${INSTALL_DIR}..."
    bash "${INSTALLER_PATH}" -b -p "${INSTALL_DIR}"
fi

# Limpieza del instalador temporal
rm -f "${INSTALLER_PATH}"

# 6. Configurar la integración con el Shell (Bash y Zsh si existe)
log_info "Configurando el entorno de consola..."
"${INSTALL_DIR}/bin/conda" init bash
if [ -f "$HOME/.zshrc" ]; then
    "${INSTALL_DIR}/bin/conda" init zsh
fi

# 7. Desactivar autoactivación de entorno base y habilitar solver libmamba (ultra-rápido)
"${INSTALL_DIR}/bin/conda" config --set auto_activate_base false
"${INSTALL_DIR}/bin/conda" config --set solver libmamba 2>/dev/null || true

log_success "=== ¡Instalación completada correctamente en Ubuntu! ==="
echo ""
echo -e "Para activar Anaconda en esta misma terminal, ejecuta:"
echo -e "  ${GREEN}source ~/.bashrc${NC}"
echo ""
echo -e "Para verificar los comandos principales:"
echo -e "  ${BLUE}conda activate base${NC}"
echo -e "  ${BLUE}jupyter lab${NC}"