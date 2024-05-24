defmodule Tonic.Objects do
  alias Tonic.Canvas
  alias Tonic.Grid

  @moduledoc """
  This module collects together the primitive drawing shapes (lines, rectangles, squares,
  polygons, circles, elipses) as well as a grouping primitive.

  The general structure of an object is a list of the form

  `[type, position, dimensions, options]`

  where `options` is a keyword list at the end, like in function calls.

  This module contains helper functions to create these list representations, 
  and to which to attach documentation. The following are identical:

  `Tonic.Objects.circle({100,100}, 50, fill: :red)`, and

  `[:circle, {100, 100}, 50, fill: :red]`
 
  It is important to note that the position of an object is interpreted as the coordinates
  of the canvas' current grid. By default, the grid is just xy pixels, but different grids 
  may have differing number of coordinates (for example, the `:triangular` grid has 3
  coordinates to specify a point). So for a square grid of spacing 5, the position
  `{10, 10}` results in an actual position of `{50, 50}`.

  Colors can be represented as [CSS named colors](https://developer.mozilla.org/en-US/docs/Web/CSS/named-color)
  either as atoms or strings, or as hex triplet strings, prefixed by a `#` 
  (example: `"#FFCC00"`)
  """

  def add(canvas = %Canvas{}, []) do
    canvas
  end

  def add(canvas = %Canvas{}, [[:group, items | options] | rest]) do
    canvas =
      %{canvas | start_tags: [format_shape(canvas, [:group | options]) | canvas.start_tags]}
      |> add(items)

    %{canvas | start_tags: [%{end_tag: :g} | canvas.start_tags]} |> add(rest)
  end

  @doc """
  Add objects to a canvas. Objects will be drawn in the order they were added. Features
  (color, line width, etc.) will be taken from the context (Canvas or group) unless 
  specifically overridden on a per-object bases. 

  Returns: the updated canvas
  """
  def add(canvas = %Canvas{}, [first | rest]) do
    %{canvas | start_tags: [format_shape(canvas, first) | canvas.start_tags]} |> add(rest)
  end

  ## Shape Helpers 

  @doc """
  Represents a line consisting of one or more segments.

  Returns: the list form of a line

  ## Examples

      iex> Tonic.Objects.line([{50, 50}, {50, 100}], stroke: :red)
      [:line, [{50, 50}, {50, 100}], stroke: :red]
  """
  def line(vertices, options \\ []) when is_list(vertices) do
    [:line, vertices | options]
  end

  @doc """
  Represents a circle with the center and radius. While the center is translated
  to grid coordinates, the radius is in raw pixels.

  Returns: the list form of a circle

  ## Examples

      iex> Tonic.Objects.circle({50, 50}, 25, fill: :green)
      [:circle, {50, 50}, 25, fill: :green]
  """
  def circle(center, radius, options \\ []) do
    [:circle, center, radius | options]
  end

  @doc """
  Represents an ellipse with center and horizontal, vertical radii. 
  While the center is translated to grid coordinates, the radii are in raw pixels.

  ## Examples

      iex> Tonic.Objects.ellipse({50, 50}, {25, 15}, fill: :green)
      [:ellipse, {50, 50}, {25, 15}, fill: :green]
  """
  def ellipse(center, {radius_x, radius_y}, options \\ []) do
    [:ellipse, center, {radius_x, radius_y} | options]
  end

  @doc """
  Represents a rectangle with upper-left corner, width, and height. While the corner
  is translated to grid coordinates, the width and height are in raw pixels.

  ## Examples

      iex> Tonic.Objects.rect({50, 50}, {25, 15}, fill: :yellow, stroke: :red)
      [:rect, {50, 50}, {25, 15}, fill: :yellow, stroke: :red]
  """
  def rect(corner, {width, height}, options \\ []) do
    [:rect, corner, {width, height} | options]
  end

  @doc """
  Represents a square iwht upper-left corner and size. While the corner is
  translated to grid coordinates, the size is in raw pixels.

  ## Example

      iex> Tonic.Objects.square({50, 50}, 25, fill: :blue, stroke: :white)
      [:rect, {50, 50}, 25, fill: :blue, stroke: :white]
  """
  def square(corner, size, options \\ []) do
    [:square, corner, size | options]
  end

  @doc """
  Represents a collection of other objects. Groups can be used for a variety of purposes:
  * To group a set of primitives into a more complex object, which can be re-used multiple
  times, by giving it an id. (TODO: Not Implemented Yet)
  * To set up drawing properties (like colors, line widths, etc.) for a collection of 
  primitives.
  * To set up a transformation context (translation, rotation, skew, scale) for a collection
  of objects.

  Groups can contain other groups. If nested groups have transformations, then those
  transformations are cumulative.

  ## Examples

      iex> Tonic.Objects.group(objects, id: "MyGroup")
      [:group, objects, id: "MyGroup"]
  
      iex> Tonic.Objects.group(objects, transform: [rotate: 30])
      [:group, objects, transform: [rotate: 30]]
  """
  def group(objects, options \\ []) when is_list(objects) do
    [:group, objects | options]
  end

  ######################
  ## Shape formatters ##
  ######################

  ### Lines

  defp format_shape(canvas, [:line, points | options]) when is_list(points) do
    points = points |> Grid.resolve(canvas) |> format_points()
    format_shape(canvas, [:line, {:points, points} | options])
  end

  ### Polygon

  defp format_shape(canvas, [:polygon, points | options]) when is_list(points) do
    points = points |> Grid.resolve(canvas) |> format_points()
    format_shape(canvas, [:polygon, {:points, points} | options])
  end

  ### Circle/Ellipse

  defp format_shape(canvas, [:ellipse, center, {rx, ry} | options]) do
    {x, y} = center |> Grid.resolve(canvas)
    options = [cx: x, cy: y, rx: rx, ry: ry] ++ options
    %{min_tag: :ellipse, options: options}
  end

  defp format_shape(canvas, [:circle, center, radius | options]) do
    {x, y} = center |> Grid.resolve(canvas)
    options = [cx: x, cy: y, rx: radius, ry: radius] ++ options
    %{min_tag: :ellipse, options: options}
  end

  ### Rectangle/Square

  defp format_shape(canvas, [:rect, corner, {width, height} | options]) do
    {x, y} = corner |> Grid.resolve(canvas)
    options = [x: x, y: y, width: width, height: height] ++ options
    %{min_tag: :rect, options: options}
  end

  defp format_shape(canvas, [:square, corner, size | options]) do
    {x, y} = corner |> Grid.resolve(canvas)
    options = [x: x, y: y, width: size, height: size] ++ options
    %{min_tag: :rect, options: options}
  end

  ### Group

  defp format_shape(canvas, [:group | options]) do
    options = format_transform_options(canvas, options)
    %{tag: :g, options: options}
  end

  # This allows re-naming :line shapes to <polyline> tags
  defp format_shape(_, [:line | options]) do
    %{min_tag: :polyline, options: options}
  end

  ### Default/Util shape. Can be used to inject raw SVG

  # default format shape, once arguments have been resolvled for cases where
  # the shape name matches the svg tag
  defp format_shape(_, [shape | options]) do
    %{min_tag: shape, options: options}
  end


  defp format_transform_options(canvas, options) do
    transforms =
      options
      |> Keyword.take([:transform])
      |> Keyword.values()
      |> List.flatten()
      |> Enum.map(fn {k, v} -> format_transform(canvas, k, v) end)
      |> Enum.join(" ")

    (options |> Keyword.delete(:transform)) ++ [transform: transforms]
  end

  defp format_transform(_, :translate, {x, y}) do
    ~s/translate(#{x},#{y})/
  end

  defp format_transform(canvas, :grid_translate, point) do
    {x, y} = point |> Grid.resolve(canvas)
    ~s/translate(#{x},#{y})/
  end

  defp format_transform(_, :rotate, degrees) do
    ~s/rotate(#{degrees})/
  end

  defp format_points(points) do
    points |> Enum.map(fn {x, y} -> ~s(#{x},#{y}) end) |> Enum.join(" ")
  end
end
