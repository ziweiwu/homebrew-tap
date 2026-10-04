# Ships the prebuilt binary rather than building from source.
#
# The binary is what the project releases: one static-ish executable per
# platform, built and smoke-run by CI on a runner of that architecture. Building
# from source here would pull a full Rust toolchain onto every user's machine to
# reproduce an artifact that already exists and was already tested, and would
# make `brew install` a multi-minute compile instead of a download.
class UsefulSystemMonitor < Formula
  desc "See what's using up your machine, and close what's hogging it"
  homepage "https://github.com/ziweiwu/useful-system-monitor"
  # No explicit `version`: Homebrew scans it from the release URL, and stating
  # it as well means a bump has two places to change and one of them will be
  # missed. The test below asserts the binary agrees with whatever was scanned.
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/ziweiwu/useful-system-monitor/releases/download/v0.10.1/useful-system-monitor-0.10.1-aarch64-apple-darwin.tar.gz"
      sha256 "ea8a997b0073013af93e658712e14abbf9975f6fcb9e9420ff225693640de656"
    end
    on_intel do
      url "https://github.com/ziweiwu/useful-system-monitor/releases/download/v0.10.1/useful-system-monitor-0.10.1-x86_64-apple-darwin.tar.gz"
      sha256 "bbb7217a5fea03adcc897cc2a7d7c6679fe288e1d0a88d553ef2342ffa56419e"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/ziweiwu/useful-system-monitor/releases/download/v0.10.1/useful-system-monitor-0.10.1-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "94b040564db5c838760efab2a9ef615102754099a3e906f64e931633300a1a05"
    end
    on_intel do
      url "https://github.com/ziweiwu/useful-system-monitor/releases/download/v0.10.1/useful-system-monitor-0.10.1-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "ed14ada01b754293a9e4f5d0c8c005ebc8c80895218f27eb3414bf8e95fd4f37"
    end
  end

  def install
    # The archive holds the binary under its build name; the command users type
    # is the project name, so it is installed under that and `sysmon` is left as
    # an alias for anyone who knows it by the crate name.
    bin.install "sysmon" => "useful-system-monitor"
    bin.install_symlink bin/"useful-system-monitor" => "sysmon"
  end

  def caveats
    <<~EOS
      Run it as `useful-system-monitor`, or `sysmon`.

      It reads process, memory, disk and battery state through the same public
      interfaces `ps`, `vm_stat` and `df` use. It needs no elevated privileges,
      and closing a process signals it as you — so it can only close what you
      could close from a shell.
    EOS
  end

  test do
    # `--version` must agree with the formula, or the bottle and the metadata
    # have drifted apart and `brew upgrade` would be a no-op that looks like an
    # upgrade.
    assert_equal version.to_s, shell_output("#{bin}/useful-system-monitor --version").strip

    # `--json` is the machine-readable contract, so assert its shape rather than
    # just a zero exit: a binary that starts and prints nothing useful would
    # otherwise pass.
    require "json"
    output = JSON.parse(shell_output("#{bin}/useful-system-monitor --mock --json"))
    assert_equal version.to_s, output["version"]
    assert_equal true, output["mock"]
    assert output["processes"].is_a?(Array), "--json should carry a processes array"

    # The alias has to work too; it is half of what the caveats promise.
    assert_match version.to_s, shell_output("#{bin}/sysmon --version")
  end
end
