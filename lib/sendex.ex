defmodule Sendex do
  @moduledoc """
  Documentation for `Sendex`.
  """
  use Swoosh.Mailer, otp_app: :sendex
  use Phoenix.Swoosh, template_root: "priv/templates"

  import Swoosh.Email

  require Logger

  alias NimbleCSV.RFC4180, as: CSV
  alias Sendex.{Recipient, Mailer}

  @sender %{
    name: Application.compile_env(:sendex, :sender_name),
    mail: Application.compile_env(:sendex, :sender_mail),
    reply: Application.compile_env(:sendex, :reply_to)
  }

  def send_all(csv_file) do
    # recipients_map = build_mailing_list("./priv/spreadsheets/octobre_2023.csv")
    recipients_map = csv_file |> build_mailing_list()

    {:ok, mailer} = recipients_map |> Mailer.start_link()

    for {recipient_key, %Recipient{sending_status: {result, _}} = recipient_value} =
          recipient_tuple <-
          recipients_map,
        result != :ok do
      result =
        recipient_value
        |> build_mail()
        |> deliver()

      result
      |> case do
        {:ok, data} ->
          Logger.info(
            "Email successfully sent to Recipient n°#{recipient_key} with data #{inspect(data)}"
          )

        {:error, message} ->
          Logger.error(
            "Email sending to Recipient n°#{recipient_key} failed with message #{inspect(message)}"
          )
      end

      Mailer.send_to(mailer, recipient_tuple, result)
    end

    # use these results to build a report
    Mailer.get_results(mailer)

    Mailer.stop_mailer(mailer)
  end

  defp build_mailing_list(file) when file |> is_binary,
    do: File.read!(file) |> CSV.parse_string() |> build_mailing_list()

  defp build_mailing_list(file) when file |> is_list do
    file
    |> Enum.reduce(%{}, fn
      ["", "", "", "", "", "", "", "", "", ""], acc ->
        acc

      [
        "Civilité",
        "Nom",
        "Carte",
        "Support",
        "Adresse",
        "CP",
        "Ville",
        "Mail pro",
        "Fonction",
        "Structure"
      ],
      acc ->
        acc

      [title, name, _, _, _, _, city, mail, _, _], acc ->
        recipient = %Recipient{
          title: title,
          name: name,
          city: city,
          mail: mail
        }

        acc |> Map.put(acc |> map_size(), recipient)
    end)
  end

  def help,
    do: Logger.notice("To send emails to the mailing list, type: file_path |> Sendex.send_all")

  @spec build_mail(%Recipient{}) :: %Swoosh.Email{}
  defp build_mail(%Recipient{title: title, name: name, city: city, mail: mail}) do
    new()
    |> to({name, mail})
    |> from({@sender.name, @sender.mail})
    |> reply_to({@sender.name, @sender.reply})
    |> subject("Proposition spectacle d'humour : Sandrine accouche !")
    |> render_body("octobre_2023.html", %{
      title: title,
      name: name,
      city: city,
      img_src: "cid:post_it.png"
    })
    |> attachment(
      Swoosh.Attachment.new({:data, File.read!("./priv/attachments/post_it.png")},
        filename: "post_it.png",
        content_type: "image/png",
        type: :inline
      )
    )
    |> attachment("./priv/attachments/DP_SANDRINE_ACCOUCHE_2023.pdf")
  end
end
