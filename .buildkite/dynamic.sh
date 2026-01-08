#!/bin/bash
set -e

# 1. Initialize an empty pipeline file
PIPELINE_FILE="pipeline_generated.yml"
echo "steps:" > "$PIPELINE_FILE"

# 2. Check for changes in C++ Source Code (src/)
# We use 'git diff' to see what changed in the commit.
# If src/ changed, we add the HEAVY C++ Compilation step.
if git diff --name-only HEAD~1 | grep "^src/"; then
  echo "  - label: ':cpp: Compile Game Engine (Bazel)'" >> "$PIPELINE_FILE"
  echo "    plugins:" >> "$PIPELINE_FILE"
  echo "      - docker#v5.8.0:" >> "$PIPELINE_FILE"
  echo "          image: 'gcr.io/bazel-public/bazel:latest'" >> "$PIPELINE_FILE"
  echo "          workdir: /app" >> "$PIPELINE_FILE"
  echo "    command: 'bazel build //:fiction-factory-game'" >> "$PIPELINE_FILE"
fi

# 3. Check for changes in Assets (assets/)
# If assets/ changed, we add the LIGHT Asset Compression step.
if git diff --name-only HEAD~1 | grep "^assets/"; then
  echo "  - label: ':art: Compress Assets'" >> "$PIPELINE_FILE"
  echo "    command: 'echo \"Compressing textures... Done!\"'" >> "$PIPELINE_FILE"
fi

# 4. Fallback: If nothing relevant changed (e.g. README), just echo.
if ! grep -q "label:" "$PIPELINE_FILE"; then
  echo "  - command: 'echo \"No buildable changes detected.\"' " >> "$PIPELINE_FILE"
  echo "    label: ':zzz: No Op'" >> "$PIPELINE_FILE"
fi

# 5. Upload the generated pipeline to Buildkite
buildkite-agent pipeline upload "$PIPELINE_FILE"
