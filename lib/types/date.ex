defmodule Timex.Ecto.Date do
  use Timex

  @behaviour Ecto.Type

  def type, do: :date

  def cast(%Date{} = date), do: {:ok, date}
  # Support embeds_one/embeds_many
  def cast(%{"calendar" => _,
             "year" => y, "month" => m, "day" => d}) do
    date = Timex.to_date({y,m,d})
    {:ok, date}
  end
  def cast(date) when is_binary(date) do
    if String.contains?(date, "T") do
      case DateTime.from_iso8601(date) do
        {:ok, d, _} -> load({d.year,d.month,d.day})
        :error -> :error
      end
    else
      case Date.from_iso8601(date) do
        {:ok, d} -> load({d.year,d.month,d.day})
        :error -> :error
      end
    end
  end
  def cast(datetime) do
    case Timex.to_date(datetime) do
      {:error, _} ->
        :error
      %Date{} = d -> {:ok, d}
    end
  end

  def load({_year, _month, _day} = date), do: {:ok, Timex.to_date(date)}

  def load(%Date{} = date) do
    {:ok, date}
  end

  def load(_), do: :error

  @doc """
  Convert to native Ecto representation
  """
  def dump(%DateTime{} = datetime) do
    case Timex.Timezone.convert(datetime, "Etc/UTC") do
      %DateTime{year: y, month: m, day: d} -> Date.from_erl({y, m, d})
      {:error, _} -> :error
    end
  end
  def dump(%Date{} = date) do
    {:ok, date}
  end
  def dump({y, m, d}) do
    Date.from_erl({y, m, d})
  end
  def dump(datetime) do
    case Timex.to_erl(datetime) do
      {:error, _}   -> :error
      {{y,m,d}=d,_} -> Date.from_erl({y, m, d})
      {y,m,d} = d   -> Date.from_erl({y, m, d})
    end
  end

  def autogenerate(precision \\ :sec)
  def autogenerate(_) do
    {date, {_, _, _}} = :erlang.universaltime
    load(date) |> elem(1)
  end

  def equal?(term1, term2) do
    term1 == term2
  end
end
