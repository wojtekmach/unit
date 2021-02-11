defmodule Unit do
  @moduledoc """
  Documentation for `Unit`.
  """

  defstruct [:magnitude, :unit]

  @doc """
  Evaluates expressions with units.

  ## Examples

      iex> Unit.eval 60[km] * 2
      #Unit<120[km]>

      iex> Unit.eval 120[km] / 2[h]
      #Unit<60.0[km/h]>

      iex> Unit.eval 10[m] * 20[m]
      #Unit<200[m2]>

  """
  defmacro eval(do: block), do: do_eval(block)
  defmacro eval(block), do: do_eval(block)

  @doc """
  Adds two values.
  """
  def add(%__MODULE__{magnitude: mag1, unit: unit}, %__MODULE__{magnitude: mag2, unit: unit}) do
    %__MODULE__{magnitude: mag1 + mag2, unit: unit}
  end

  def add(%__MODULE__{magnitude: mag, unit: unit}, number) when is_number(number) do
    %__MODULE__{magnitude: mag + number, unit: unit}
  end

  @doc """
  Subtracts two values.
  """
  def sub(%__MODULE__{magnitude: mag1, unit: unit}, %__MODULE__{magnitude: mag2, unit: unit}) do
    %__MODULE__{magnitude: mag1 - mag2, unit: unit}
  end

  def sub(%__MODULE__{magnitude: mag, unit: unit}, number) when is_number(number) do
    %__MODULE__{magnitude: mag - number, unit: unit}
  end

  @doc """
  Multiplies two values.
  """
  def mult(%__MODULE__{magnitude: mag1, unit: unit1}, %__MODULE__{magnitude: mag2, unit: unit2}) do
    %__MODULE__{magnitude: mag1 * mag2, unit: normalize_unit({:*, [unit1, unit2]})}
  end

  def mult(%__MODULE__{magnitude: mag, unit: unit}, number) when is_number(number) do
    %__MODULE__{magnitude: mag * number, unit: unit}
  end

  @doc """
  Divides two values.
  """
  def div(%__MODULE__{magnitude: mag1, unit: unit1}, %__MODULE__{magnitude: mag2, unit: unit2}) do
    %__MODULE__{magnitude: mag1 / mag2, unit: normalize_unit({:/, [unit1, unit2]})}
  end

  def div(%__MODULE__{magnitude: mag, unit: unit}, number) when is_number(number) do
    %__MODULE__{magnitude: mag / number, unit: unit}
  end

  defp do_eval(block) do
    block =
      Macro.prewalk(block, fn
        {{:., _, [Access, :get]}, _, [magnitude, unit]} ->
          Macro.escape(%__MODULE__{magnitude: magnitude, unit: unit(unit)})

        other ->
          other
      end)

    quote do
      # `if` adds scope and we need it so that imports don't leak outside
      if true do
        import Kernel, except: [+: 2, -: 2, *: 2, /: 2]
        import Unit.Kernel
        unquote(block)
      end
    end
  end

  defp unit({:*, _, list}) do
    normalize_unit({:*, Enum.map(list, &unit/1)})
  end

  defp unit({:/, _, list}) do
    normalize_unit({:/, Enum.map(list, &unit/1)})
  end

  defp unit({atom, _, nil}) when is_atom(atom) do
    case atom |> Atom.to_string() |> String.reverse() |> Integer.parse() do
      {int, str} ->
        {str |> String.reverse() |> String.to_atom(),
         int |> Integer.digits() |> Enum.reverse() |> Integer.undigits()}

      :error ->
        {atom, 1}
    end
  end

  defp normalize_unit({:*, [left, right]}) do
    case {normalize_unit(left), normalize_unit(right)} do
      {{unit, exp1}, {unit, exp2}} ->
        {unit, exp1 + exp2}

      {left, right} ->
        {:*, [left, right]}
    end
  end

  defp normalize_unit({:/, [left, right]}) do
    case {normalize_unit(left), normalize_unit(right)} do
      {{unit, exp1}, {unit, exp2}} ->
        {unit, exp1 - exp2}

      {left, right} ->
        {:/, [left, right]}
    end
  end

  defp normalize_unit(other) do
    other
  end
end

defimpl Inspect, for: Unit do
  def inspect(%{magnitude: magnitude, unit: unit}, _) do
    "#Unit<#{magnitude}[#{unit(unit)}]>"
  end

  defp unit({:*, list}) do
    Enum.map_join(list, "*", &unit/1)
  end

  defp unit({:/, [left, right]}) do
    unit(left) <> "/" <> unit(right)
  end

  defp unit({unit, 1}) do
    Atom.to_string(unit)
  end

  defp unit({unit, exp}) do
    Atom.to_string(unit) <> Integer.to_string(exp)
  end
end

defmodule Unit.Kernel do
  def a + b do
    Unit.add(a, b)
  end

  def a - b do
    Unit.sub(a, b)
  end

  def a * b do
    Unit.mult(a, b)
  end

  def a / b do
    Unit.div(a, b)
  end
end
