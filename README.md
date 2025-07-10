---
title: Sinatra Web Calendar
---

# Sinatra Web Calendar

## Requirements

- SQLite
- Ruby(with rbenv)

## Setup

### SQL

``` shell
sudo apt install -y sqlite3 libsqlite3-dev
```

``` shell
sqlite3 days.db < dbinit.sq3
```

### Ruby

``` shell
bundle install
```

## Run

``` shell
bundle exec ruby webcal.rb
```
