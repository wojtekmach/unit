defmodule UnitTest do
  use ExUnit.Case, async: true
  doctest Unit
  require Unit

  test "eval" do
    assert Unit.eval(1[m]) == %Unit{magnitude: 1, unit: {:m, 1}}
    assert Unit.eval(1[m2]) == %Unit{magnitude: 1, unit: {:m, 2}}
    assert Unit.eval(1[m * m]) == %Unit{magnitude: 1, unit: {:m, 2}}
    assert Unit.eval(1[m * m * m]) == %Unit{magnitude: 1, unit: {:m, 3}}
    assert Unit.eval(1[m * m * s]) == %Unit{magnitude: 1, unit: {:*, [{:m, 2}, {:s, 1}]}}
    assert Unit.eval(1[m / s]) == %Unit{magnitude: 1, unit: {:/, [{:m, 1}, {:s, 1}]}}
    assert Unit.eval(1[m / s2]) == %Unit{magnitude: 1, unit: {:/, [{:m, 1}, {:s, 2}]}}
    assert Unit.eval(1[m2 / m]) == %Unit{magnitude: 1, unit: {:m, 1}}

    assert inspect(Unit.eval(1[m])) == "#Unit<1[m]>"
    assert inspect(Unit.eval(1[m2])) == "#Unit<1[m2]>"
    assert inspect(Unit.eval(1[m * s])) == "#Unit<1[m*s]>"
    assert inspect(Unit.eval(1[m / s])) == "#Unit<1[m/s]>"

    assert Unit.eval(1[m] * 1[s]) == Unit.eval(1[m * s])
  end
end
