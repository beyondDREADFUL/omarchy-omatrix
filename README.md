# omarchy-omatrix

A dial picker for [Omarchy](https://omarchy.org/) **themes** and **backgrounds**, with type-to-filter. It can replace the stock pickers behind **menu → Style → Theme** and **menu → Style → Background**, and you can switch back with one command.

The dial design comes from **Omatrix** in [dkgamer02ai/omarchy-wallpaper-engine](https://github.com/dkgamer02ai/omarchy-wallpaper-engine) (MIT). That project uses the dial to pick live Wallpaper Engine wallpapers. This plugin keeps the dial and drops the live-wallpaper parts: no `linux-wallpaperengine`, no Steam, no autostart or hooks. It only uses Omarchy's own themes and static backgrounds.

## What it does

- **Themes mode** shows every installed theme, using the previews the stock theme switcher caches in `~/.cache/omarchy/theme-selector/previews`. Choosing one runs `omarchy-theme-set`.
- **Backgrounds mode** shows the current theme's backgrounds, plus any you keep in `~/.config/omarchy/backgrounds/<theme>/`. Choosing one runs `omarchy-theme-bg-set`.

| Action | Control |
|---|---|
| Filter | type (case-insensitive; spaces also match dashes) |
| Delete a filter character | `Backspace` |
| Spin the dial | `←` `→` · scroll · drag |
| Apply | `Enter` · left-click |
| Close | `Esc` · right-click |

## Requirements

- Omarchy with its Quickshell shell (`omarchy-shell`) and the `omarchy plugin` command.

## Install

```bash
omarchy plugin add https://github.com/beyondDREADFUL/omarchy-omatrix.git --enable
```

Open it directly:

```bash
omarchy-shell shell summon io.github.beyonddreadful.omatrix '{"mode":"themes"}'
omarchy-shell shell summon io.github.beyonddreadful.omatrix '{"mode":"backgrounds"}'
```

### Use it for menu → Style

```bash
~/.config/omarchy/plugins/io.github.beyonddreadful.omatrix/bin/omatrix-pickers on
```

This adds a marked block to `~/.config/omarchy/extensions/omarchy-menu.jsonc`. The block overrides the **Theme** and **Background** rows: it copies each row's icon and label from Omarchy's stock menu and changes only the action. Before the first change, the script saves a backup to `omarchy-menu.jsonc.before-omatrix-pickers`. Nothing under `/usr/share/omarchy` is touched.

### Roll back

```bash
~/.config/omarchy/plugins/io.github.beyonddreadful.omatrix/bin/omatrix-pickers off
```

This removes the block, so the menu uses the stock pickers again. `omatrix-pickers status` shows which pickers the menu uses.

## Uninstall

Run `omatrix-pickers off` **first**. Otherwise the menu rows will point at a plugin that no longer exists. Then remove the plugin:

```bash
omarchy plugin remove io.github.beyonddreadful.omatrix
```

## Notes

- Themes mode lists the theme switcher's preview cache. If you add a theme, open the stock switcher once (or run `omatrix-pickers off`, pick a theme, then `on` again) so the cache picks it up.
- Applying a theme restarts the shell, which closes the dial. This is expected.
- If you edit the QML while the shell is running, restart the shell (`omarchy-restart-shell`) to load the change. Hot reload doesn't always pick it up.

## Credits

- Dial design: **Omatrix** from [dkgamer02ai/omarchy-wallpaper-engine](https://github.com/dkgamer02ai/omarchy-wallpaper-engine), MIT. Its copyright notice is kept in [LICENSE](LICENSE).
- [Omarchy](https://omarchy.org/) by DHH.

## License

MIT. See [LICENSE](LICENSE).
