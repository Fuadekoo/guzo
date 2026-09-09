# Fonts

GUZO ships no font of its own. The default Flutter font covers English letters
and digits, which is everything the English and Numbers modes need.

## Amharic needs an Ethiopic font

No Latin font contains the Ethiopic Unicode block (U+1200–U+137F), so on a
device with no Ethiopic face installed the Amharic modes render every letter as
an empty box (tofu).

Most Android builds carry **Noto Sans Ethiopic**, and `GuzoFonts.ethiopicFallback`
asks for it by name along with a few other common faces. That works on the
majority of devices — but it is a request, not a guarantee, and it is worth
removing the doubt before release.

## Bundling the font (recommended before shipping)

1. Download **Noto Sans Ethiopic** (SIL Open Font License 1.1, free to bundle
   and redistribute) from <https://fonts.google.com/noto/specimen/Noto+Sans+Ethiopic>
   or <https://github.com/notofonts/ethiopic>.

2. Copy the static files into this folder:

   ```
   assets/fonts/NotoSansEthiopic-Regular.ttf
   assets/fonts/NotoSansEthiopic-Bold.ttf
   ```

3. Uncomment the `fonts:` block near the bottom of `pubspec.yaml`.

4. `flutter pub get`, then rebuild.

Nothing in the Dart code has to change. The family name registered in
`pubspec.yaml` is already the first entry in `GuzoFonts.ethiopicFallback`, so
the bundled face is picked up automatically and takes priority over whatever
the device happens to have.

## Checking it worked

Run the Amharic Fidel mode. If you see `ሀ ለ ሐ መ` on the collectibles and in the
progress ribbon, the font resolved. Empty rectangles mean it did not.

`test/amharic_letters_test.dart` verifies the *data* is intact — that the
letters are real Ethiopic code points and none were mangled in an editor. It
cannot tell you whether a font exists to draw them, which is why this manual
check matters.
