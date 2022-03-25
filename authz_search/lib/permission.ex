defmodule Authz.Permission do
  # "org:non-mem"
  @levels ["site", "org", "user", "*", "org:mem"]
  @resources ["resource", "*", "other"]
  @ids ["rid", "other", "*"]
  @actions ["action", "other", "*"]

  def neg(set) do
    Enum.map(set, &Map.put(&1, :type, "-"))
  end

  def s do
    p() ++ p!()
  end

  def p! do
    p() |> neg
  end

  def p do
    for l <- @levels, r <- @resources, i <- @ids, a <- @actions do
      %{type: "+", level: l, resource: r, id: i, action: a}
    end
  end

  def a! do
    a() |> neg
  end

  def a do
    abstain(p())
  end

  def j! do
    j() |> neg
  end

  def j do
    p() -- a()
  end

  def abstain(set) do
    Enum.filter(set, fn x ->
      x.level == "org:non-mem" ||
        x.resource == "other" ||
        x.id == "other" ||
        x.action == "other"
    end)
  end
end

defmodule Authz.Groups do
  @moduledoc """
  Groups will split a set of permissions into levels
  """

  @site :site
  @org :org
  @user :user
  @wild :wild
  @sum :sum
  @product :product
  @group_order [@wild, @site, @org, @user, @sum, @product]

  @groups [
    %{name: @site, levels: ["site"]},
    %{name: @org, levels: ["org", "org:mem", "org:non-mem"]},
    %{name: @user, levels: ["user"]},
    %{name: @wild, levels: ["*"]}
  ]

  # This function will return the permission set split into the appropriate
  # groups.
  def group(set) do
    Enum.reduce(set, Map.new(@groups, &{&1.name, []}), fn x, acc ->
      g = level_group(x.level)
      acc = Map.put(acc, g.name, [x | acc[g.name]])
      acc
    end)
  end

  defp(level_group(level)) do
    Enum.find(@groups, fn g -> level in g.levels end)
  end

  def group_order do
    @group_order
  end
end
