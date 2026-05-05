# ROCKNIX-derived Qualcomm SM8550 handheld hints for Thorch.
# These are Arch-safe exports adapted from ROCKNIX hardware quirks; the original
# ROCKNIX autostart scripts are preserved under /usr/share/thorch/rocknix-quirks.

export DEVICE_HAS_TOUCHSCREEN="true"
export DEVICE_NO_MAC="true"
export DEVICE_MANGOHUD_SUPPORT="true"
export DEVICE_LED_CONTROL="true"
export DEVICE_BATTERY_LED_STATUS="true"

export DEVICE_PLAYBACK_PATH_SPK="Speakers"
export DEVICE_PLAYBACK_PATH_HP="HP"

export THORCH_DEVICE_TEMP_SENSOR="/sys/devices/virtual/thermal/thermal_zone3/temp"
export THORCH_CPU_FREQ_POLICIES="/sys/devices/system/cpu/cpufreq/policy0 /sys/devices/system/cpu/cpufreq/policy4 /sys/devices/system/cpu/cpufreq/policy7"
export THORCH_GPU_FREQ_PATH="/sys/devices/platform/soc@0/3d00000.gpu/devfreq/3d00000.gpu"

export SLOW_CORES="taskset -c 0-3"
export FAST_CORES="taskset -c 4-7"

export DEVICE_FUNC_KEYA_MODIFIER="BTN_MODE"
export DEVICE_FUNC_KEYB_MODIFIER="BTN_START"

export UI_SHADER="slangp"
export THORCH_ROCKNIX_QUIRKS_DIR="/usr/share/thorch/rocknix-quirks/SM8550"

if [ -z "${SDL_GAMECONTROLLERCONFIG_FILE:-}" ] &&
  [ -f /usr/share/thorch/SDL-GameControllerDB/gamecontrollerdb.txt ]; then
  export SDL_GAMECONTROLLERCONFIG_FILE="/usr/share/thorch/SDL-GameControllerDB/gamecontrollerdb.txt"
fi

if [ -z "${SDL_GAMEPADCONFIG_FILE:-}" ] &&
  [ -f /usr/share/thorch/SDL-GameControllerDB/gamecontrollerdb.txt ]; then
  export SDL_GAMEPADCONFIG_FILE="/usr/share/thorch/SDL-GameControllerDB/gamecontrollerdb.txt"
fi

if [ -z "${SDL_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT:-}" ]; then
  export SDL_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT="${THORCH_SDL_GAMEPAD_IGNORE_EXCEPT:-0x045e/0x0b12}"
fi

if [ -z "${SDL_GAMEPAD_IGNORE_DEVICES_EXCEPT:-}" ]; then
  export SDL_GAMEPAD_IGNORE_DEVICES_EXCEPT="${THORCH_SDL_GAMEPAD_IGNORE_EXCEPT:-0x045e/0x0b12}"
fi
