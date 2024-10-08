default: rebuild

rebuild:
	darwin-rebuild switch --flake .#personal

update:
	nix flake update
