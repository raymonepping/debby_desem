# Zuurdesembrood Mastergids

Bronbestanden en buildtools voor de Nederlandstalige *Zuurdesembrood Mastergids*.
De gids wordt in Markdown onderhouden en met Pandoc als gevalideerde EPUB 3
gebouwd.

## Vereisten

De build gebruikt:

- Pandoc;
- Markdownlint CLI;
- EPUBCheck;
- `xmllint` en `unzip`;
- ImageMagick of `sips` voor het optimaliseren van de omslag.

Op macOS met Homebrew:

```bash
brew install pandoc markdownlint-cli epubcheck imagemagick
```

## EPUB bouwen

Voer vanuit de hoofdmap van het project uit:

```bash
./scripts/build-epub.sh
```

Het script:

1. controleert de Markdown-opmaak en documentversie;
2. optimaliseert de omslag als tijdelijke JPEG;
3. bouwt een EPUB 3 met hoofdstukken, navigatie, metadata en CSS;
4. valideert het resultaat met XML-controles en EPUBCheck;
5. vervangt de bestaande EPUB alleen als alle controles slagen.

De standaarduitvoer is:

```text
docs/zuurdesembrood-mastergids-v3.15.epub
```

Een ander bron- en doelbestand kunnen als argumenten worden opgegeven:

```bash
./scripts/build-epub.sh docs/boek-v3.16.md docs/boek-v3.16.epub
```

Gebruik tijdelijk een andere omslag met:

```bash
EPUB_COVER_IMAGE=images/andere-omslag.png ./scripts/build-epub.sh
```

## Controles afzonderlijk uitvoeren

```bash
./scripts/lint-markdown.sh
./scripts/check-version.sh
./scripts/check-links.sh
./scripts/validate-epub.sh
```

De externe-linkcontrole heeft internettoegang nodig. Met `make check` worden alle
lokale controles plus de EPUB-build uitgevoerd; `make check-links` controleert
de externe links afzonderlijk.

## Inhoud op één pagina houden

Een kort tekstblok kan in de EPUB zoveel mogelijk bij elkaar worden gehouden
met een Pandoc fenced div:

```markdown
### Tussenkop

::: {.keep-together}

Deze korte tekst blijft indien mogelijk op dezelfde pagina.

- Eerste onderdeel
- Tweede onderdeel

:::
```

Plaats een niveau-2-hoofdstukkop nooit binnen zo'n blok. EPUB-readers mogen de
regel negeren wanneer het blok groter is dan het beschikbare scherm.

## Versies en releases

De versie in `subtitle: Versie …` moet overeenkomen met `-v…` in de
Markdown-bestandsnaam en, bij een release, met de Git-tag. Een tag zoals
`v3.15` bouwt en valideert de EPUB en voegt deze automatisch aan de GitHub
Release toe.

Gebruik voor een release ook de
[releasechecklist](docs/release-checklist.md).

## Projectstructuur

```text
css/       EPUB-stylesheet
docs/      Markdown-bron en gebouwde EPUB
images/    bronafbeelding voor de omslag
scripts/   build- en controlescripts
```

## Bijdragen en licentie

Zie [CONTRIBUTING.md](CONTRIBUTING.md) voor de werkwijze. Dit project gebruikt
de [MIT-licentie](LICENSE).
