defmodule Tonic.Canvas do
    defstruct [
    width: 0, 
    height: 0, 
    options: [],
    shapes: [],
    grid_stack: [&Tonic.Grid.identity/1]
  ]

  def to_svg(canvas) do
    ~s(<svg xmlns="http://www.w3.org/2000/svg" width="#{canvas.width}" height="#{canvas.height}">)
    <> (canvas.shapes |> Tonic.SVG.render())
    <> ~s(</svg>)
  end
end
