case "$(uname -s)" in
  Darwin*) export OS_TYPE="macos" ;;
  Linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      export OS_TYPE="wsl"
    else
      export OS_TYPE="linux"
    fi
    ;;
  *) export OS_TYPE="unknown" ;;
esac
