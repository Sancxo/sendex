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

  @mailing_list_path "./priv/mailing_lists/mailing_list.csv"
  @mail_batch 100

  @spec help() :: :ok
  def help do
    Logger.notice("""
    - To import a csv file as a mailing list, type: Sendex.import_mailing_list(file_path)
    - After that, to send emails to each unreached contact of the created mailing list, type: Sendex.send_all(file_path, template_path, attachments_list)
    """)
  end

  @spec send_all(binary(), binary(), img: binary(), attachment: binary()) :: :ok
  def send_all(
        csv_file,
        template,
        attachments
      ) do
    recipients_map = csv_file |> get_mailing_list()

    {:ok, mailer} = recipients_map |> Mailer.start_link()

    for {recipient_key, %Recipient{sending_status: {status, _}} = recipient_data} = recipient <-
          recipients_map,
        status != "ok",
        reduce: 0 do
      acc when acc < @mail_batch ->
        result =
          recipient_data
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

        Mailer.update_status(mailer, recipient, result)

        acc + 1

      acc ->
        acc
    end

    # use the results in Mailer state to build a new mailing list with the new sending_status
    mailer
    |> Mailer.get_results()
    |> build_mailing_list()

    Mailer.stop_mailer(mailer)
  end

  @spec import_mailing_list(binary() | list()) :: :ok
  def import_mailing_list(file) when file |> is_binary,
    do: file |> File.read!() |> CSV.parse_string() |> import_mailing_list()

  def import_mailing_list(file) when file |> is_list do
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
    # Doing a new mailing list from the recipients_map allows us to be sure that each contact is formatted with the %Recipient{} model.
    |> build_mailing_list()
  end

  @spec build_mailing_list(Mailer.recipients_map()) :: :ok
  defp build_mailing_list(recipients_map) do
    formatted_csv_file =
      recipients_map
      |> Enum.map(fn {key,
                      %Recipient{
                        title: title,
                        name: name,
                        city: city,
                        mail: mail,
                        sending_status: {status, data}
                      }} ->
        [key, title, name, city, mail, status, inspect(data)]
      end)

    formatted_csv_file =
      [["no", "title", "name", "city", "mail", "status", "data"] | formatted_csv_file]
      |> CSV.dump_to_iodata()

    @mailing_list_path
    |> File.write!(formatted_csv_file)
  end

  @spec get_mailing_list(binary()) :: Mailer.recipients_map()
  defp get_mailing_list(file_path) do
    file_path
    |> File.read!()
    |> CSV.parse_string()
    |> Enum.reduce(%{}, fn
      [key, title, name, city, mail, status, data], acc ->
        recipient = %Recipient{
          title: title,
          name: name,
          city: city,
          mail: mail,
          sending_status: {status, data}
        }

        acc |> Map.put(key, recipient)
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
    |> subject("Proposition spectacle d'humour: Sandrine accouche !")
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
