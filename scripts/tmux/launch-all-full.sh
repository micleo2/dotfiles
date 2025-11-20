#!/bin/zsh

tmux new -d -s sh -c ~/sparse/xplat/static_h/
tmux send-keys -t sh "vim" C-m
tmux split-window -t sh -h
tmux send-keys -t sh "cd ~/sparse/xplat/static_h" C-m
tmux split-window -t sh -v
tmux send-keys -t sh "cd ~/builds/shdebug" C-m

tmux new -d -s musica -c ~/oss/aome/spotify-player/
tmux send-keys -t musica "./target/release/spotify_player" C-m
tmux split-window -t musica -h
tmux send-keys -t musica "cd ~/scripts/translate" C-m
tmux send-keys -t musica "python3 t-repl.py" C-m
tmux new-window -t musica -c ~/oss/realtime-lyrics/spotify-lyrics-api
tmux send-keys -t musica "php -S localhost:8000 api/index.php" C-m
tmux previous-window -t musica

tmux new -d -s hermes -c ~/sparse/xplat/hermes/

exit 0
