# Prompt für Claude Code: Sudoku-Spiel mit Flutter + Flame

Baue ein vollständiges, produktionsreifes Sudoku-Spiel als Flutter-App, das sowohl
als Android-App als auch als Web-App (Flutter Web) lauffähig ist. Nutze Flame nur
dort, wo es echten Mehrwert bringt (z. B. Animationen, Partikeleffekte bei gelöstem
Rätsel); die Kern-UI (Raster, Zahleneingabe) soll mit normalen Flutter-Widgets
umgesetzt werden, da das für ein rasterbasiertes Puzzle robuster und einfacher zu
warten ist als eine reine Flame-Canvas-Lösung. Triff diese Architekturentscheidung
eigenständig, wenn du gute Gründe für eine Abweichung hast, und begründe sie kurz.

## 1. Projekt-Setup
- Erstelle ein neues Flutter-Projekt mit Unterstützung für Android und Web.
- Füge `flame` als Dependency hinzu (für Animationen/Effekte), außerdem
  Standardpakete wie `provider` oder `riverpod` für State-Management (wähle eines
  und begründe die Wahl kurz), sowie `shared_preferences` für lokales Speichern
  von Spielstand und Einstellungen.
- Richte eine klare Ordnerstruktur ein (z. B. `lib/models`, `lib/logic`,
  `lib/ui`, `lib/services`).

## 2. Spiellogik (Kern)
- **Board-Repräsentation**: 9x9-Raster, 3x3-Boxen, Zellen mit Wert, Notizen
  (Kandidaten 1-9), Status (fest vorgegeben / vom Spieler eingetragen).
- **Puzzle-Generator**: Erzeuge ein vollständig gelöstes 9x9-Sudoku (z. B. via
  Backtracking mit Randomisierung), entferne dann Zahlen, sodass ein Rätsel mit
  **eindeutiger Lösung** entsteht. Prüfe die Eindeutigkeit mit einem Solver, der
  nach mehr als einer Lösung sucht und abbricht.
- **Schwierigkeitsgrade**: mindestens Easy, Medium, Hard, Expert – gesteuert über
  Anzahl der vorgegebenen Zellen und/oder benötigte Lösungstechniken
  (z. B. Hard = erfordert mehr als reines "Naked Single").
- **Validierung**: Prüfe bei jeder Eingabe, ob eine Zahl gegen Sudoku-Regeln
  verstößt (Zeile, Spalte, Box), und ob das gesamte Board am Ende korrekt gelöst
  ist.
- **Solver/Hint-Engine**: Implementiere einen Solver, der auch als Basis für ein
  Hinweissystem dient (z. B. "zeige die nächste logisch ableitbare Zahl" statt nur
  "hier ist die Lösung").

## 3. Gameplay-Features
- Zellenauswahl per Tap, Zahleneingabe über ein Nummernpad (1-9 + Löschen).
- **Notizen-Modus** (Pencil Marks): Kandidatenzahlen klein in der Zelle eintragen.
- **Hervorhebung**: gleiche Zeile/Spalte/Box der ausgewählten Zelle, sowie alle
  Zellen mit demselben Wert, farblich markieren.
- **Fehleranzeige**: falsch eingetragene Zahlen visuell markieren (optional
  abschaltbar), Fehlerzähler mit konfigurierbarem Limit ("Game Over nach 3
  Fehlern" o. ä., als Option).
- **Undo/Redo** für Eingaben.
- **Hinweis-Button**: begrenzte Anzahl an Hinweisen pro Spiel, die die Hint-Engine
  nutzt.
- **Timer**: Spielzeit anzeigen, pausierbar.
- **Speichern/Fortsetzen**: laufendes Spiel wird lokal gespeichert (auch bei
  App-Kill) und beim nächsten Start automatisch angeboten.
- **Neues Spiel starten** mit Schwierigkeitsauswahl.
- **Gewinn-Erkennung** mit Abschlussanimation (hier bietet sich Flame an, z. B.
  ein kurzer Partikel- oder Konfetti-Effekt).
- **Voreintragen der Notizen**: Es gibt einen Button, mit dem man die Notizen 
  automatisch ausfüllen kann, sodass der manuell Aufwand nicht mehr nötig ist.

## 4. UI/UX
- Responsives Layout: Das Raster soll auf Handy-Hochformat, Tablet und im
  Browser (verschiedene Fenstergrößen) sauber skalieren und zentriert bleiben.
- Klares, ruhiges Design mit gutem Kontrast; Dark Mode und Light Mode.
- Zugängliche Touch-Ziele (ausreichend große Zellen/Buttons für Mobile).
- Einstellungsseite: Fehlerlimit an/aus, Hervorhebungen an/aus, Dark/Light Mode,
  Sound an/aus.

## 5. Architektur & Codequalität
- Trenne strikt: Spiellogik (reines Dart, ohne Flutter-Imports, gut testbar) von
  UI-Layer und von Persistenz-Layer.
- Nutze Unit-Tests für: Puzzle-Generator (Eindeutigkeit der Lösung), Solver,
  Validierungslogik, Schwierigkeitsberechnung.
- Nutze Widget-Tests für zentrale UI-Interaktionen (Zahl eingeben, Notiz
  eintragen, Undo).
- Kommentiere komplexe Algorithmen (Backtracking, Eindeutigkeitsprüfung) kurz,
  aber verzichte auf Kommentar-Rauschen bei selbsterklärendem Code.

## 6. Nicht-funktionale Anforderungen
- Performance: Puzzle-Generierung darf die UI nicht blockieren (ggf. in einem
  Isolate ausführen), besonders für höhere Schwierigkeitsgrade.
- Web-Build: Teste/berücksichtige, dass Touch- und Maus-Interaktion beide
  funktionieren.
- Keine Abhängigkeit von Cloud-Diensten – alles lokal, offline spielbar.

## 7. Vorgehen / Reihenfolge
Arbeite in dieser Reihenfolge und zeige nach jedem Schritt kurz den Stand:
1. Projekt-Setup + Datenmodelle (Board, Cell)
2. Solver + Puzzle-Generator inkl. Tests
3. Basis-UI: Raster anzeigen, Zahl eingeben, Validierung
4. Notizen-Modus, Hervorhebungen, Fehlerzähler, Undo/Redo
5. Timer, Hinweissystem, Speichern/Fortsetzen
6. Einstellungen, Dark/Light Mode, Gewinn-Animation (Flame)
7. Feinschliff: Responsives Layout für Web, letzte Tests, Aufräumen

## 8. Abschluss
Erstelle am Ende eine kurze README mit: Projektstruktur-Überblick, wie man das
Projekt für Android baut (`flutter build apk`) und für Web
(`flutter build web`), sowie bekannte Einschränkungen.
