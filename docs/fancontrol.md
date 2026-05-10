# Thorch Fan Curve Quick Guide

Thorch controls the Thor fan with `thorch-fancontrol`. The service reads
temperatures from thermal sysfs sensors, chooses a PWM value from the configured
profile, and writes that value to the fan PWM sysfs node.

When multiple thermal sensors are readable, Thorch follows the hottest selected
sensor by default. This reacts more like Android thermal policy than a broad
sensor average, where idle or cooler zones can hide a hot CPU/GPU spot.

For a quieter or more aggressive curve, start with the built-in profiles:

```bash
sudo sed -i 's/^THORCH_FAN_PROFILE=.*/THORCH_FAN_PROFILE=quiet/' /etc/thorch/fancontrol.conf
sudo systemctl restart thorch-fancontrol.service
sudo thorch-fancontrol status
```

`THORCH_FAN_PROFILE` can be:

- `quiet`: later fan ramp, lower noise.
- `moderate`: balanced default.
- `aggressive`: earlier fan ramp.
- `custom`: user-defined temperature thresholds and PWM speeds.

## Custom Curve

Persistent settings live in `/etc/thorch/fancontrol.conf`. Temperatures are in
millidegrees Celsius, so `65000` means 65 C. PWM speeds are integers from `0` to
`255`.

Edit the config:

```bash
sudo nano /etc/thorch/fancontrol.conf
```

Example custom curve:

```bash
THORCH_FAN_PROFILE=custom
THORCH_FAN_POLL_SECONDS=3
THORCH_FAN_SENSOR_MODE=max

THORCH_FAN_T1=50000
THORCH_FAN_T2=55000
THORCH_FAN_T3=60000
THORCH_FAN_T4=65000
THORCH_FAN_T5=70000
THORCH_FAN_T6=75000
THORCH_FAN_MAX_TEMP=80000

THORCH_FAN_SPEED1=51
THORCH_FAN_SPEED2=77
THORCH_FAN_SPEED3=102
THORCH_FAN_SPEED4=119
THORCH_FAN_SPEED5=153
THORCH_FAN_SPEED6=204
THORCH_FAN_MAX_SPEED=255
```

Then restart the service:

```bash
sudo systemctl restart thorch-fancontrol.service
sudo thorch-fancontrol status
```

The fan uses the first speed whose threshold has been crossed. For example,
with the custom curve above:

- At or below 50 C, the target PWM is `0`.
- Above 50 C, the target PWM is `51`.
- Above 60 C, the target PWM is `102`.
- Above 80 C, the target PWM is `255`.

Thresholds must increase from `THORCH_FAN_T1` through
`THORCH_FAN_MAX_TEMP`. Speeds may stay flat or increase, but values outside
`0..255` are rejected.

## Testing

Check the detected PWM path, selected sensors, current control temperature, and
target PWM:

```bash
sudo thorch-fancontrol status
```

Apply the current curve once without leaving a daemon running:

```bash
sudo systemctl stop thorch-fancontrol.service
sudo thorch-fancontrol once
```

Start the normal boot service again:

```bash
sudo systemctl enable --now thorch-fancontrol.service
```

Follow service logs while tuning:

```bash
journalctl -fu thorch-fancontrol.service
```

## Sensor And PWM Overrides

Most users should leave hardware paths empty so Thorch can autodetect them. For
bring-up or debugging, the config can pin paths explicitly:

```bash
THORCH_FAN_PWM_PATH=/sys/class/hwmon/hwmon0/pwm1
THORCH_FAN_TEMP_SENSORS="/sys/devices/virtual/thermal/thermal_zone0/temp /sys/devices/virtual/thermal/thermal_zone1/temp"
```

`THORCH_FAN_TEMP_SENSORS` is a space-separated list. When more than one sensor
is configured, `THORCH_FAN_SENSOR_MODE=max` uses the hottest readable value
before selecting the fan speed. Set `THORCH_FAN_SENSOR_MODE=average` to restore
the quieter ROCKNIX-style broad sensor average.

## Safety Notes

Lower-noise curves also mean higher temperatures. Keep a terminal open with
`thorch-fancontrol status` or `journalctl -fu thorch-fancontrol.service` while
tuning, and avoid disabling the service for normal use.

If a custom curve fails validation, `thorch-fancontrol` exits without applying
it. Fix `/etc/thorch/fancontrol.conf`, then restart the service.
