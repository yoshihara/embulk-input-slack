# Slack input plugin for Embulk

embulk-input-slack is the Embulk input plugin for [Slack](https://slack.com) history.

## Overview

* **Plugin type**: input
* **Resume supported**: no
* **Cleanup supported**: no
* **Guess supported**: no

## Configuration

- **token**: your token for target team (string, required)
- **channel**: target channel (string, default: all channel)
- **from**: from datetime for range (date, default: first history)
- **to**: to datetime for range (date, default: today)

## Example

```yaml
in:
  type: slack
  token: YOUR-TOKEN-IS-HERE
  channel: #general
  from: 2015/02/02
  to: 2015/04/30
```


## Build

```
$ rake
```
