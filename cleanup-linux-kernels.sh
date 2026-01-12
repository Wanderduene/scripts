#!/bin/bash

# Ausgabe
echo "## Delete Linux Kernels ##"
echo ""

# Aktuellen Kernel ermitteln
CURRENT_KERNEL=$(uname -r)

# Alle installierten Kernel auflisten und sortieren
KERNELS=($(dpkg --list | grep linux-image | awk '{print $2}' | grep -v "$CURRENT_KERNEL" | sort -Vr))

# Auflistung
echo "Folgende Kernel wurden gefunden:"
for (( i=0; i<${#KERNELS[@]}; i++ )); do
 echo ${KERNELS[$i]}
done

echo "---"

# Prüfen, ob es mehr als 3 Kernel gibt
if [ ${#KERNELS[@]} -le 3 ]; then
    echo "Es sind nur ${#KERNELS[@]} Kernel installiert. Es wird nichts gelöscht."
    exit 0
fi

# Alle Kernel bis auf die drei aktuellsten löschen
for (( i=3; i<${#KERNELS[@]}; i++ )); do
    KERNEL_TO_REMOVE="${KERNELS[$i]}"
    echo "Lösche Kernel: $KERNEL_TO_REMOVE"
    sudo apt purge -y "$KERNEL_TO_REMOVE"

    # Entsprechende Header löschen
    HEADERS_TO_REMOVE=$(dpkg --list | grep linux-headers | awk '{print $2}' | grep "${KERNEL_TO_REMOVE#linux-image-}")
    if [ -n "$HEADERS_TO_REMOVE" ]; then
        echo "Lösche Header: $HEADERS_TO_REMOVE"
        sudo apt purge -y "$HEADERS_TO_REMOVE"
    fi
done

echo "---"

# GRUB aktualisieren
echo "Aktualisiere GRUB..."
sudo update-grub

# Nicht mehr benötigte Pakete bereinigen
echo "Bereinige nicht mehr benötigte Pakete..."
sudo apt autoremove -y

echo ""

echo "Fertig. Bitte das System neu starten, um die Änderungen zu übernehmen."
