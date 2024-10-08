default: rebuild

rebuild:
	darwin-rebuild switch --flake .#personal
