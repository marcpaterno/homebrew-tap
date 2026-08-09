# marcpaterno Tap

These are formulae I maintain for personal use.

`headroom-proxy` is a Homebrew service wrapper. It does not install the
`headroom` package or include the proxy implementation; it delegates to the
externally installed `headroom proxy` command.

## Installation

```bash
brew install marcpaterno/tap/<formula>
```

Or tap the repository first:

```bash
brew tap marcpaterno/tap
brew install <formula>
```

You can also reference it in a Brewfile:

```ruby
tap "marcpaterno/tap"
brew "<formula>"
```

## Development & Testing

### Adding new tests

- Edit the `test do … end` block in the formula file (e.g., `Formula/headroom-proxy.rb`).
- Write deterministic checks that do not require network access or external services.
- Prefer Homebrew test helpers:
  - `assert_match <expected>, shell_output("#{bin}/binary --option")`
  - `assert_predicate <path>, :exist?`
- For wrappers around external commands, create a stub command in `testpath` and put it first in `PATH` so tests do not depend on a developer's environment.
- Example:

```ruby
test do
  stub = testpath/"headroom"
  args = testpath/"headroom-args"
  stub.write <<~EOS
    #!/bin/bash
    printf '%s\\n' "$@" > "#{args}"
  EOS
  chmod 0755, stub

  with_env("PATH" => "#{testpath}:#{ENV.fetch("PATH")}") do
    system bin/"headroom-proxy", "--help"
  end

  assert_equal ["proxy", "--help"], args.readlines(chomp: true)
end
```

Keep tests fast and side‑effect free; they run on every CI run and on `brew test`.

### Running the test suite locally

1. **Install the external runtime** (the formula does not install it):
   ```bash
   pipx install --python python3.13 "headroom[all]"
   headroom --version
   headroom proxy --help
   ```
2. **Tap the repo** (local path or remote):
   ```bash
   brew tap /Users/paterno/repos/homebrew-tap   # local
   # or
   brew tap marcpaterno/tap
   ```
3. **Install the formula** (this installs only the wrapper):
   ```bash
   brew install headroom-proxy
   ```
4. **Run the formula’s tests**:
   ```bash
   brew test headroom-proxy
   ```

### Running and troubleshooting the service

```bash
brew services start headroom-proxy
brew services info headroom-proxy
tail -f "$(brew --prefix)/var/log/headroom-proxy.log"
tail -f "$(brew --prefix)/var/log/headroom-proxy-error.log"
brew services stop headroom-proxy
```

The service must be able to find `headroom` on its launchd `PATH`. If it fails
after working in an interactive shell, inspect the error log and make the
external executable available to launchd before restarting the service.

Alternatively, run the Homebrew test‑bot locally to perform a full suite (audit, install, test) similar to CI:

```bash
brew test-bot --only-setup
brew test-bot --only-formulae
```

### CI checks

The GitHub Actions workflow `.github/workflows/tests.yml` runs on pushes and pull requests. It performs:

- `brew audit --strict --online` for style and policy compliance.
- `brew test` for each formula.
- Bottle creation and upload for PRs.

Ensure your changes pass the local tests before pushing; CI will fail on audit warnings or test errors.

## Documentation

`brew help`, `man brew` or see [Homebrew's documentation](https://docs.brew.sh).
