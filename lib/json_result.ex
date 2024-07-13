defmodule JsonResult do


  def create_error_struct(error_message) do
    %{result: %{ success: false},  error_message: error_message}
  end


end
