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
    phone: Application.compile_env(:sendex, :sender_phone),
    mail: Application.compile_env(:sendex, :sender_mail),
    reply: Application.compile_env(:sendex, :reply_to)
  }

  @spec help() :: :ok
  def help,
    do:
      Logger.notice(
        "To send emails to the mailing list, type: Sendex.send_all(file_path, template_path, attachments_list)"
      )

  def send_all(
        csv_file,
        template,
        attachments
      ) do
    recipients_map = csv_file |> build_mailing_list()

    {:ok, mailer} = recipients_map |> Mailer.start_link()

    for {recipient_key, %Recipient{sending_status: {result, _}} = recipient_value} =
          recipient_tuple <-
          recipients_map,
        result != :ok do
      result =
        recipient_value
        |> build_mail(template, attachments)
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
    results =
      mailer
      |> Mailer.get_results()
      |> Enum.map(fn {_key,
                      %Recipient{
                        title: title,
                        name: name,
                        city: city,
                        mail: mail,
                        sending_status: {status, data}
                      }} ->
        [title, name, city, mail, status, data |> Enum.map(fn {k, v} -> "#{k}: #{v}" end)]
      end)

    results =
      [["title", "name", "city", "mail", "status", "data"] | results]
      |> CSV.dump_to_iodata()

    "./priv/results/results.csv"
    |> File.write!(results)

    Mailer.stop_mailer(mailer)
  end

  @spec build_mailing_list(binary() | list()) :: %{non_neg_integer() => %Recipient{}}
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

  @spec build_mail(%Recipient{}, String.t(), img: String.t(), attachment: String.t()) ::
          %Swoosh.Email{}
  defp build_mail(
         %Recipient{title: title, name: name, city: city, mail: mail},
         template,
         img: img,
         attachment: attachment
       ) do
    new()
    |> to({name, mail})
    |> from({@sender.name, @sender.mail})
    |> reply_to({@sender.name, @sender.reply})
    |> subject("Sandrine accouche à #{city}! (spectacle d'humour)")
    |> render_body(template, %{
      sender_name: @sender.name,
      sender_phone: @sender.phone,
      sender_mail: @sender.mail,
      title: title,
      name: name,
      city: city,
      img_src: "cid:" <> img
    })
    |> attachment(
      Swoosh.Attachment.new({:data, File.read!("./priv/attachments/" <> img)},
        filename: img,
        content_type: "image/png",
        type: :inline
      )
    )
    |> attachment("./priv/attachments/" <> attachment)
  end
end
