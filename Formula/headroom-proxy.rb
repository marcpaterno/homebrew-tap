class HeadroomProxy < Formula
  desc "Homebrew service wrapper for the headroom proxy command"
  homepage "https://github.com/paterno/headroom-proxy"
  version "1.0.0"
  license "MIT"

  def install
    (bin/"headroom-proxy").write <<~EOS
      #!/bin/bash
      if ! HEADROOM_BIN="$(command -v headroom)"; then
        echo "headroom command not found on PATH: $PATH" >&2
        echo 'Install it with: pipx install --python python3.13 "headroom[all]"' >&2
        exit 1
      fi
      if ! "$HEADROOM_BIN" proxy --help >/dev/null 2>&1; then
        echo "headroom proxy is unavailable or cannot be executed: $HEADROOM_BIN" >&2
        exit 1
      fi
      exec "$HEADROOM_BIN" proxy "$@"
    EOS
  end

  def post_install
    unless which("headroom")
      opoo "headroom command not found. Install it with:\n  pipx install --python python3.13 \"headroom[all]\""
    end
  end

  def caveats
    <<~EOS
      This formula installs a Homebrew service wrapper; it does not install headroom.

      Install the external runtime with:
        pipx install --python python3.13 "headroom[all]"

      The headroom executable must be available on PATH to both your shell and launchd.
      Check the service with:
        brew services info headroom-proxy
      View logs with:
        tail -f "$(brew --prefix)/var/log/headroom-proxy.log"
        tail -f "$(brew --prefix)/var/log/headroom-proxy-error.log"
      Stop it while troubleshooting with:
        brew services stop headroom-proxy
    EOS
  end

  service do
    run [opt_bin/"headroom-proxy", "--host", "127.0.0.1", "--port", "8787"]
    keep_alive({ successful_exit: false })
    environment_variables(
      HEADROOM_MODE:         "token",
      HEADROOM_DEFAULT_MODE: "optimize",
      HEADROOM_CODE_AWARE:   "true",
      HEADROOM_BUDGET:       "50.0",
      HEADROOM_LOG_LEVEL:    "INFO",
      OPENAI_TARGET_API_URL: "https://litellm.fnal.gov/v1",
    )
    log_path var/"log/headroom-proxy.log"
    error_log_path var/"log/headroom-proxy-error.log"
  end

  test do
    stub = testpath/"headroom"
    args = testpath/"headroom-args"
    stub.write <<~EOS
      #!/bin/bash
      printf '%s\n' "$@" > "#{args}"
      exit "${HEADROOM_STUB_EXIT:-0}"
    EOS
    chmod 0755, stub

    with_env("PATH" => "#{testpath}:#{ENV.fetch("PATH")}") do
      system bin/"headroom-proxy", "--host", "127.0.0.1", "--port", "8787"
    end

    assert_equal ["proxy", "--host", "127.0.0.1", "--port", "8787"], args.readlines(chomp: true)
  end
end
