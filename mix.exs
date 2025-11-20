defmodule Forum.Mixfile do
  use Mix.Project

  def project() do
    [
      app: :forum,
      version: "0.1.0",
      description: "Forum Elixir N2O Application",
      package: package(),
      deps: deps()
    ]
  end

  def package do
    [
      files: ~w(doc lib mix.exs LICENSE),
      licenses: ["ISC"],
      maintainers: ["Ihor Horobets"],
      name: :forum,
      links: %{"GitHub" => "https://github.com/iho/forum"}
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
      {:rocksdb, git: "git@github.com:emqx/erlang-rocksdb.git"},
      {:nitro, "~> 8.2.4"},
      {:kvs, "~> 10.8.3"},
      {:n2o, "~> 10.12.4"},
      {:syn, "~> 2.1.1"},
      {:earmark, "~> 1.4"},
      {:html_sanitize_ex, "~> 1.4"}
    ]
  end
end
