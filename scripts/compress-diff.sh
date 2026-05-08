#!/bin/bash
INPUT=$(cat)
awk '
  /^diff --git/ { print; next }
  /^index /     { print; next }
  /^\+\+\+/     { print; next }
  /^---/        { print; next }
  /^@@/         { print; next }
  /^\+[[:space:]]*$/ { next }
  /^-[[:space:]]*$/ { next }
  /^\+/         { print; next }
  /^-/          { print; next }
' <<< "$INPUT"
