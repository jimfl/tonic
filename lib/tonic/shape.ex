defmodule Tonic.Shape do
  alias Tonic.{Canvas, Grid, Shape, Transform}

  defstruct name: "",
            coords: [],
            dimensions: [],
            attributes: %{},
            transforms: [],
            children: [],
            parent: nil,
            canvas: nil

  #
  # A D D
  #

  @doc """
  Adds one or more shapes to a container. A container is either a canvas, or another
  shape, such as a group, or a grid. `add/2` returns the container, so that `add`s 
  (or other container functions) can be chained.
  """
  def add(container, shapes)

  def add(container, []), do: container

  # Add a list of shapes to another shape (usually group or grid)
  # returns the shape
  def add(%Shape{} = shape, [child | rest]) do
    shape |> add(child) |> add(rest)
  end

  # Add a list of shapes to a canvas
  # returns the canvas
  def add(%Canvas{} = canvas, [shape | rest]) do
    canvas |> add(shape) |> add(rest)
  end

  # Add a single shape to a shape
  # returns the shape
  def add(%Shape{} = shape, %Shape{} = child) do
    %{shape | children: [%{child | parent: shape} | shape.children]}
  end

  # This is a special-case add() which pushes a grid onto the canvas, adds 
  # the grid's "children" in the grid context, then pops the grid.
  # This allows shapes with grids to be constucted without a canvas.
  # The "grid" is just a container shape that gets stripped away when
  # added to a canvas. The coordinate transformations happen when the
  # grid's children are added to the canvas 
  # 
  # returns the canvas
  def add(%Canvas{} = canvas, %Shape{name: :grid} = grid) do
    grid_type = grid.attributes.grid_type

    canvas
    |> grid_shape_to_push(grid, grid_type)
    |> add(grid.children)
    |> Grid.pop()
  end

  # Add a single shape to a canvas
  # returns the canvas
  def add(%Canvas{} = canvas, %Shape{} = shape) do
    %{canvas | shapes: [shape |> shape_in_context(canvas) | canvas.shapes]}
  end

  defp shape_in_context(shape, canvas) do
    %{
      shape
      | canvas: canvas,
        coords: Grid.resolve(shape.coords, canvas),
        children: shape.children |> Enum.map(&shape_in_context(&1, canvas)),
        transforms: shape.transforms |> Transform.grid_resolve(canvas)
    }
  end

  defp grid_shape_to_push(canvas, shape, :square) do
    spacing = shape.attributes.spacing
    Grid.push(canvas, :square, spacing)
  end

  defp grid_shape_to_push(canvas, shape, :triangular) do
    spacing = shape.attributes.spacing
    Grid.push(canvas, :triangular, spacing)
  end

  defp grid_shape_to_push(canvas, shape, :rectangular) do
    x_spacing = shape.attributes.x_spacing
    y_spacing = shape.attributes.y_spacing
    Grid.push(canvas, :rectangular, x_spacing, y_spacing)
  end

  defp grid_shape_to_push(canvas, shape, :custom) do
    func = shape.attributes.function
    Grid.push(canvas, :custom, func)
  end

  #
  # S H A P E S
  #

  def rect(corner, width, height, options \\ []) do
    %Shape{name: :rect, coords: [corner], dimensions: [width, height]}
    |> add_attributes(options)
  end

  def square(corner, size, options \\ []) do
    rect(corner, size, size, options)
  end

  def ellipse(center, radius_x, radius_y, options \\ []) do
    %Shape{name: :ellipse, coords: [center], dimensions: [radius_x, radius_y]}
    |> add_attributes(options)
  end

  def circle(center, radius, options \\ []) do
    ellipse(center, radius, radius, options)
  end

  def line([_ | _] = points, options \\ []) do
    %Shape{name: :polyline, coords: points}
    |> add_attributes(options)
  end

  def group(options \\ []) do
    %Shape{name: :g} |> add_attributes(options)
  end

  def grid(type, options \\ []) do
    %Shape{name: :grid, attributes: %{grid_type: type}}
    |> add_attributes(options)
  end

  def polygon([_ | _] = points, options \\ []) do
    %Shape{name: :polygon, coords: points}
    |> add_attributes(options)
  end

  defp add_attributes(shape, []), do: shape

  defp add_attributes(shape, [{key, value} | rest]) do
    add_attributes(
      %{shape | attributes: shape.attributes |> Map.put(key, value)},
      rest
    )
  end

  defp add_attributes(shape, [_ | rest]), do: add_attributes(shape, rest)
end
