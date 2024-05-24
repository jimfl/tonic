defmodule Tonic.Canvas do
  defstruct transform_stack: [],
            grid_stack: [],
            start_tags: [],
            end_tag_stack: []

  def new({width, height}, options \\ []) do
    xmlns = {:xmlns, "http://www.w3.org/2000/svg"}

    %__MODULE__{
      start_tags: [%{tag: :svg, options: [xmlns, {:width, width}, {:height, height} | options]}],
      end_tag_stack: [:svg],
      grid_stack: [fn p -> p end]
    }
  end

  defp build_tag(%{tag: tag, options: options}) do
    attributes = for {k, v} <- options, into: "", do: ~s( #{k}="#{v}")
    ~s(<#{tag}#{attributes} >)
  end

  defp build_tag(%{min_tag: tag, options: options}) do
    attributes = for {k, v} <- options, into: "", do: ~s( #{k}="#{v}")
    ~s(<#{tag}#{attributes} />)
  end

  defp build_tag(%{end_tag: tag}) do
    ~s(</#{tag}>)
  end

  def render(canvas = %__MODULE__{}) do
    [
      canvas.start_tags |> Enum.reverse() |> Enum.map(fn tag -> build_tag(tag) end)
      | canvas.end_tag_stack |> Enum.map(fn tag -> ~s(</#{tag}>) end)
    ]
    |> IO.iodata_to_binary()
  end
end
