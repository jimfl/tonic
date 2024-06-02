defmodule Tonic.SVG do
  alias Tonic.{Shape, Transform}

  defp render_min_tag(tag, attributes) do
    attrs = for {k, v} <- attributes, into: "", do: ~s( #{k}="#{v}")
    ~s(<#{tag}#{attrs} />)
  end

  defp render_start_tag(tag, attributes) do
    attrs = for {k, v} <- attributes, into: "", do: ~s( #{k}="#{v}")
    ~s(<#{tag}#{attrs}>)
  end

  defp render_end_tag(tag), do: ~s(</#{tag}>)

  def render(shapes, tags \\ [])

  def render([], tags), do: tags |> IO.iodata_to_binary()

  def render([shape | rest], tags) do
    render(rest, [render_shape(shape) | tags])
  end

  def render_shape(%Shape{children: []} = shape), do: render_leaf(shape)

  def render_shape(%Shape{name: tag} = shape) do
    attr = extract_attributes(shape) |> add_transforms(shape)

    [
      [
        render_start_tag(tag, attr)
        | [
            shape.children |> render()
            | render_end_tag(tag)
          ]
      ]
    ]
    |> IO.iodata_to_binary()
  end

  def render_leaf(%Shape{name: tag} = shape) do
    attr = extract_attributes(shape) |> add_transforms(shape)
    render_min_tag(tag, attr)
  end

  def extract_attributes(%Shape{name: :rect} = shape) do
    [{x, y} | _] = shape.coords
    [size | _] = shape.dimensions
    shape.attributes |> Map.merge(%{x: x, y: y, width: size, height: size})
  end

  def extract_attributes(%Shape{name: :ellipse} = shape) do
    [{x, y} | _] = shape.coords
    [r_x, r_y | _] = shape.dimensions
    shape.attributes |> Map.merge(%{cx: x, cy: y, rx: r_x, ry: r_y})
  end

  def extract_attributes(%Shape{name: :polyline} = shape) do
    points =
      shape.coords
      |> Enum.map(fn {x, y} -> "#{x},#{y}" end)
      |> Enum.join(" ")

    shape.attributes |> Map.put(:points, points)
  end

  def extract_attributes(%Shape{name: :polygon} = shape) do
    points =
      shape.coords
      |> Enum.map(fn {x, y} -> "#{x},#{y}" end)
      |> Enum.join(" ")

    shape.attributes |> Map.put(:points, points)
  end

  def extract_attributes(%Shape{attributes: attributes}), do: attributes

  def add_transforms(attributes, %Shape{transforms: []}), do: attributes

  def add_transforms(attributes, shape) do
    rendered = render_transform(shape.transforms, "") |> String.trim()
    attributes |> Map.put(:transform, rendered)
  end

  def render_transform([], acc), do: acc

  def render_transform([tfm | rest], acc) do
    render_transform(rest, render_transform(tfm) <> acc)
  end

  def render_transform(%Transform{type: :rotate, coords: nil} = tfm) do
    degrees = tfm.magnitude
    ~s/rotate(#{degrees}) /
  end

  def render_transform(%Transform{type: :rotate} = tfm) do
    degrees = tfm.magnitude
    {x, y} = tfm.coords
    ~s/rotate(#{degrees} #{x} #{y}) /
  end

  def render_transform(%Transform{type: :translate} = tfm) do
    {x, y} = tfm.magnitude
    ~s/translate(#{x} #{y}) /
  end

  def render_transform(%Transform{type: :scale} = tfm) do
    {x, y} = tfm.magnitude
    ~s/scale(#{x} #{y}) /
  end

  def render_transform(%Transform{type: :skew, magnitude: {x, 0}}) do
    ~s/skewX(#{x}) /
  end

  def render_transform(%Transform{type: :skew, magnitude: {0, y}}) do
    ~s/skewY(#{y}) /
  end

  def render_transform(%Transform{type: :skew} = tfm) do
    {x, y} = tfm.magnitude
    ~s/skewX(#{x}) skewY(#{y}) /
  end

  def render_transform(%Transform{type: :matrix} = tfm) do
    {a, b, c, d, e, f} = tfm.magnitude
    ~s/matrix(#{a} #{b} #{c} #{d} #{e} #{f}) /
  end
end
