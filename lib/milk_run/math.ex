defmodule MilkRun.Math do
  def float_to_int float_value do
    float_value
    |> Float.round()
    |> trunc
  end
end
