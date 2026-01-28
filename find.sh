#!/usr/bin/env bash
# find.sh - Fully hybrid CLI + Interactive with flexible list/cat anywhere

set -euo pipefail

# -------------------------------
# Colors
# -------------------------------
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
NC="\033[0m"

# -------------------------------
# FUNCTIONS
# -------------------------------

# Build find pattern from extensions
build_find_pattern() {
  local pattern=""
  for ext in "${exts[@]}"; do
    pattern="$pattern -o -name '*.$ext'"
  done
  pattern="${pattern# -o }"
  echo "$pattern"
}

# CLI: list matching files
list_files_cli() {
  local pattern
  pattern=$(build_find_pattern)
  mapfile -t files < <(eval "find . -type f \( $pattern \) | sort")
  [[ ${#files[@]} -eq 0 ]] && { echo -e "${RED}❌ No matching files found.${NC}"; return; }
  for f in "${files[@]}"; do
    echo -e "${YELLOW}$f${NC}"
  done
}

# CLI: cat/show matching files
cat_files_cli() {
  local pattern
  pattern=$(build_find_pattern)
  mapfile -t files < <(eval "find . -type f \( $pattern \) | sort")
  [[ ${#files[@]} -eq 0 ]] && { echo -e "${RED}❌ No matching files found.${NC}"; return; }
  for f in "${files[@]}"; do
    echo -e "${GREEN}==================== $f ====================${NC}"
    cat "$f"
    echo
  done
}

# Interactive: list all files in current directory (no extension filter)
list_all_files_current_dir() {
  echo -e "${CYAN}🔹 Listing all files in current directory${NC}"
  echo
  mapfile -t files < <(find . -maxdepth 1 -type f | sort)
  [[ ${#files[@]} -eq 0 ]] && { echo -e "${RED}❌ No files found.${NC}"; return; }
  for f in "${files[@]}"; do
    echo -e "${YELLOW}$f${NC}"
  done
}

# Interactive: preview a single file
preview_a_file() {
  read -rp "Enter file path to preview: " file
  if [[ ! -f "$file" ]]; then
    echo -e "${RED}❌ File not found: $file${NC}"
    return
  fi
  echo -e "${GREEN}----- Start of $file -----${NC}"
  cat "$file"
  echo -e "${GREEN}----- End of $file -----${NC}"
}

# Interactive: preview all matching files
preview_all_files() {
  echo -e "${CYAN}🔹 Previewing all matching files${NC}"
  cat_files_cli
}

# Interactive: preview matching files in a directory
preview_dir_files() {
  read -rp "Enter directory path: " dir
  if [[ ! -d "$dir" ]]; then
    echo -e "${RED}❌ Directory not found: $dir${NC}"
    return
  fi
  local pattern
  pattern=$(build_find_pattern)
  local dir_path
  dir_path="$(realpath "$dir")"
  mapfile -t files < <(eval "find \"$dir_path\" -type f \( $pattern \) | sort")
  [[ ${#files[@]} -eq 0 ]] && { echo -e "${RED}❌ No files found in $dir_path${NC}"; return; }
  for f in "${files[@]}"; do
    echo -e "${GREEN}==================== $f ====================${NC}"
    cat "$f"
    echo
  done
}

# -------------------------------
# MENU
# -------------------------------
show_menu() {
  echo "----------------------------------------"
  echo "Dynamic File Explorer - $(pwd)"
  echo "1) List all files in current directory"
  echo "2) Preview a single file"
  echo "3) Preview all matching files"
  echo "4) Preview all matching files in a directory"
  echo "0) Exit"
  echo "----------------------------------------"
}

interactive_mode() {
  while true; do
    show_menu
    read -rp "Choose an option: " choice
    case "$choice" in
      1) list_all_files_current_dir ;;
      2) preview_a_file ;;
      3) preview_all_files ;;
      4) preview_dir_files ;;
      0) echo "Exiting."; exit 0 ;;
      *) echo -e "${RED}Invalid choice${NC}" ;;
    esac
    echo
  done
}

# -------------------------------
# MAIN
# -------------------------------

if [[ $# -gt 0 ]]; then
  # CLI: mode can appear anywhere
  mode="list"  # default
  exts=()
  for arg in "$@"; do
    case "$arg" in
      list|cat|show) mode="$arg" ;;
      *) exts+=("$arg") ;;
    esac
  done

  # Default extensions if none supplied
  [[ ${#exts[@]} -eq 0 ]] && exts=("yml" "yaml" "yml.j2")

  # Show what we are doing
  echo -e "${CYAN}🔹 Extensions: ${exts[*]} | Mode: $mode${NC}"

  # Execute CLI
  if [[ "$mode" == "list" ]]; then
    list_files_cli
  else
    cat_files_cli
  fi
  exit 0
else
  # Interactive mode
  exts=("yml" "yaml" "yml.j2")
  interactive_mode
fi
