# SSDPDirectory

A fairly straightforward toy implementation of an SSDP Directory. When started, it listens for SSDP presence notifications, and stores those services in an ETS table.

## Usage

Discover all services:

```elixir
SSDPDirectory.discover_services()
```

List all known services:

```elixir
SSDPDirectory.list_services()
```

It's pretty simple.

## Caveats

The ETS table does not have any eviction strategy. It will grow indefinitely unless you clear it with: `SSDPDirectory.Cache.flush()`