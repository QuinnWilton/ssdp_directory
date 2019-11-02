defmodule SSDPDirectory.MixProject do
  use Mix.Project

  def project do
    [
      app: :ssdp_directory,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {SSDPDirectory.Application, []},
      start_phases: [discovery: []]
    ]
  end

  defp deps do
    []
  end
end
