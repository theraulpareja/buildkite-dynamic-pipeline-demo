#!/bin/bash
set -e

QUEUE="Linux"
PIPELINE_FILE="pipeline_generated.yml"
echo "steps:" > "$PIPELINE_FILE"

# 1. Check for C++ Changes
if git diff --name-only HEAD~1 | grep "^src/"; then
  echo "  - label: ':cpp: Compile Game Engine (Bazel)'" >> "$PIPELINE_FILE"
  echo "    agents:" >> "$PIPELINE_FILE"
  echo "      queue: \"$QUEUE\"" >> "$PIPELINE_FILE"
  echo "    plugins:" >> "$PIPELINE_FILE"
  echo "      - docker#v5.8.0:" >> "$PIPELINE_FILE"
  echo "          image: 'gcr.io/bazel-public/bazel:latest'" >> "$PIPELINE_FILE"
  echo "          workdir: /app" >> "$PIPELINE_FILE"
  echo "          entrypoint: '/bin/bash'" >> "$PIPELINE_FILE"
  
  # ---------------------------------------------------------
  # FIX: Use ["-c", "..."] so Bash executes it as a command, not a file
  echo "    command: [\"-c\", \"bazel build //:fiction-factory-game\"]" >> "$PIPELINE_FILE"
  # ---------------------------------------------------------
fi

# 2. Check for Asset Changes (Keep this as is)
if git diff --name-only HEAD~1 | grep "^assets/"; then
  echo "  - label: ':art: Compress Assets'" >> "$PIPELINE_FILE"
  echo "    agents:" >> "$PIPELINE_FILE"
  echo "      queue: \"$QUEUE\"" >> "$PIPELINE_FILE"
  echo "    command: 'echo \"Compressing textures... Done!\"'" >> "$PIPELINE_FILE"
fi

# 3. Fallback (Keep this as is)
if ! grep -q "label:" "$PIPELINE_FILE"; then
  echo "  - label: ':zzz: No Op'" >> "$PIPELINE_FILE"
  echo "    agents:" >> "$PIPELINE_FILE"
  echo "      queue: \"$QUEUE\"" >> "$PIPELINE_FILE"
  echo "    command: 'echo \"No buildable changes detected.\"' " >> "$PIPELINE_FILE"
fi

buildkite-agent pipeline upload "$PIPELINE_FILE"
