# Zen: browser styling

`userChrome.css` styles Zen's browser controls with dark neutral surfaces,
soft-grey text, sand accents, and a grey selected tab. It also centers the
inactive address display and reproduces unloaded tabs become grayscale at 50% opacity.

## Install

Stowing `shared` exposes this directory at `~/.config/zen`, but Zen loads CSS
from its active profile's `chrome` directory.

1. Select a dark theme in Zen. The color overrides apply only in dark mode.
2. Open `about:support` and use **Profile Directory → Open Directory** to find
   the active profile. Use this path rather than guessing from `profiles.ini`;
   multiple profiles can coexist.
3. In `about:config`, set
   `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`.
4. Set `profile` below to the actual path. Quit Zen before installing.

```sh
profile="$HOME/.zen/REPLACE_WITH_ACTIVE_PROFILE"
mkdir -p "$profile/chrome"
```

If the profile has no `userChrome.css`, link the dotfiles version:

```sh
ln -s "$HOME/dotfiles/shared/.config/zen/userChrome.css" \
  "$profile/chrome/userChrome.css"
```

If you already have a `userChrome.css`, link this file under a separate name:

```sh
ln -s "$HOME/dotfiles/shared/.config/zen/userChrome.css" \
  "$profile/chrome/solitude.css"
```

Then add this import at the top of the existing `userChrome.css`, before style
rules (after any `@charset` declaration):

```css
@import url("solitude.css");
```

Existing rules later in that file can override imported styles. Adjust the
source path above if the dotfiles repository lives elsewhere.

5. Restart Zen. Future edits through the symlink take effect after restarting.

Reference: [Zen's userChrome guide](https://docs.zen-browser.app/guides/live-editing).
