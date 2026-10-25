# Project context

`timetable-next` continues [JonasWanke/timetable](https://github.com/JonasWanke/timetable) from alpha.15. It is a Flutter calendar display and interaction library. The host application owns persistence, synchronization, time-zone conversion and recurrence rules.

## Code map

| Path | Responsibility |
|---|---|
| `lib/timetable_next.dart` | Public exports |
| `lib/timetable.dart` | Compatibility entry |
| `lib/src/event/` | Event spans, providers and builders |
| `lib/src/date/` | Date ranges, snapping, controllers and paging |
| `lib/src/time/` | Time ranges, zoom, overlays and registrations |
| `lib/src/layouts/`, `components/` | Layout, painting and gestures |
| `lib/src/utils.dart`, `utils/` | Shared calculations and render helpers |
| `example/lib/` | Example application and shared QA fixture |
| `test/`, `example/integration_test/` | Contract, widget and platform tests |

## Contracts

- UTC-marked values represent display fields without time-zone conversion. See [GLOSSARY.md](GLOSSARY.md) for event and date terminology.
- Positive event spans are half-open; zero-duration events are points. Closed intervals use microsecond precision.
- Date snapping ties choose the later date, including negative pages.
- Animation futures terminate on completion or interruption. Interrupted animations need not reach their target.
- Views must unregister from their controller when detached or rebound. Compact months derive their initial month from the date controller.

Current constraints live in the pubspecs. See [dependency decisions](doc/DEPENDENCIES.md), [QA](doc/QA.md) and the [independent-maintenance decision](doc/adr/0001-independent-maintenance.md).
