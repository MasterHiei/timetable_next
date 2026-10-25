# Calendar display

timetable_next presents calendar data supplied by a host application.

## Language

**Event**: An item with a start-inclusive and end-exclusive time span. A zero-duration event is treated as a point.

**All-day event**: An event classified by this package as lasting at least 24 hours; this is a duration-based display category.

**Multi-date view**: A calendar layout showing consecutive dates and their events.

**Recurring view**: A multi-date layout with concrete date indicators hidden. It does not define recurrence rules.

**Visible date range**: The dates currently represented by a view, including partially visible dates.

**Timetable time**: Date and time fields represented with `isUtc == true` and displayed without time-zone conversion.
