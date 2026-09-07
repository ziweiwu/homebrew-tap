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
  version "0.10.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/ziweiwu/useful-system-monitor/releases/download/v0.10.0/useful-system-monitor-0.10.0-aarch64-apple-darwin.tar.gz"
      sha256 "a30d4300b3cfb8d99160a115595495f894cf9011907f7f74fa039cb04f26f4b3"
    end
    on_intel do
      url "https://github.com/ziweiwu/useful-system-monitor/releases/download/v0.10.0/useful-system-monitor-0.10.0-x86_64-apple-darwin.tar.gz"
      sha256 "3d2e0d48147102c718140db8f532463d04f59379c137f2e3891ae0d6567e5dd1"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/ziweiwu/useful-system-monitor/releases/download/v0.10.0/useful-system-monitor-0.10.0-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "9b40319310aa05c5a079c660e3214e18c4d4f4464b166a90d9fb5a0f6eb7de49"
    end
    on_intel do
      url "https://github.com/ziweiwu/useful-system-monitor/releases/download/v0.10.0/useful-system-monitor-0.10.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "3f9d83f5160f0733f77400e113bd4bdf74df48aed49249634971e67a22dc0992"
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
