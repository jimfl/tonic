defmodule Tonic.GridTest do
  use ExUnit.Case
  alias Tonic.Grid

  test "push and pop grid" do
    canvas = %Tonic.Canvas{}

    assert canvas.grid_stack |> length() == 1
    current_trans = (canvas.grid_stack |> List.first()).({1, 1})

    canvas = Grid.push(canvas, :square, 5)

    assert canvas.grid_stack |> length() == 2
    assert (canvas.grid_stack |> List.first()).({1, 1}) == {5, 5}

    canvas = Grid.pop(canvas)

    assert canvas.grid_stack |> length() == 1
    assert (canvas.grid_stack |> List.first()).({1, 1}) == current_trans
  end

  test "implicit push and pop with grid shape" do
    canvas =
      %Tonic.Canvas{}
      |> Tonic.Shape.add(
        Tonic.Shape.grid(:square, spacing: 5)
        |> Tonic.Shape.add(Tonic.Shape.square({10, 10}, 30))
      )

    assert length(canvas.shapes) == 1
    [square | _] = canvas.shapes
    [{50, 50} | _] = square.coords
  end

  test "can't pop the last grid off the stack" do
    canvas = %Tonic.Canvas{} |> Grid.pop() |> Grid.pop() |> Grid.pop()
    assert length(canvas.grid_stack) == 1
  end
end
