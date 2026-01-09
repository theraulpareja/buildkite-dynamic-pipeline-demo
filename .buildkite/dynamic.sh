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

cat <<EOF > "$PIPELINE_FILE"
steps:
EOF

# CASE 1: C++ Changes
if git diff --name-only HEAD~1 | grep -q "^src/"; then
  cat <<EOF >> "$PIPELINE_FILE"
  - label: ":bazel: Compile Game (C++)"
    agents:
      queue: "$QUEUE"
    plugins:
      - docker#v5.8.0:
          image: "gcr.io/bazel-public/bazel:latest"
          workdir: "/app"
          # CRITICAL: Override the default 'bazel' entrypoint to get a shell
          entrypoint: "/bin/bash"
          # COMMAND:
          # 1. '-c' tells bash to run the string following it
          # 2. We 'touch MODULE.bazel' to make the directory a valid Bazel workspace
          # 3. We run the build
          command: 
            - "-c"
            - "touch MODULE.bazel && bazel build //:fiction-factory-game"
EOF
fi

# CASE 2: Asset Changes
if git diff --name-only HEAD~1 | grep -q "^assets/"; then
  cat <<EOF >> "$PIPELINE_FILE"
  - label: ":art: Compress Assets"
    agents:
      queue: "$QUEUE"
    command: "echo 'Compressing textures... Done!'"
EOF
fi

# CASE 3: Fallback
if ! grep -q "label:" "$PIPELINE_FILE"; then
  cat <<EOF >> "$PIPELINE_FILE"
  - label: ":zzz: No Op"
    agents:
      queue: "$QUEUE"
    command: "echo 'No buildable changes detected.'"
EOF
fi

# -------------------------------------------------------------------------
# EXECUTION
# -------------------------------------------------------------------------
buildkite-agent pipeline upload "$PIPELINE_FILE"