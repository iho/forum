defmodule Forum.Mixfile do
  use Mix.Project

  def project() do
    [
      app: :Forum,
      version: "6.9.3",
      description: "Forum Elixir N2O Application",
      package: package(),
      deps: deps()
    ]
  end

  def package do
    [
      files: ~w(doc lib mix.exs LICENSE),
      licenses: ["ISC"],
      maintainers: ["Namdak Tonpa"],
      name: :Forum,
      links: %{"GitHub" => "https://github.com/erpuno/Forum"}
    ]
  end


  def application() do
    [
      mod: {Forum.Application, []},
      extra_applications: [:xmerl, :logger]
    ]
  end

  def deps() do
    [
      {:ex_doc, "~> 0.29.0", only: :dev},
      {:plug, "~> 1.15.3"},
      {:bandit, "~> 1.0"},
      {:websock_adapter, "~> 0.5"},
      {:rocksdb, "~> 1.8.0"},
      {:nitro, "~> 8.2.4"},
      {:kvs, "~> 10.8.3"},
      {:n2o, "~> 10.12.4"},
      {:syn, "~> 2.1.1"},
      {:argon2_elixir, "4.0.0"},
      {:exsync, "~> 0.4", only: :dev},
      {:resend, "~> 0.4.0"}
    ]
  end
end
