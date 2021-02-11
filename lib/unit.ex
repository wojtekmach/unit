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

  """
  defmacro eval(do: block), do: do_eval(block)
  defmacro eval(block), do: do_eval(block)

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

  defp unit(ast) do
    Macro.postwalk(ast, fn
      {unit, _, nil} ->
        unit

      {:/, _, ast} ->
        {:/, ast}

      {:*, _, ast} ->
        {:*, ast}
    end)
  end

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
    %__MODULE__{magnitude: mag1 * mag2, unit: {:*, [unit1, unit2]}}
  end

  def mult(%__MODULE__{magnitude: mag, unit: unit}, number) when is_number(number) do
    %__MODULE__{magnitude: mag * number, unit: unit}
  end

  @doc """
  Divides two values.
  """
  def div(%__MODULE__{magnitude: mag1, unit: unit1}, %__MODULE__{magnitude: mag2, unit: unit2}) do
    %__MODULE__{magnitude: mag1 / mag2, unit: {:/, [unit1, unit2]}}
  end

  def div(%__MODULE__{magnitude: mag, unit: unit}, number) when is_number(number) do
    %__MODULE__{magnitude: mag / number, unit: unit}
  end

  defimpl Inspect do
    def inspect(%{magnitude: magnitude, unit: unit}, _) do
      "#Unit<#{magnitude}[#{unit(unit)}]>"
    end

    defp unit({:/, [a, b]}) do
      unit(a) <> "/" <> unit(b)
    end

    defp unit({:*, [a, b]}) do
      unit(a) <> " " <> unit(b)
    end

    defp unit(atom) when is_atom(atom) do
      Atom.to_string(atom)
    end
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
