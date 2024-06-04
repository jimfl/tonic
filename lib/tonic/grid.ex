defmodule Tonic.Grid do
  alias Tonic.Canvas

  @moduledoc """
  Grid allows the Canvas to support different coordinate systems for object
  placement. A grid is a function that takes some coordinates and resolves them
  to the native pixels on the canvas.  In the following example, this draws a
  circle at native x,y coordinates 50, 50:

      %Tonic.Canvas{{100, 100}}
      |> Grid.push(:square, 5)
      |> Shape.add([
        Shape.circle({10, 10}, 10)
      ])
  
  Grids are pushed onto a stack so that sub-components which draw complex
  shapes can have their own grid locally. Only object coordinates are resolved
  through the current grid, not distances or dimensions. In the above example,
  the coordinates for the center of the circle `{10, 10}` are resolved to
  `{50, 50}` by the square grid with spacing 5. The radius of the circle is not
  affected by the grid, and remains 10.

  Certain transformations on groups can also be done relative to the grid, most notably
  translations. These however are explicitly done via the grid.

      Shape.group(...)
      |> Transform.translate({50, 50})

  would be equivalent to

      Shape.group(...)
      |> Transform.grid_translate({10, 10})

  under a square grid with spacing 5. Note that the synax for grid 

  Currently supported grids are 
  * `:square` -- with a single spacing for x and y
  * `:rectangular` -- with separate spacing in the x and y direction
  * `:triangular` -- a triangular grid mapping 3 a,b,c coordinates to x-y coordinates 

  In the triangular grid the points a, b, and c represent moving left, down-and-left, and down-and-right
  respectively. Usually only 2 of the coordinates need be non-zero, so there are multiple ways to represent
  the same point.
  
  """

  def push(canvas = %Canvas{}, :square, spacing) do
    mapper = fn {x, y} -> {x * spacing, y * spacing} end
    %{canvas | grid_stack: [mapper | canvas.grid_stack]}
  end

  def push(canvas = %Canvas{}, :triangular, spacing) do
    mapper = fn {a, b, c} ->
      {
        spacing * (a + 0.5 * (b - c)),
        spacing * (:math.sqrt(3) / 2) * (b + c)
      }
    end

    %{canvas | grid_stack: [mapper | canvas.grid_stack]}
  end

  def push(canvas = %Canvas{}, :rectangular, x_spacing, y_spacing) do
    mapper = fn {x, y} -> {x * x_spacing, y * y_spacing} end
    %{canvas | grid_stack: [mapper | canvas.grid_stack]}
  end

  # Never remove the bottom entry in the stack
  def pop(canvas = %Canvas{grid_stack: [_top | []]}) do
    canvas
  end

  def pop(canvas = %Canvas{grid_stack: [_top | rest]}) do
    %{canvas | grid_stack: rest}
  end

  def resolve(points, %Canvas{grid_stack: [top | _]})
      when is_list(points) do
    points |> Enum.map(top)
  end

  def resolve(point, %Canvas{grid_stack: [top | _]}) do
    top.(point)
  end

  def identity(x), do: x
end
