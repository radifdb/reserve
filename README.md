# radif

**Coming soon.** A graph + relational database, part of
[épure](https://epuremethod.com).

*Radif* is the Persian word for a row, a series: the ordered
repertoire of melodies in Persian classical music.

## Packages

| Package | Folder |
|---|---|
| `@radif/db` | `db/` |
| `radifdb` | `radifdb/` |

Both are placeholders at version 0.0.0. The bare name `radif` is not
available: npm refuses it as too similar to `raf`, `redis` and
`radium`. Packages live under `@radif`; `radifdb` is reserved so a
search for it lands here.

## Publishing

    pnpm pub:dry   # pack and show what would be published
    pnpm pub       # publish every package at the root version

The version is the one in the root `package.json`. `@radif/db` needs
the npm org `radif` to exist and include you.
