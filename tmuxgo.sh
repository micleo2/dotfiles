#!/bin/bash
SESSION=$USER

tmux -2 new-session -d -s $SESSION

# Setup main window
tmux new-window -t $SESSION:1 -n 'main'
tmux split-window -h
tmux select-pane -t 1
tmux send-keys "vim ." C-m
tmux select-pane -t 2
tmux send-keys "ls" C-m
tmux split-window -v
tmux send-keys "python3.6" C-m
tmux send-keys "import numpy as np" C-m

# Set default window
tmux select-window -t $SESSION:1
tmux select-pane -t 1

# Attach to session
tmux -2 attach-session -t $SESSION
