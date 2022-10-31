defmodule Expression.AutodocTest do
  use ExUnit.Case, async: true
  alias Expression.Callbacks.Standard

  defp find_docs(module, name) do
    Enum.filter(module.expression_docs(), &(elem(&1, 0) == name))
  end

  test "expression docs" do
    assert [{"date", :direct, args, docstring, expression_docs}] = find_docs(Standard, "date")

    assert docstring =~ "Defines a new date value"

    assert ["year", "month", "day"] = args

    assert expression_docs == [
             %{
               doc: "Construct a date from year, month, and day integers",
               expression: "date(year, month, day)",
               context: %{"day" => 31, "month" => 1, "year" => 2022},
               result: ~D[2022-01-31]
             }
           ]
  end

  test "regular docstrings" do
    assert [{"has_time", :direct, args, docstring, expression_docs}] =
             find_docs(Standard, "has_time")

    assert docstring =~ "Tests whether `expression` contains a time."

    assert ["expression"] = args

    assert expression_docs == []
  end

  test "vargs" do
    assert [{"or", :vargs, args, docstring, expression_docs}] = find_docs(Standard, "or")

    assert docstring =~ "Returns TRUE if any argument is TRUE"

    assert ["arguments"] = args

    assert expression_docs
  end

  test "undocumented" do
    assert [{"map", :direct, args, docstring, expression_docs}] = find_docs(Standard, "map")

    refute docstring

    assert ["enumerable", "mapper"] = args

    assert expression_docs == []
  end

  test "private functions excluded" do
    assert [] = find_docs(Standard, "extract_dateish")
  end
end