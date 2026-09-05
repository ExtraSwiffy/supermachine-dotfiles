#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
profile_file="${HOME}/.bash_profile"

mkdir -p "${config_home}/quickshell/supermachine"
cp -a "${project_dir}/config/quickshell/supermachine/." "${config_home}/quickshell/supermachine/"
mkdir -p "${config_home}/foot"
install -m 0644 "${project_dir}/config/foot/foot.ini" "${config_home}/foot/foot.ini"

mkdir -p "${config_home}/supermachine"
mkdir -p "${HOME}/.local/bin"
install -m 0755 "${project_dir}/bin/startx" "${HOME}/.local/bin/startx"
install -m 0755 "${project_dir}/bin/supermachine-console-mode" "${HOME}/.local/bin/supermachine-console-mode"
install -m 0755 "${project_dir}/bin/supermachine-system-info" "${HOME}/.local/bin/supermachine-system-info"
install -m 0755 "${project_dir}/bin/steamos-session-select" "${HOME}/.local/bin/steamos-session-select"
install -m 0755 "${project_dir}/bin/steamos-session-select" "${HOME}/.local/bin/return-to-gaming-mode"
install -m 0755 "${project_dir}/bin/supermachine-shell" "${HOME}/.local/bin/supermachine-shell"
install -m 0755 "${project_dir}/bin/supermachine-diagnostics" "${HOME}/.local/bin/supermachine-diagnostics"
install -m 0755 "${project_dir}/bin/supermachine-terminal" "${HOME}/.local/bin/supermachine-terminal"
install -m 0755 "${project_dir}/bin/supermachine-install-age" "${HOME}/.local/bin/supermachine-install-age"
install -m 0755 "${project_dir}/bin/supermachine-config-files" "${HOME}/.local/bin/supermachine-config-files"
install -m 0644 "${project_dir}/config/supermachine/terminal.bashrc" "${config_home}/supermachine/terminal.bashrc"
mkdir -p "${config_home}/systemd/user"
install -m 0644 "${project_dir}/systemd/supermachine-shell.service" "${config_home}/systemd/user/supermachine-shell.service"
systemctl --user daemon-reload >/dev/null 2>&1 || true
systemctl --user enable supermachine-shell.service >/dev/null 2>&1 || true
touch "${profile_file}"
if grep -q 'SUPERMACHINE AUTO START' "${profile_file}"; then
    sed -i 's/ && ! -e "$HOME\/.config\/supermachine\/console-mode"//' "${profile_file}"
fi
if ! grep -q 'SUPERMACHINE AUTO START' "${profile_file}"; then
    printf '%s\n' \
        '' \
        '# SUPERMACHINE AUTO START' \
        '# Start the persistent SuperMachine desktop or console session on TTY1.' \
        'if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" && "$(tty)" == "/dev/tty1" ]]; then' \
        '    exec "$HOME/.local/bin/startx"' \
        'fi' >> "${profile_file}"
fi

if [[ "${1:-}" != "--shell-only" ]]; then
    mkdir -p "${config_home}/hypr"
    cp "${project_dir}/config/hypr/hyprland.lua" "${config_home}/hypr/hyprland.lua"
    if [[ ! -f "${config_home}/hypr/monitors.lua" ]]; then
        cp "${project_dir}/config/hypr/monitors.lua.example" "${config_home}/hypr/monitors.lua"
    fi
fi

echo "SuperMachine 2.0 configuration deployed."
