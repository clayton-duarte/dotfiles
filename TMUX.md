# tmux Cheat Sheet

tmux is a terminal multiplexer — it lets you keep sessions alive across SSH disconnects and manage multiple terminal panes in one window.

## Core Concept

Everything in tmux is triggered with a **prefix key**: `Ctrl-b` (hold Ctrl, press b, release both, then press the next key).

## Session Persistence (Your Main Use Case)

```bash
# Start a new named session
tmux new -s work

# Detach from session (keeps it running in background)
Ctrl-b d

# List running sessions
tmux ls

# Reattach to a session
tmux attach -t work

# Reattach to last session
tmux attach
```

### SSH Workflow

1. SSH into a remote machine
2. Run `tmux new -s work` (or `tmux attach` if session already exists)
3. Do your work
4. If connection drops → session survives
5. SSH back in → `tmux attach` picks up where you left off

**Pro tip**: Use `tmux new -A -s work` to attach if the session exists, or create it if it doesn't — one command for both.

## Windows (Tabs)

```
Ctrl-b c        Create new window
Ctrl-b n        Next window
Ctrl-b p        Previous window
Ctrl-b 1-9      Switch to window by number
Ctrl-b ,        Rename current window
Ctrl-b &        Close current window (with confirmation)
```

## Panes (Splits)

```
Ctrl-b |        Split horizontally (custom binding)
Ctrl-b -        Split vertically (custom binding)
Ctrl-b ←↑↓→    Move between panes (arrow keys)
Ctrl-b z        Toggle pane zoom (fullscreen a pane)
Ctrl-b x        Close current pane
Ctrl-b Space    Cycle pane layouts
```

> The default split bindings are `Ctrl-b %` (horizontal) and `Ctrl-b "` (vertical).
> The config remaps them to `|` and `-` for easier recall.

## Scrolling & Copy Mode

```
Ctrl-b [        Enter scroll/copy mode (scroll with arrow keys or mouse)
q               Exit scroll mode
```

With mouse mode enabled (in your config), you can also scroll with the trackpad/mouse wheel.

## Session Management

```bash
tmux ls                     # List all sessions
tmux kill-session -t work   # Kill a specific session
tmux rename -t old new      # Rename a session
```

```
Ctrl-b s        Show session picker (interactive switch)
Ctrl-b $        Rename current session
Ctrl-b d        Detach (session keeps running)
```

## Useful Extras

```
Ctrl-b r        Reload tmux config (custom binding)
Ctrl-b ?        Show all key bindings
Ctrl-b t        Show a clock (press q to exit)
```

## Quick Reference

| Task                          | Command                          |
|-------------------------------|----------------------------------|
| Start named session           | `tmux new -s name`               |
| Attach or create              | `tmux new -A -s name`            |
| Detach                        | `Ctrl-b d`                       |
| Reattach                      | `tmux attach -t name`            |
| New window                    | `Ctrl-b c`                       |
| Split horizontal              | `Ctrl-b \|`                      |
| Split vertical                | `Ctrl-b -`                       |
| Switch pane                   | `Ctrl-b arrow`                   |
| Zoom pane                     | `Ctrl-b z`                       |
| Kill session                  | `tmux kill-session -t name`      |
