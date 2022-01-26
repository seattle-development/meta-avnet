#!/bin/sh

source /usr/local/bin/gpio/gpio_common.sh

BASE_A0010000=$(get_gpiochip_base a0010000)
BASE_A0030000=$(get_gpiochip_base a0030000)
BASE_ZYNQMP_GPIO=$(get_gpiochip_base zynqmp_gpio)

echo PS_LED1:$((BASE_ZYNQMP_GPIO + 26)):out:1 > $GPIO_CONF

for i in $(seq 0 2); do
    echo SW$((i + 2)):$((BASE_A0030000 + i)):in >> $GPIO_CONF
done

for i in $(seq 8); do
    echo SW5_$i:$((BASE_A0010000 + i - 1)):in >> $GPIO_CONF
done