defmodule Tonic.Canvas do
  defstruct width: 0,
            height: 0,
            origin: {0, 0},
            options: %{},
            shapes: [],
            grid_stack: [&Tonic.Grid.identity/1]

  def new(options \\ []) do
    %__MODULE__{} |> set_up(options)  
  end

  defp set_up(canvas, []), do: canvas

  defp set_up(canvas, [{:origin, origin} | rest]) do
    %{canvas | origin: origin } 
    |> set_up(rest)
  end

  defp set_up(canvas, [{:height, h} | rest]) do
    %{canvas | height: h} 
    |> set_up(rest)
  end

  defp set_up(canvas, [{:width, w} | rest]) do
    %{canvas | width: w} 
    |> set_up(rest)
  end

  defp set_up(canvas, [{k, v} | rest]) do
    %{canvas | options: canvas.options |> Map.put(k, v)} 
    |> set_up(rest)
  end

  defp compute_view_box(canvas) do
    {origin_x, origin_y} = canvas.origin

    vb = 
      {-origin_x, -origin_y, canvas.width - origin_x, canvas.height - origin_y}
      |> Tuple.to_list()
      |> Enum.join(" ")

    %{canvas | options: canvas.options |> Map.put("view-box", vb)}
  end

  defp opts_to_attributes(canvas) do
    for {k, v} <- canvas.options |> Map.to_list(), into: "" do
      ~s( #{k}="#{v}")
    end
  end

  def to_svg(canvas, {width, height}) do
    %{canvas | 
      options: canvas.options 
        |> Map.put(:height, height) 
        |> Map.put(:width, width)
    }
    |> to_svg()
  end

  def to_svg(canvas) do
    canvas = canvas |> compute_view_box()
    ~s(<svg xmlns="http://www.w3.org/2000/svg" #{canvas |> opts_to_attributes()}>) <>
      (canvas.shapes |> Tonic.SVG.render()) <>
      ~s(</svg>)
  end

end
