#!/bin/bash
set -e

# -------------------------------------------------------------------------
# CONFIGURATION
# -------------------------------------------------------------------------
PIPELINE_FILE="pipeline_generated.yml"
QUEUE="Linux"

# -------------------------------------------------------------------------
# LOGIC
# -------------------------------------------------------------------------

# Start the pipeline file
cat <<EOF > "$PIPELINE_FILE"
steps:
EOF

# CASE 1: C++ Changes (The Heavy Build)
# We use 'grep' to check if any file in src/ changed
if git diff --name-only HEAD~1 | grep -q "^src/"; then
  cat <<EOF >> "$PIPELINE_FILE"
  - label: ":bazel: Compile Game (C++)"
    agents:
      queue: "$QUEUE"
    plugins:
      - docker#v5.8.0:
          image: "gcr.io/bazel-public/bazel:latest"
          workdir: "/app"
          # This 'shell' option is the magic fix. 
          # It tells Docker: "Don't run 'bazel'. Just give me a bash shell."
          shell: ["/bin/bash", "-e", "-c"]
    command: "bazel build //:fiction-factory-game"
EOF
fi

# CASE 2: Asset Changes (The Light Task)
if git diff --name-only HEAD~1 | grep -q "^assets/"; then
  cat <<EOF >> "$PIPELINE_FILE"
  - label: ":art: Compress Assets"
    agents:
      queue: "$QUEUE"
    command: "echo 'Compressing textures... Done!'"
EOF
fi

# CASE 3: No Changes (Fallback)
if ! grep -q "label:" "$PIPELINE_FILE"; then
  cat <<EOF >> "$PIPELINE_FILE"
  - label: ":zzz: No code nor assets changes detected, nothing to do here"
    agents:
      queue: "$QUEUE"
    command: "echo 'No buildable changes detected.'"
EOF
fi

# -------------------------------------------------------------------------
# EXECUTION
# -------------------------------------------------------------------------
buildkite-agent pipeline upload "$PIPELINE_FILE"