# frozen_string_literal: true

# Numbers entered without a country code are parsed as US numbers;
# any +-prefixed international number is still accepted.
Phonelib.default_country = "US"
