#!/bin/bash
set -e

# Define the queue we want the NEXT steps to run on,
# In a real setup, we might send C++ jobs to "High-CPU-Queue" and Assets to "Generic-Queue" as an example

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
  # ---------------------------------------------------------
  # FIX: Override the default 'bazel' entrypoint to get a shell
  echo "          entrypoint: '/bin/bash'" >> "$PIPELINE_FILE"
  # ---------------------------------------------------------
  echo "    command: 'bazel build //:fiction-factory-game'" >> "$PIPELINE_FILE"
fi

# 2. Check for Asset Changes
if git diff --name-only HEAD~1 | grep "^assets/"; then
  echo "  - label: ':art: Compress Assets'" >> "$PIPELINE_FILE"
  echo "    agents:" >> "$PIPELINE_FILE"
  echo "      queue: \"$QUEUE\"" >> "$PIPELINE_FILE"
  echo "    command: 'echo \"Compressing textures... Done!\"'" >> "$PIPELINE_FILE"
fi

# 3. Fallback
if ! grep -q "label:" "$PIPELINE_FILE"; then
  echo "  - label: ':zzz: No Op'" >> "$PIPELINE_FILE"
  echo "    agents:" >> "$PIPELINE_FILE"
  echo "      queue: \"$QUEUE\"" >> "$PIPELINE_FILE"
  echo "    command: 'echo \"No buildable changes detected.\"' " >> "$PIPELINE_FILE"
fi

# Upload
buildkite-agent pipeline upload "$PIPELINE_FILE"
