#!/usr/bin/env bash
set -euo pipefail

# Scan modules for execute.sh scripts
MODULES=($(ls -d modules/*/ 2>/dev/null))
MENU=()
for d in "${MODULES[@]}"; do
  name=$(basename "$d")
  if [[ -f "$d/execute.sh" ]]; then
    MENU+=("$name")
  fi
done

if [[ ${#MENU[@]} -eq 0 ]]; then
  echo modules found."; exit 1
fi

SELECTED=0

draw_menu() {
  clear
  echo "StratoShell - Module selection"
  echo "--------------------------------"
  for i in "${!MENU[@]}"; do
    if [[ $i -eq $SELECTED ]]; then
      echo -e "> \e[7m${MENU[$i]}\e[0m"
    else
      echo "  ${MENU[$i]}"
    fi
  done
  echo "\nUse ↑/↓ arrows, Enter to run, q to quit"
}

while true; do
  draw_menu
  read -rsn1 key
  case "$key" in
    $'\x1b') # escape sequence
      read -rsn2 -t 0.001 key
      case "$key" in
        '[A') ((SELECTED--)); ((SELECTED<0)) && SELECTED=$((${#MENU[@]}-1));;
        '[B') ((SELECTED++)); ((SELECTED>=${#MENU[@]})) && SELECTED=0;;
      esac
      ;;
    "") # Enter
      MOD="${MENU[$SELECTED]}"
      ./modules/"$MOD"/execute.sh
      read -p "Press ENTER to return to menu..."
      ;;
    q) exit 0;;
  esac
done
