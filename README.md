# Sendex

In a terminal, go to Sendex folder and type `iex -S mix` to compile and start the application.

Once in iex, type `Sendex.help` to get a short notice on how to use the application.

To send a customized email to all the recipients present in the file, just type `Sendex.send_all(file_path, template_path, attachments_list)`; `file_path` being a `.csv` file formatted as below; `template_path` being a Phoenix_html `.html.eex` file and `attachments_list` being a keyword list with `:img` and `:attachment` keys (`:img` is to embed an attached image into the email, attachment is for an attached document, like a `.pdf` for example).

The email template should be stored in `./priv/templates/`; the email attachments should be stored in `./priv/attachments/`; the CSV file containing the list of recipients can be stored in `./priv/spreadsheets/`; the result of the sending will be stored in `./priv/results/`.

Right now, the CSV file should be formatted as follow (because I had to work with a CSV file having this format): `title`, `name`, `_`, `_`, `_`, `_`, `city`, `mail`, `_`, `_` .
- `Title` is how you call the recipient (ex: "M.", "Ms.");
- `Name` is the recipient's name (full or just family name, ex: "Smith" or "John Smith");
- `City` is the city the recipient works in (used to customize the email title and body);
- `Mail` is the email address the email will be sent to;
- `_` are unimportant columns that you can use for your personal needs; for example, if you need more fields to customize your email, you can dedicate a column to: recipient's job position, recipient's age, recipient's nickname, recipient's id, etc. Note that you'll need to update the `%Recipient{}` model and the `build_mailing_list/1` function in order to make the application work with your columns.

I used Sendgrid to send the emails, but feel free to change the Swoosh adapter in the config to use your favorite service.