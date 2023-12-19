defmodule Hub.NatsServer do
  use Supervisor
  require Logger

  def start_link(target) do
    Supervisor.start_link(__MODULE__, target)
  end

  @impl Supervisor
  def init(target) do
    {:ok, path} = setup_nats_server_binary(target)
    args = nats_args(target)
    opts = [log_output: :info, log_prefix: "NATS", stderr_to_stdout: true]
    Supervisor.init([{MuonTrap.Daemon, [path, args, opts]}], strategy: :one_for_one)
  end

  defp nats_args(:host) do
    [
      "--port", "4223",
      "--http_port", "8223"
    ]
  end

  defp nats_args(_rpi) do
    []
  end

  defp setup_nats_server_binary(target) do
    case File.exists?(binary_path(target)) do
      false ->
        Logger.info("NATS Binary Not Installed. Extracting it")
        :ok = extract_tar(target)
        {:ok, binary_path(target)}

      true ->
        {:ok, binary_path(target)}
    end
  end

  @nats_server_version "2.10.7"
  defp extract_tar(target) do
    archive_path = Path.join(:code.priv_dir(:hub), "#{name(target)}.tar.gz")
    :erl_tar.extract(archive_path, [:compressed, {:cwd, dir(target)}])
  end

  defp binary_path(target) do
    Path.join(dir(target), "#{name(target)}/nats-server")
  end

  defp name(target) do
    "nats-server-v#{@nats_server_version}-#{platform_tag(target)}"
  end

  defp platform_tag(:host), do: "darwin-arm64"
  defp platform_tag(_rpi), do: "linux-arm7"

  defp dir(:host) do
    Path.join(:code.priv_dir(:hub), "../tmp")
  end

  defp dir(_rpi) do
    "/root"
  end
end
