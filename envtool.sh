_envtool_is_interactive() { case $- in *i*) return 0;; *) return 1;; esac; }

# Insert into prompt for zsh; otherwise print.
_envtool_emit() {
  if [ -n "${ZSH_VERSION-}" ] && _envtool_is_interactive; then
    print -z -- "$1"
  else
    printf '%s\n' "$1"
  fi
}

# Quote values safely for export (single-quote, escape embedded single quotes)
_envtool_quote() {
  printf "'%s'" "$(printf "%s" "$1" | sed "s/'/'\"'\"'/g")"
}

# Convert picked "KEY" / "KEY=" / "KEY=VAL" -> "export KEY=" / "export KEY='VAL'"
_envtool_to_export() {
  local picked="$1"
  local key="${picked%%=*}"

  # normalize KEY -> KEY=
  if [[ "$picked" != *"="* ]]; then
    printf 'export %s=\n' "$key"
    return 0
  fi

  # KEY= (blank)
  if [[ "$picked" == "$key=" ]]; then
    printf 'export %s=\n' "$key"
    return 0
  fi

  # KEY=VALUE
  local val="${picked#*=}"
  printf 'export %s=%s\n' "$key" "$(_envtool_quote "$val")"
}

# Given lines like:
#   ABC=def
#   ABC=xyz
#   ABC
#   ABC=
# Output candidates for fzf:
#   ABC=        (exactly once)
#   ABC=def     (deduped)
#   ABC=xyz     (deduped)
_envtool_expand_blanks() {
  awk '
    function trim(s){ sub(/^[[:space:]]+/,"",s); sub(/[[:space:]]+$/,"",s); return s }

    {
      line = trim($0)
      if (line=="" || line ~ /^[[:space:]]*#/) next

      key = line
      sub(/=.*/, "", key)

      # normalize KEY -> KEY=
      if (index(line, "=") == 0) line = key "="

      if (!(key in key_seen)) { key_seen[key]=1; key_order[++n]=key }

      if (!(line in line_seen)) { line_seen[line]=1; lines[++m]=line }
    }

    END {
      # Print blank variant once per key
      for (i=1; i<=n; i++) {
        k = key_order[i]
        blank = k "="
        if (!(blank in printed)) { printed[blank]=1; print blank }
      }
      # Print all non-blank distinct lines
      for (j=1; j<=m; j++) {
        line = lines[j]
        k = line; sub(/=.*/, "", k)
        blank = k "="
        if (line != blank) print line
      }
    }
  '
}

# Reverse stdin (newest-first preference)
_envtool_rev() {
  if command -v tac >/dev/null 2>&1; then tac
  elif tail -r /dev/null >/dev/null 2>&1; then tail -r
  else awk '{a[NR]=$0} END{for(i=NR;i>=1;i--) print a[i]}'
  fi
}

# eh: mine zsh history for env exports/assignments; menu includes KEY= once per key; selection is saved and inserted/printed.
eh() {
  command -v fzf >/dev/null 2>&1 || { echo "eh: fzf not found" >&2; return 1; }

  local hist="${HISTFILE:-${ZSH_HISTFILE:-$HOME/.zsh_history}}"
  [ -f "$hist" ] || { echo "eh: history not found: $hist" >&2; return 1; }

  command -v perl >/dev/null 2>&1 || { echo "eh: perl not found (needed to parse quoted history safely)" >&2; return 1; }

  local max="${ENVTOOL_HIST_MAX:-50000}"

  local picked
  picked="$(
    tail -n "$max" "$hist" 2>/dev/null \
      | _envtool_rev \
      | perl -ne '
          s/^: \d+:\d+;//; chomp;
          my $l = $_;
          my @out = ();

          if ($l =~ /^\s*export\b/) {
            $l =~ s/^\s*export\s+//;
            while ($l =~ /([A-Za-z_]\w*)(?:=(?:"((?:\\.|[^"])*)"|'\''((?:\\.|[^'\''])*)'\''|([^\s]+)))?/g) {
              my ($k,$dq,$sq,$u)=($1,$2,$3,$4);
              if (defined $dq) { push @out, "$k=$dq"; }
              elsif (defined $sq) { push @out, "$k=$sq"; }
              elsif (defined $u) { push @out, "$k=$u"; }
              else { push @out, "$k"; }
            }
          } elsif ($l =~ /^\s*[A-Za-z_]\w*=/) {
            while ($l =~ /\G\s*([A-Za-z_]\w*)=(?:"((?:\\.|[^"])*)"|'\''((?:\\.|[^'\''])*)'\''|([^\s]+))/gc) {
              my ($k,$dq,$sq,$u)=($1,$2,$3,$4);
              my $v = defined $dq ? $dq : defined $sq ? $sq : $u;
              push @out, "$k=$v";
            }
          }

          print join("\n", @out), "\n" if @out;
        ' \
      | awk '!seen[$0]++' \
      | _envtool_expand_blanks \
      | fzf --prompt="env(hist)> " --height=40% --reverse
  )"
  [ -n "$picked" ] || return 0

  _envtool_emit "$(_envtool_to_export "$picked")"
}
