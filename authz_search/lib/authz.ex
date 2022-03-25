defmodule Authz do
  alias TableRex.Table
  use Number

  @yes "✅"
  @no "❌"
  @abstain "⛶"
  @sum "sum"
  @product "product"
  @sort_order [@yes, @no, @abstain, @sum]

  # Set space returns the number of permissions in each set at each level
  def set_space do
    %{
      @yes => Authz.Groups.group(Authz.Permission.j()),
      @no => Authz.Groups.group(Authz.Permission.j!()),
      @abstain => Authz.Groups.group(Authz.Permission.a() ++ Authz.Permission.a!())
    }
  end

  def set_space_counts(print \\ false, scribe \\ false)

  # Using Scribe
  def set_space_counts(print, scribe) when print and scribe do
    set_space_counts_table()
    |> Scribe.print(data: [:set | Authz.Groups.group_order()])
  end

  def set_space_counts(print, _scribe) when print do
    header = [:set] ++ Authz.Groups.group_order()

    rows =
      set_space_counts_table()
      |> Enum.reduce([], fn row, acc ->
        acc ++
          [
            for c <- header do
              Map.get(row, c, "")
            end
          ]
      end)
      |> Enum.map(fn row ->
        Enum.map(row, fn value ->
          case is_number(value) do
            true ->
              number_to_delimited(value, precision: 0)

            false ->
              value
          end
        end)
      end)

    # https://github.com/djm/table_rex
    Table.new(rows, header, "Permission Permutation Sets")
    |> Table.put_column_meta(0, color: IO.ANSI.color(31))
    |> Table.put_header_meta(0..length(header), color: IO.ANSI.color(31))
    |> Table.render!()
    |> IO.puts()
  end

  def set_space_counts(_print, _scribe) do
    order = Authz.Groups.group_order()

    set_space()
    |> Enum.map(fn {row, grps} ->
      {row,
       grps
       |> Enum.map(fn {grp, set} ->
         {grp, length(set)}
       end)
       |> Enum.sort(fn {a, _}, {b, _} ->
         Enum.find_index(order, &(a == &1)) <= Enum.find_index(order, &(b == &1))
       end)}
    end)
    |> Map.new(fn {set, row} ->
      {set, row}
    end)
  end

  # Permission Sets
  def set_space_counts_table() do
    table =
      set_space_counts()
      |> Enum.map(fn {set, grps} ->
        {set, Map.new(grps)}
      end)
      |> Enum.map(fn {set, grps} ->
        grps =
          Map.put(
            grps,
            :sum,
            Enum.reduce(grps, 0, fn {x, y}, acc ->
              case x do
                x when x in [:sum, :product] -> acc
                _ -> acc + y
              end
            end)
          )

        grps =
          Map.put(
            grps,
            :product,
            Enum.reduce(grps, 1, fn {x, y}, acc ->
              case x do
                x when x in [:sum, :product] -> acc
                _ -> acc * y
              end
            end)
          )

        grps = Map.put(grps, :set, set)
        Map.put(grps, :set, set)
      end)
      |> Enum.sort(fn a, b ->
        Enum.find_index(@sort_order, &(a.set == &1)) <=
          Enum.find_index(@sort_order, &(b.set == &1))
      end)

    table ++
      [
        column_summary(table, @sum, &Enum.sum/1),
        column_summary(table, @product, &Enum.product/1, 1)
      ]
  end

  # column_summary is a calculation of all columns returned as a row
  # f takes the entire column of values
  def column_summary(table, name, f, def \\ 0, ignore \\ []) do
    table
    |> Enum.reduce(%{}, fn row, acc ->
      Enum.reduce(row, acc, fn {level, value}, acc ->
        Map.put(acc, level, [value | Map.get(acc, level, [def])])
      end)
    end)
    |> Enum.reduce(%{}, fn {level, value}, acc ->
      Map.put(
        acc,
        level,
        cond do
          level == :set ->
            name

          Enum.member?(ignore, level) ->
            ""

          true ->
            f.(value)
        end
      )
    end)
  end
end
