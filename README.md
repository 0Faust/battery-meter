# Battery Meter (battery-meter)

Плагин для AngelOS: заряд батареи на панели и на рабочем столе. Процент, статус зарядки, оценка оставшегося времени, предупреждения при низком заряде (пороги настраиваются в Settings → Plugins). Пиксельная полоска в стиле angelOS.

Battery plugin for AngelOS: charge percentage, charging status, time estimate and low-battery warnings on the bar and the desktop, with a pixel bar in angelOS style.

## Установка / Install
Через Community Store или вручную:

    cp -a battery-meter ~/.config/angelos/plugins/battery-meter

Затем перезагрузите AngelOS и включите плагин в Settings → Plugins.

## Как работает / How it works
- Ищет первую батарею `/sys/class/power_supply/BAT*` и читает файлы `capacity`, `status`, `energy_now`, `energy_full`, `power_now` раз в 15 секунд.
- Не использует сеть и внешние программы (кроме одного вызова `sh` для поиска батареи).
- Без батареи (десктоп) показывает «нет батареи».

## Ограничения / Limitations
Оценка времени работает, только если система отдаёт `energy_*` и `power_now`. Если у батареи есть только `charge_*` и `current_*`, процент и статус работают, а время не показывается.

## Лицензия / License
MIT, см. LICENSE.
