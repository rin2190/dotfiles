# Dotfiles

Cambios personales sobre end-4/dots-hyprland (illogical-impulse) con Hyprland 0.57 en Linux.

## Visualizador de audio (barras abajo, ancho completo)

- `.config/cava/config_quickshell`: configuración de cava. 64 barras, 30 fps, `sleep_timer = 3`.
- `.config/quickshell/ii/modules/ii/background/widgets/AudioVisualizerWidget.qml`: widget que lanza cava y dibuja las barras en el borde inferior. Hereda de `AbstractBackgroundWidget`, con arrastre desactivado.
- `.config/quickshell/ii/modules/ii/background/Background.qml`: bloque que carga el widget del visualizador, después del reloj.
- `.config/quickshell/ii/modules/common/Config.qml`: entrada por defecto `audioVisualizer` en `background.widgets`.
- `.config/quickshell/ii/modules/settings/BackgroundConfig.qml`: interruptor de activar en la sección Fondo de los ajustes.

## Configuración personal

- `.config/illogical-impulse/config.json`: formato de hora de la barra en 12 horas (`h:mm AP`).
- `.config/hypr/custom/keybinds.lua`: atajos personales de Hyprland.

## Actualizaciones de end-4

Los archivos de código (`Config.qml`, `Background.qml`, `BackgroundConfig.qml`) pueden generar conflictos al actualizar la shell. Si pasa, revisa las líneas marcadas arriba y vuelve a aplicarlas.
