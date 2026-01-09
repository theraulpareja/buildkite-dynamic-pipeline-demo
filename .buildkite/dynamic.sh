#!/bin/bash
set -e

PIPELINE_FILE="pipeline_generated.yml"
QUEUE="Linux"

cat <<EOF > "$PIPELINE_FILE"
steps:
EOF

# CASE 1: C++ Changes (The Docker Build)
if git diff --name-only HEAD~1 | grep -q "^src/"; then
  cat <<EOF >> "$PIPELINE_FILE"
  - label: ":bazel: Compile Game (C++)"
    agents:
      queue: "$QUEUE"
    plugins:
      - docker#v5.8.0:
          image: "gcr.io/bazel-public/bazel:latest"
          workdir: "/app"
          
          # 1. PERMISSIONS: This enables the container to write 'bazel-out' to your repo
          propagate-uid-gid: true
          
          # 2. SHELL: Ensures we bypass the default 'bazel' entrypoint
          entrypoint: "/bin/bash"
          
          # 3. COMMAND: Just build. The plugin has already mounted your repo to /app
          command: ["-c", "bazel build //:fiction-factory-game"]
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

buildkite-agent pipeline upload "$PIPELINE_FILE"