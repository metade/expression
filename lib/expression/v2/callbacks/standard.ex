defmodule Expression.V2.Callbacks.Standard do
  @moduledoc """
  Callback functions to be used in Expressions.

  This is the same idea as `Expression.Callbacks.Standard` but
  it's in a rough shape, mostly to just prove that this all works.
  """

  use Expression.V2.Callbacks
  use Expression.V2.Autodoc

  alias Expression.DateHelpers

  @punctuation_pattern ~r/\s*[,:;!?.-]\s*|\s/
  @doc """
  Defines a new date value
  """
  @expression_doc doc: "Construct a date from year, month, and day integers",
                  expression: "date(year, month, day)",
                  context: %{
                    "year" => 2022,
                    "month" => 1,
                    "day" => 31
                  },
                  result: ~D[2022-01-31]
  def date(_ctx, year, month, day) do
    fields = [
      calendar: Calendar.ISO,
      year: year,
      month: month,
      day: day,
      time_zone: "Etc/UTC",
      zone_abbr: "UTC"
    ]

    struct(Date, fields)
  end

  @doc """
  Calculates a new datetime based on the offset and unit provided.

  The unit can be any of the following values:

  * "Y" for years
  * "M" for months
  * "W" for weeks
  * "D" for days
  * "h" for hours
  * "m" for minutes
  * "s" for seconds

  Specifying a negative offset results in date calculations back in time.

  """
  @expression_doc doc: "Calculates a new datetime based on the offset and unit provided.",
                  expression: "datetime_add(datetime, offset, unit)",
                  context: %{
                    "datetime" => ~U[2022-07-31 00:00:00Z],
                    "offset" => 1,
                    "unit" => "M"
                  },
                  result: ~U[2022-08-31 00:00:00Z]
  @expression_doc doc: "Leap year handling in a leap year.",
                  expression: "datetime_add(date(2020, 02, 28), 1, \"D\")",
                  result: ~U[2020-02-29 00:00:00.000000Z]
  @expression_doc doc: "Leap year handling outside of a leap year.",
                  expression: "datetime_add(date(2021, 02, 28), 1, \"D\")",
                  result: ~U[2021-03-01 00:00:00.000000Z]
  @expression_doc doc: "Negative offsets",
                  expression: "datetime_add(date(2020, 02, 29), -1, \"D\")",
                  result: ~U[2020-02-28 00:00:00.000000Z]
  def datetime_add(_ctx, datetime, offset, unit) do
    datetime = DateHelpers.extract_datetimeish(datetime)

    case unit do
      "Y" -> Timex.shift(datetime, years: offset)
      "M" -> Timex.shift(datetime, months: offset)
      "W" -> Timex.shift(datetime, weeks: offset)
      "D" -> Timex.shift(datetime, days: offset)
      "h" -> Timex.shift(datetime, hours: offset)
      "m" -> Timex.shift(datetime, minutes: offset)
      "s" -> Timex.shift(datetime, seconds: offset)
    end
  end

  @doc """
  Converts date stored in text to an actual date object and
  formats it using `strftime` formatting.

  It will fallback to "%Y-%m-%d %H:%M:%S" if no formatting is supplied

  """
  @expression_doc doc: "Convert a date from a piece of text to a formatted date string",
                  expression: "datevalue(\"2022-01-01\")",
                  result: %{"__value__" => "2022-01-01 00:00:00", "date" => ~D[2022-01-01]}
  @expression_doc doc: "Convert a date from a piece of text and read the date field",
                  expression: "datevalue(\"2022-01-02\").date",
                  result: ~D[2022-01-02]
  @expression_doc doc: "Convert a date value and read the date field",
                  expression: "datevalue(date(2022, 1, 3)).date",
                  result: ~D[2022-01-03]
  def datevalue(_ctx, date, format \\ "%Y-%m-%d %H:%M:%S") do
    case DateHelpers.extract_dateish(date) do
      nil -> %{"__value__" => "", "date" => nil}
      date -> %{"__value__" => Timex.format!(date, format, :strftime), "date" => date}
    end
  end

  @doc """
  Returns only the day of the month of a date (1 to 31)
  """
  @expression_doc doc: "Getting today's day of the month",
                  expression: "day(date(2022, 9, 10))",
                  result: 10
  @expression_doc doc: "Getting today's day of the month",
                  expression: "day(now())",
                  fake_result: DateTime.utc_now().day
  def day(_ctx, %{day: day} = _date) do
    day
  end

  @doc """
  Moves a date by the given number of months
  """
  @expression_doc doc: "Move the date in a date object by 1 month",
                  expression: "edate(right_now, 1)",
                  context: %{
                    "right_now" => DateTime.new!(Date.new!(2022, 1, 1), Time.new!(0, 0, 0))
                  },
                  result:
                    Timex.shift(DateTime.new!(Date.new!(2022, 1, 1), Time.new!(0, 0, 0)),
                      months: 1
                    )
  @expression_doc doc: "Move the date store in a piece of text by 1 month",
                  expression: "edate(\"2022-10-10\", 1)",
                  result: ~D[2022-11-10]
  def edate(_ctx, date, months) do
    DateHelpers.extract_dateish(date) |> Timex.shift(months: months)
  end

  @doc """
  Returns only the hour of a datetime (0 to 23)
  """
  @expression_doc doc: "Get the current hour",
                  expression: "hour(now())",
                  fake_result: DateTime.utc_now().hour
  def hour(_ctx, %{hour: hour} = _date) do
    hour
  end

  @doc """
  Returns only the minute of a datetime (0 to 59)
  """
  @expression_doc doc: "Get the current minute",
                  expression: "minute(now())",
                  fake_result: DateTime.utc_now().minute
  def minute(_ctx, date) do
    %{minute: minute} = DateHelpers.extract_datetimeish(date)
    minute
  end

  @doc """
  Returns only the month of a date (1 to 12)
  """
  @expression_doc doc: "Get the current month",
                  expression: "month(now())",
                  fake_result: DateTime.utc_now().month
  def month(_ctx, %{month: month} = _date) do
    month
  end

  @doc """
  Returns the current date time as UTC

  ```
  It is currently @NOW()
  ```
  """
  @expression_doc doc: "return the current timestamp as a DateTime value",
                  expression: "now()",
                  fake_result: DateTime.utc_now()
  @expression_doc doc: "return the current datetime and format it using `datevalue`",
                  expression: "datevalue(now(), \"%Y-%m-%d\")",
                  fake_result: %{
                    "__value__" => DateTime.utc_now() |> Timex.format!("%Y-%m-%d", :strftime),
                    "date" => DateTime.utc_now()
                  }
  def now(_ctx) do
    DateTime.utc_now()
  end

  @doc """
  Returns only the second of a datetime (0 to 59)
  """
  @expression_doc expression: "second(now)",
                  context: %{"now" => DateTime.utc_now()},
                  fake_result: DateTime.utc_now().second
  def second(_ctx, %{second: second} = _date) do
    second
  end

  @doc """
  Defines a time value which can be used for time arithmetic
  """
  @expression_doc expression: "time(12, 13, 14)",
                  result: %Time{hour: 12, minute: 13, second: 14}
  def time(_ctx, hours, minutes, seconds) do
    %Time{hour: hours, minute: minutes, second: seconds}
  end

  @doc """
  Converts time stored in text to an actual time
  """
  @expression_doc expression: "timevalue(\"2:30\")",
                  result: %Time{hour: 2, minute: 30, second: 0}
  @expression_doc expression: "timevalue(\"2:30:55\")",
                  result: %Time{hour: 2, minute: 30, second: 55}
  def timevalue(_ctx, expression) when is_binary(expression) do
    parts =
      expression
      |> String.split(":")
      |> Enum.map(&String.to_integer/1)

    defaults = [
      hour: 0,
      minute: 0,
      second: 0
    ]

    fields =
      [:hour, :minute, :second]
      |> Enum.zip(parts)

    struct(Time, Keyword.merge(defaults, fields))
  end

  @doc """
  Returns the current date
  """
  @expression_doc expression: "today()",
                  fake_result: Date.utc_today()
  def today(_ctx) do
    Date.utc_today()
  end

  @doc """
  Returns the day of the week of a date (1 for Sunday to 7 for Saturday)
  """
  @expression_doc expression: "weekday(today)",
                  context: %{"today" => ~D[2022-11-06]},
                  result: 1
  @expression_doc expression: "weekday(today)",
                  context: %{"today" => ~D[2022-11-01]},
                  result: 3
  def weekday(_ctx, date) do
    iso_week_day = Timex.weekday(date)

    if iso_week_day == 7 do
      1
    else
      iso_week_day + 1
    end
  end

  @doc """
  Returns only the year of a date
  """
  @expression_doc expression: "year(now)",
                  context: %{"now" => DateTime.utc_now()},
                  fake_result: DateTime.utc_now().year
  def year(_ctx, date) do
    %{year: year} = DateHelpers.extract_dateish(date)
    year
  end

  @doc """
  Returns `true` if and only if all its arguments evaluate to `true`
  """
  @expression_doc expression: "and(contact.gender = \"F\", contact.age >= 18)",
                  code_expression: "contact.gender = \"F\" and contact.age >= 18",
                  context: %{
                    "contact" => %{
                      "gender" => "F",
                      "age" => 32
                    }
                  },
                  result: true
  @expression_doc expression: "and(contact.gender = \"F\", contact.age >= 18)",
                  code_expression: "contact.gender = \"F\" and contact.age >= 18",
                  context: %{
                    "contact" => %{
                      "gender" => "?",
                      "age" => 32
                    }
                  },
                  result: false
  def and_vargs(_ctx, arguments) do
    Enum.all?(arguments, & &1)
  end

  @doc """
  Returns `false` if the argument supplied evaluates to truth-y
  """
  @expression_doc expression: "not(false)", result: true
  def not_(_ctx, argument) do
    !argument
  end

  @doc """
  Returns `true` if any argument is `true`.
  Returns the first truthy value found or otherwise false.

  Accepts any amount of arguments for testing truthiness.
  """
  @expression_doc doc: "Return true if any of the values are true",
                  expression: "or(true, false)",
                  code_expression: "true or false",
                  result: true
  @expression_doc doc: "Return the first value that is truthy",
                  expression: "or(false, \"foo\")",
                  code_expression: "false or \"foo\"",
                  result: "foo"
  @expression_doc expression: "or(true, true)",
                  code_expression: "true or true",
                  result: true
  @expression_doc expression: "or(false, false)",
                  code_expression: "false or false",
                  result: false
  @expression_doc expression: "or(a, b)",
                  context: %{"a" => false, "b" => "bee"},
                  code_expression: "a or b",
                  result: "bee"
  @expression_doc expression: "or(a, b)",
                  context: %{"a" => "a", "b" => false},
                  code_expression: "a or b",
                  result: "a"
  @expression_doc expression: "or(b, b)",
                  context: %{},
                  code_expression: "b or b",
                  result: false
  def or_vargs(_ctx, arguments) do
    Enum.reduce_while(arguments, false, fn arg, acc ->
      if(arg, do: {:halt, arg}, else: {:cont, acc})
    end)
  end

  @doc """
  Returns the absolute value of a number
  """
  @expression_doc expression: "abs(-1)",
                  result: 1
  def abs(_ctx, number) do
    Kernel.abs(number)
  end

  @doc """
  Returns the maximum value of all arguments
  """
  @expression_doc expression: "max(1, 2, 3)",
                  result: 3
  def max_vargs(_ctx, arguments) do
    Enum.max(arguments)
  end

  @doc """
  Returns the minimum value of all arguments
  """
  @expression_doc expression: "min(1, 2, 3)",
                  result: 1
  def min_vargs(_ctx, arguments) do
    Enum.min(arguments)
  end

  @doc """
  Returns the result of a number raised to a power - equivalent to the ^ operator
  """
  @expression_doc expression: "power(2, 3)",
                  fake_result: 8.0
  def power(_ctx, a, b) do
    :math.pow(a, b)
  end

  @doc """
  Returns the sum of all arguments, equivalent to the + operator

  ```
  You have @SUM(contact.reports, contact.forms) reports and forms
  ```
  """
  @expression_doc expression: "sum(1, 2, 3)",
                  result: 6
  def sum_vargs(_ctx, arguments) do
    Enum.sum(arguments)
  end

  @doc """
  Returns the character specified by a number

  ```
  > "As easy as @char(65), @char(66), @char(67)"
  "As easy as A, B, C"
  ```
  """
  @expression_doc expression: "char(65)",
                  result: "A"
  def char(_ctx, code) do
    <<code>>
  end

  @doc """
  Removes all non-printable characters from a text string
  """
  @expression_doc expression: "clean(value)",
                  context: %{"value" => <<65, 0, 66, 0, 67>>},
                  result: "ABC"
  def clean(_ctx, binary) do
    binary
    |> String.graphemes()
    |> Enum.filter(&String.printable?/1)
    |> Enum.join("")
  end

  @doc """
  Returns a numeric code for the first character in a text string

  ```
  > "The numeric code of A is @CODE(\\"A\\")"
  "The numeric code of A is 65"
  ```
  """
  @expression_doc expression: "code(\"A\")",
                  result: 65
  def code(_ctx, <<code>>) do
    code
  end

  @doc """
  Joins text strings into one text string

  ```
  > "Your name is @CONCATENATE(contact.first_name, \\" \\", contact.last_name)"
  "Your name is name surname"
  ```
  """
  @expression_doc expression: "concatenate(contact.first_name, \" \", contact.last_name)",
                  context: %{
                    "contact" => %{
                      "first_name" => "name",
                      "last_name" => "surname"
                    }
                  },
                  result: "name surname"
  def concatenate_vargs(_ctx, arguments) do
    Enum.join(arguments, "")
  end

  @doc """
  Formats the given number in decimal format using a period and commas

  ```
  > You have @fixed(contact.balance, 2) in your account
  "You have 4.21 in your account"
  ```
  """
  @expression_doc expression: "fixed(4.209922, 2, false)",
                  result: "4.21"
  @expression_doc expression: "fixed(4000.424242, 4, true)",
                  result: "4,000.4242"
  @expression_doc expression: "fixed(3.7979, 2, false)",
                  result: "3.80"
  @expression_doc expression: "fixed(3.7979, 2)",
                  result: "3.80"
  def fixed(_ctx, number, precision, no_commas \\ false)

  def fixed(_ctx, number, precision, false),
    do: Number.Delimit.number_to_delimited(number, precision: precision)

  def fixed(_ctx, number, precision, true),
    do:
      Number.Delimit.number_to_delimited(number,
        precision: precision,
        delimiter: ",",
        separator: "."
      )

  @doc """
  Returns the first characters in a text string. This is Unicode safe.
  """
  @expression_doc expression: "left(\"foobar\", 4)",
                  result: "foob"

  @expression_doc expression:
                    "left(\"Умерла Мадлен Олбрайт - первая женщина на посту главы Госдепа США\", 20)",
                  result: "Умерла Мадлен Олбрай"
  def left(_ctx, binary, size) do
    String.slice(binary, 0, size)
  end

  @doc """
  Returns the number of characters in a text string
  """
  @expression_doc expression: "len(\"foo\")",
                  result: 3
  @expression_doc expression: "len(\"zoë\")",
                  result: 3
  def len(_ctx, binary) do
    String.length(binary)
  end

  @doc """
  Converts a text string to lowercase
  """
  @expression_doc expression: "lower(\"Foo Bar\")",
                  result: "foo bar"
  def lower(_ctx, binary) do
    String.downcase(binary)
  end

  @doc """
  Capitalizes the first letter of every word in a text string
  """
  @expression_doc expression: "proper(\"foo bar\")",
                  result: "Foo Bar"
  def proper(_ctx, binary) do
    binary
    |> String.split(" ")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  @doc """
  Repeats text a given number of times
  """
  @expression_doc expression: "rept(\"*\", 10)",
                  result: "**********"
  def rept(_ctx, value, amount) do
    String.duplicate(value, amount)
  end

  @doc """
  Returns the last characters in a text string.
  This is Unicode safe.
  """
  @expression_doc expression: "right(\"testing\", 3)",
                  result: "ing"
  @expression_doc expression:
                    "right(\"Умерла Мадлен Олбрайт - первая женщина на посту главы Госдепа США\", 20)",
                  result: "ту главы Госдепа США"
  def right(_ctx, binary, size) do
    String.slice(binary, -size, size)
  end

  @doc """
  Substitutes new_text for old_text in a text string. If instance_num is given, then only that instance will be substituted
  """
  @expression_doc expression: "substitute(\"I can't\", \"can't\", \"can do\")",
                  result: "I can do"
  def substitute(_ctx, subject, pattern, replacement) do
    String.replace(subject, pattern, replacement)
  end

  @doc """
  Returns the unicode character specified by a number
  """
  @expression_doc expression: "unichar(65)", result: "A"
  @expression_doc expression: "unichar(233)", result: "é"
  def unichar(_ctx, code) do
    <<code::utf8>>
  end

  @doc """
  Returns a numeric code for the first character in a text string
  """
  @expression_doc expression: "unicode(\"A\")", result: 65
  @expression_doc expression: "unicode(\"é\")", result: 233
  def unicode(_ctx, <<code::utf8>>) do
    code
  end

  @doc """
  Converts a text string to uppercase
  """
  @expression_doc expression: "upper(\"foo\")",
                  result: "FOO"
  def upper(_ctx, binary) do
    String.upcase(binary)
  end

  @doc """
  Returns the first word in the given text - equivalent to WORD(text, 1)
  """
  @expression_doc expression: "first_word(\"foo bar baz\")",
                  result: "foo"
  def first_word(_ctx, binary) do
    [word | _] = String.split(binary, " ")
    word
  end

  @doc """
  Formats a number as a percentage
  """
  @expression_doc expression: "percent(2/10)", result: "20%"
  @expression_doc expression: "percent(0.2)", result: "20%"
  @expression_doc expression: "percent(d)", context: %{"d" => "0.2"}, result: "20%"
  def percent(_ctx, float) do
    with float when is_number(float) <- parse_float(float) do
      Number.Percentage.number_to_percentage(float * 100, precision: 0)
    end
  end

  @doc """
  Formats digits in text for reading in TTS
  """
  @expression_doc expression: "read_digits(\"+271\")", result: "plus two seven one"
  def read_digits(_ctx, binary) do
    map = %{
      "+" => "plus",
      "0" => "zero",
      "1" => "one",
      "2" => "two",
      "3" => "three",
      "4" => "four",
      "5" => "five",
      "6" => "six",
      "7" => "seven",
      "8" => "eight",
      "9" => "nine"
    }

    binary
    |> String.graphemes()
    |> Enum.map(fn grapheme -> Map.get(map, grapheme, nil) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  @doc """
  Removes the first word from the given text. The remaining text will be unchanged
  """
  @expression_doc expression: "remove_first_word(\"foo bar\")", result: "bar"
  @expression_doc expression: "remove_first_word(\"foo-bar\", \"-\")", result: "bar"
  def remove_first_word(_ctx, binary) do
    separator = " "
    tl(String.split(binary, separator)) |> Enum.join(separator)
  end

  def remove_first_word(_ctx, binary, separator) do
    tl(String.split(binary, separator)) |> Enum.join(separator)
  end

  @doc """
  Extracts the nth word from the given text string. If stop is a negative number,
  then it is treated as count backwards from the end of the text. If by_spaces is
  specified and is `true` then the function splits the text into words only by spaces.
  Otherwise the text is split by punctuation characters as well
  """
  @expression_doc expression: "word(\"hello cow-boy\", 2)", result: "cow"
  @expression_doc expression: "word(\"hello cow-boy\", 2, true)", result: "cow-boy"
  @expression_doc expression: "word(\"hello cow-boy\", -1)", result: "boy"
  def word(_ctx, binary, n) do
    parts = String.split(binary, @punctuation_pattern)

    # This slicing seems off.
    [part] =
      if n < 0 do
        Enum.slice(parts, n, 1)
      else
        Enum.slice(parts, n - 1, 1)
      end

    part
  end

  def word(_ctx, binary, n, by_spaces) do
    splitter = if(by_spaces, do: " ", else: @punctuation_pattern)
    parts = String.split(binary, splitter)

    # This slicing seems off.
    [part] =
      if n < 0 do
        Enum.slice(parts, n, 1)
      else
        Enum.slice(parts, n - 1, 1)
      end

    part
  end

  @doc """
  Returns the number of words in the given text string. If by_spaces is specified and is `true` then the function splits the text into words only by spaces. Otherwise the text is split by punctuation characters as well

  ```
  > You entered @word_count("one two three") words
  You entered 3 words
  ```
  """
  @expression_doc expression: "word_count(\"hello cow-boy\")", result: 3
  @expression_doc expression: "word_count(\"hello cow-boy\", true)", result: 2
  def word_count(_ctx, binary) do
    binary
    |> String.split(@punctuation_pattern)
    |> Enum.count()
  end

  def word_count(_ctx, binary, by_spaces) do
    splitter = if(by_spaces, do: " ", else: @punctuation_pattern)

    binary
    |> String.split(splitter)
    |> Enum.count()
  end

  @doc """
  Extracts a substring of the words beginning at start, and up to but not-including stop.
  If stop is omitted then the substring will be all words from start until the end of the text.
  If stop is a negative number, then it is treated as count backwards from the end of the text.
  If by_spaces is specified and is `true` then the function splits the text into words only by spaces.
  Otherwise the text is split by punctuation characters as well
  """
  @expression_doc expression: "word_slice(\"FLOIP expressions are fun\", 2, 4)",
                  result: "expressions are"
  @expression_doc expression: "word_slice(\"FLOIP expressions are fun\", 2)",
                  result: "expressions are fun"
  @expression_doc expression: "word_slice(\"FLOIP expressions are fun\", 1, -2)",
                  result: "FLOIP expressions"
  @expression_doc expression: "word_slice(\"FLOIP expressions are fun\", -1)",
                  result: "fun"
  def word_slice(_ctx, binary, start) do
    parts =
      binary
      |> String.split(" ")

    cond do
      start > 0 ->
        parts
        |> Enum.slice(start - 1, length(parts))
        |> Enum.join(" ")

      start < 0 ->
        parts
        |> Enum.slice(start..length(parts))
        |> Enum.join(" ")
    end
  end

  def word_slice(_ctx, binary, start, stop) do
    cond do
      stop > 0 ->
        binary
        |> String.split(@punctuation_pattern)
        |> Enum.slice((start - 1)..(stop - 2)//1)
        |> Enum.join(" ")

      stop < 0 ->
        binary
        |> String.split(@punctuation_pattern)
        |> Enum.slice((start - 1)..(stop - 1)//1)
        |> Enum.join(" ")
    end
  end

  def word_slice(_ctx, binary, start, stop, by_spaces) do
    splitter = if(by_spaces, do: " ", else: @punctuation_pattern)

    case stop do
      stop when stop > 0 ->
        binary
        |> String.split(splitter)
        |> Enum.slice((start - 1)..(stop - 2))
        |> Enum.join(" ")

      stop when stop < 0 ->
        binary
        |> String.split(splitter)
        |> Enum.slice((start - 1)..(stop - 1))
        |> Enum.join(" ")
    end
  end

  @doc """
  Returns `true` if the argument is a number.
  """
  @expression_doc expression: "isnumber(1)", result: true
  @expression_doc expression: "isnumber(1.0)", result: true
  @expression_doc expression: "isnumber(\"1.0\")", result: true
  @expression_doc expression: "isnumber(\"a\")", result: false
  def isnumber(_ctx, var) do
    case var do
      var when is_float(var) or is_integer(var) ->
        true

      var when is_binary(var) ->
        String.match?(var, ~r/^\d+?.?\d+$/)

      _var ->
        false
    end
  end

  @doc """
  Returns `true` if the argument is a boolean.
  """
  @expression_doc expression: "isbool(true)", result: true
  @expression_doc expression: "isbool(false)", result: true
  @expression_doc expression: "isbool(1)", result: false
  @expression_doc expression: "isbool(0)", result: false
  @expression_doc expression: "isbool(\"true\")", result: false
  @expression_doc expression: "isbool(\"false\")", result: false
  def isbool(_ctx, var) do
    var in [true, false]
  end

  @doc """
  Returns `true` if the argument is a string.
  """
  @expression_doc expression: "isstring(\"hello\")", result: true
  @expression_doc expression: "isstring(false)", result: false
  @expression_doc expression: "isstring(1)", result: false
  def isstring(_ctx, binary), do: is_binary(binary)

  defp search_words(haystack, words) do
    patterns =
      words
      |> String.split(" ")
      |> Enum.map(&Regex.escape/1)
      |> Enum.map(&Regex.compile!(&1, "i"))

    results =
      patterns
      |> Enum.map(&Regex.run(&1, haystack))
      |> Enum.map(fn
        [match] -> match
        nil -> nil
      end)
      |> Enum.reject(&is_nil/1)

    {patterns, results}
  end

  @doc """
  Tests whether all the words are contained in text

  The words can be in any order and may appear more than once.
  """
  @expression_doc expression: "has_all_words(\"the quick brown FOX\", \"the fox\")", result: true
  @expression_doc expression: "has_all_words(\"the quick brown FOX\", \"red fox\")", result: false
  def has_all_words(_ctx, haystack, words) do
    {patterns, results} = search_words(haystack, words)
    # future match result: Enum.join(results, " ")
    Enum.count(patterns) == Enum.count(results)
  end

  @doc """
  Tests whether any of the words are contained in the text

  Only one of the words needs to match and it may appear more than once.
  """
  @expression_doc expression: "has_any_word(\"The Quick Brown Fox\", \"fox quick\")",
                  result: %{"__value__" => true, "match" => "Quick Fox"}
  @expression_doc expression: "has_any_word(\"The Quick Brown Fox\", \"yellow\")",
                  result: %{"__value__" => false, "match" => nil}
  def has_any_word(_ctx, haystack, words) do
    haystack_words = String.split(haystack)
    haystacks_lowercase = Enum.map(haystack_words, &String.downcase/1)
    words_lowercase = String.split(words) |> Enum.map(&String.downcase/1)

    matched_indices =
      haystacks_lowercase
      |> Enum.with_index()
      |> Enum.filter(fn {haystack_word, _index} ->
        Enum.member?(words_lowercase, haystack_word)
      end)
      |> Enum.map(fn {_haystack_word, index} -> index end)

    matched_haystack_words = Enum.map(matched_indices, &Enum.at(haystack_words, &1))

    match? = Enum.any?(matched_haystack_words)

    %{
      "__value__" => match?,
      "match" => if(match?, do: Enum.join(matched_haystack_words, " "), else: nil)
    }
  end

  @doc """
  Tests whether text starts with beginning

  Both text values are trimmed of surrounding whitespace, but otherwise matching is
  strict without any tokenization.
  """
  @expression_doc expression: "has_beginning(\"The Quick Brown\", \"the quick\")", result: true
  @expression_doc expression: "has_beginning(\"The Quick Brown\", \"the    quick\")",
                  result: false
  @expression_doc expression: "has_beginning(\"The Quick Brown\", \"quick brown\")", result: false
  def has_beginning(_ctx, text, beginning) do
    case Regex.run(~r/^#{Regex.escape(beginning)}/i, to_string(text)) do
      # future match result: first
      [_first | _remainder] -> true
      nil -> false
    end
  end

  @doc """
  Tests whether `expression` contains a date formatted according to our environment

  This is very naively implemented with a regular expression.
  """
  @expression_doc expression: "has_date(\"the date is 15/01/2017\")", result: true
  @expression_doc expression: "has_date(\"there is no date here, just a year 2017\")",
                  result: false
  def has_date(_ctx, expression) do
    !!DateHelpers.extract_dateish(expression)
  end

  @doc """
  Tests whether `expression` is a date equal to `date_string`
  """
  @expression_doc expression: "has_date_eq(\"the date is 15/01/2017\", \"2017-01-15\")",
                  result: true
  @expression_doc expression:
                    "has_date_eq(\"there is no date here, just a year 2017\", \"2017-01-15\")",
                  result: false
  def has_date_eq(_ctx, expression, date_string) do
    found_date = DateHelpers.extract_dateish(expression)
    test_date = DateHelpers.extract_dateish(date_string)
    # Future match result: found_date
    found_date == test_date
  end

  @doc """
  Tests whether `expression` is a date after the date `date_string`
  """
  @expression_doc expression: "has_date_gt(\"the date is 15/01/2017\", \"2017-01-01\")",
                  result: true
  @expression_doc expression: "has_date_gt(\"the date is 15/01/2017\", \"2017-03-15\")",
                  result: false
  def has_date_gt(_ctx, expression, date_string) do
    found_date = DateHelpers.extract_dateish(expression)
    test_date = DateHelpers.extract_dateish(date_string)
    # future match result: found_date
    Date.compare(found_date, test_date) == :gt
  end

  @doc """
  Tests whether `expression` contains a date before the date `date_string`
  """
  @expression_doc expression: "has_date_lt(\"the date is 15/01/2017\", \"2017-06-01\")",
                  result: true
  @expression_doc expression: "has_date_lt(\"the date is 15/01/2021\", \"2017-03-15\")",
                  result: false
  def has_date_lt(_ctx, expression, date_string) do
    found_date = DateHelpers.extract_dateish(expression)
    test_date = DateHelpers.extract_dateish(date_string)
    # future match result: found_date
    Date.compare(found_date, test_date) == :lt
  end

  @doc """
  Tests whether an email is contained in text
  """
  @expression_doc expression: "has_email(\"my email is foo1@bar.com, please respond\")",
                  result: true
  @expression_doc expression: "has_email(\"i'm not sharing my email\")", result: false
  def has_email(_ctx, expression) do
    case Regex.run(~r/([a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)/, expression) do
      # future match result: match
      [_match | _] -> true
      nil -> false
    end
  end

  @doc """
  Returns whether the contact is part of group with the passed in UUID
  """
  @expression_doc expression:
                    "has_group(contact.groups, \"b7cf0d83-f1c9-411c-96fd-c511a4cfa86d\")",
                  context: %{
                    "contact" => %{
                      "groups" => [
                        %{
                          "uuid" => "b7cf0d83-f1c9-411c-96fd-c511a4cfa86d"
                        }
                      ]
                    }
                  },
                  result: true
  @expression_doc expression:
                    "has_group(contact.groups, \"00000000-0000-0000-0000-000000000000\")",
                  context: %{
                    "contact" => %{
                      "groups" => [
                        %{
                          "uuid" => "b7cf0d83-f1c9-411c-96fd-c511a4cfa86d"
                        }
                      ]
                    }
                  },
                  result: false
  def has_group(_ctx, groups, uuid) do
    group = Enum.find(groups, nil, &(&1["uuid"] == uuid))
    # future match result: group
    !!group
  end

  defp extract_numberish(value) when is_number(value), do: value

  defp extract_numberish(expression) do
    with [match] <-
           Regex.run(~r/([0-9]+\.?[0-9]*)/u, replace_arabic_numerals(expression), capture: :first),
         float <- parse_float(match) do
      float
    else
      # Regex can return nil
      nil -> nil
      # Float parsing can return :error
      :error -> nil
    end
  end

  defp replace_arabic_numerals(expression) when is_binary(expression) do
    replace_numerals(expression, %{
      "٠" => "0",
      "١" => "1",
      "٢" => "2",
      "٣" => "3",
      "٤" => "4",
      "٥" => "5",
      "٦" => "6",
      "٧" => "7",
      "٨" => "8",
      "٩" => "9"
    })
  end

  defp replace_numerals(expression, mapping) do
    mapping
    |> Enum.reduce(expression, fn {rune, replacement}, expression ->
      String.replace(expression, rune, replacement)
    end)
  end

  def parse_float(number) when is_number(number), do: number

  def parse_float(binary) when is_binary(binary) do
    case Float.parse(binary) do
      {float, ""} -> float
      _ -> nil
    end
  end

  @doc """
  Tests whether `expression` contains a number
  """
  @expression_doc expression: "has_number(\"the number is 42 and 5\")", result: true
  @expression_doc expression: "has_number(\"العدد ٤٢\")", result: true
  @expression_doc expression: "has_number(\"٠.٥\")", result: true
  @expression_doc expression: "has_number(\"0.6\")", result: true

  def has_number(_ctx, expression) do
    number = extract_numberish(expression)
    # future match result: number
    !!number
  end

  @doc """
  Tests whether `expression` contains a number equal to the value
  """

  @expression_doc expression: "has_number_eq(\"the number is 42\", 42)", result: true
  @expression_doc expression: "has_number_eq(\"the number is 42\", 42.0)", result: true
  @expression_doc expression: "has_number_eq(\"the number is 42\", \"42\")", result: true
  @expression_doc expression: "has_number_eq(\"the number is 42.0\", \"42\")", result: true
  @expression_doc expression: "has_number_eq(\"the number is 40\", \"42\")", result: false
  @expression_doc expression: "has_number_eq(\"the number is 40\", \"foo\")", result: false
  @expression_doc expression: "has_number_eq(\"four hundred\", \"foo\")", result: false
  def has_number_eq(_ctx, expression, float) do
    with number when is_number(number) <- extract_numberish(expression),
         float when is_number(float) <- parse_float(float) do
      # Future match result: number
      float == number
    else
      nil -> false
      :error -> false
    end
  end

  @doc """
  Tests whether `expression` contains a number greater than min
  """
  @expression_doc expression: "has_number_gt(\"the number is 42\", 40)", result: true
  @expression_doc expression: "has_number_gt(\"the number is 42\", 40.0)", result: true
  @expression_doc expression: "has_number_gt(\"the number is 42\", \"40\")", result: true
  @expression_doc expression: "has_number_gt(\"the number is 42.0\", \"40\")", result: true
  @expression_doc expression: "has_number_gt(\"the number is 40\", \"40\")", result: false
  @expression_doc expression: "has_number_gt(\"the number is 40\", \"foo\")", result: false
  @expression_doc expression: "has_number_gt(\"four hundred\", \"foo\")", result: false
  def has_number_gt(_ctx, expression, float) do
    with number when is_number(number) <- extract_numberish(expression),
         float when is_number(float) <- parse_float(float) do
      # Future match result: number
      number > float
    else
      nil -> false
      :error -> false
    end
  end

  @doc """
  Tests whether `expression` contains a number greater than or equal to min
  """
  @expression_doc expression: "has_number_gte(\"the number is 42\", 42)", result: true
  @expression_doc expression: "has_number_gte(\"the number is 42\", 42.0)", result: true
  @expression_doc expression: "has_number_gte(\"the number is 42\", \"42\")", result: true
  @expression_doc expression: "has_number_gte(\"the number is 42.0\", \"45\")", result: false
  @expression_doc expression: "has_number_gte(\"the number is 40\", \"45\")", result: false
  @expression_doc expression: "has_number_gte(\"the number is 40\", \"foo\")", result: false
  @expression_doc expression: "has_number_gte(\"four hundred\", \"foo\")", result: false
  def has_number_gte(_ctx, expression, float) do
    with number when is_number(number) <- extract_numberish(expression),
         float when is_number(float) <- parse_float(float) do
      # Future match result: number
      number >= float
    else
      nil -> false
      :error -> false
    end
  end

  @doc """
  Tests whether `expression` contains a number less than max
  """
  @expression_doc expression: "has_number_lt(\"the number is 42\", 44)", result: true
  @expression_doc expression: "has_number_lt(\"the number is 42\", 44.0)", result: true
  @expression_doc expression: "has_number_lt(\"the number is 42\", \"40\")", result: false
  @expression_doc expression: "has_number_lt(\"the number is 42.0\", \"40\")", result: false
  @expression_doc expression: "has_number_lt(\"the number is 40\", \"40\")", result: false
  @expression_doc expression: "has_number_lt(\"the number is 40\", \"foo\")", result: false
  @expression_doc expression: "has_number_lt(\"four hundred\", \"foo\")", result: false
  def has_number_lt(_ctx, expression, float) do
    with number when is_number(number) <- extract_numberish(expression),
         float when is_number(float) <- parse_float(float) do
      # Future match result: number
      number < float
    else
      nil -> false
      :error -> false
    end
  end

  @doc """
  Tests whether `expression` contains a number less than or equal to max
  """
  @expression_doc expression: "has_number_lte(\"the number is 42\", 42)", result: true
  @expression_doc expression: "has_number_lte(\"the number is 42\", 42.0)", result: true
  @expression_doc expression: "has_number_lte(\"the number is 42\", \"42\")", result: true
  @expression_doc expression: "has_number_lte(\"the number is 42.0\", \"40\")", result: false
  @expression_doc expression: "has_number_lte(\"the number is 40\", \"foo\")", result: false
  @expression_doc expression: "has_number_lte(\"four hundred\", \"foo\")", result: false
  @expression_doc expression: "has_number_lte(response, 5)",
                  context: %{"response" => 3},
                  result: true
  def has_number_lte(_ctx, expression, float) do
    with number when is_number(number) <- extract_numberish(expression),
         float when is_number(float) <- parse_float(float) do
      # Future match result: number
      number <= float
    else
      nil -> false
      :error -> false
    end
  end

  @doc """
  Tests whether the text contains only phrase

  The phrase must be the only text in the text to match
  """
  @expression_doc expression: "has_only_phrase(\"Quick Brown\", \"quick brown\")", result: true
  @expression_doc expression: "has_only_phrase(\"\", \" \")", result: true
  @expression_doc expression: "has_only_phrase(\"The Quick Brown Fox\", \"quick brown\")",
                  result: false

  def has_only_phrase(_ctx, expression, phrase) do
    result = Enum.map([expression, phrase], &String.downcase(String.trim(to_string(&1))))

    case result do
      # Future match result: expression
      [same, same] -> true
      _anything_else -> false
    end
  end

  @doc """
  Returns whether two text values are equal (case sensitive). In the case that they are, it will return the text as the match.
  """
  @expression_doc expression: "has_only_text(\"foo\", \"foo\")", result: true
  @expression_doc expression: "has_only_text(\"\", \"\")", result: true
  @expression_doc expression: "has_only_text(\"foo\", \"FOO\")", result: false
  def has_only_text(_ctx, expression_one, expression_two) do
    expression_one == expression_two
  end

  @doc """
  Tests whether `expression` matches the regex pattern

  Both text values are trimmed of surrounding whitespace and matching is case-insensitive.
  """
  @expression_doc expression: "has_pattern(\"Buy cheese please\", \"buy (\\w+)\")", result: true
  @expression_doc expression: "has_pattern(\"Sell cheese please\", \"buy (\\w+)\")", result: false
  def has_pattern(_ctx, expression, pattern) do
    with {:ok, regex} <- Regex.compile(String.trim(pattern), "i"),
         [[_first | _remainder]] <- Regex.scan(regex, String.trim(expression), capture: :all) do
      # Future match result: first
      true
    else
      _ -> false
    end
  end

  @doc """
  Tests whether `expression` contains a phone number.
  The optional country_code argument specifies the country to use for parsing.
  """
  @expression_doc expression: "has_phone(\"my number is +12067799294 thanks\")", result: true
  @expression_doc expression: "has_phone(\"my number is 2067799294 thanks\", \"US\")",
                  result: true
  @expression_doc expression: "has_phone(\"my number is 206 779 9294 thanks\", \"US\")",
                  result: true
  @expression_doc expression: "has_phone(\"my number is none of your business\", \"US\")",
                  result: false
  def has_phone(_ctx, expression) do
    letters_removed = Regex.replace(~r/[a-z]/i, expression, "")

    case ExPhoneNumber.parse(letters_removed, "") do
      # Future match result: ExPhoneNumber.format(pn, :es164)
      {:ok, _pn} -> true
      _ -> false
    end
  end

  def has_phone(_ctx, expression, country_code) do
    letters_removed = Regex.replace(~r/[a-z]/i, expression, "")

    case ExPhoneNumber.parse(letters_removed, country_code) do
      # Future match result: ExPhoneNumber.format(pn, :es164)
      {:ok, _pn} -> true
      _ -> false
    end
  end

  @doc """
  Tests whether phrase is contained in `expression`

  The words in the test phrase must appear in the same order with no other words in between.
  """
  @expression_doc expression: "has_phrase(\"the quick brown fox\", \"brown fox\")", result: true
  @expression_doc expression: "has_phrase(\"the quick brown fox\", \"quick fox\")", result: false
  @expression_doc expression: "has_phrase(\"the quick brown fox\", \"\")", result: true
  def has_phrase(_ctx, expression, phrase) do
    lower_expression = String.downcase(to_string(expression))
    lower_phrase = String.downcase(to_string(phrase))

    String.contains?(lower_expression, lower_phrase)
  end

  @doc """
  Tests whether there the `expression` has any characters in it
  """
  @expression_doc expression: "has_text(\"quick brown\")", result: true
  @expression_doc expression: "has_text(\"\")", result: false
  @expression_doc expression: "has_text(\" \n\")", result: false
  @expression_doc expression: "has_text(123)", result: true
  def has_text(_ctx, expression) do
    expression |> to_string() |> String.trim() != ""
  end

  @doc """
  Tests whether `expression` contains a time.
  """
  @expression_doc expression: "has_time(\"the time is 10:30\")",
                  result: %{"__value__" => true, "match" => ~T[10:30:00]}
  @expression_doc expression: "has_time(\"the time is 10:00 pm\")",
                  result: %{"__value__" => true, "match" => ~T[10:00:00]}
  @expression_doc expression: "has_time(\"the time is 10:30:45\")",
                  result: %{"__value__" => true, "match" => ~T[10:30:45]}
  @expression_doc expression: "has_time(\"there is no time here, just the number 25\")",
                  result: false
  def has_time(_ctx, expression) do
    if time = DateHelpers.extract_timeish(expression) do
      %{
        "__value__" => true,
        "match" => time
      }
    else
      false
    end
  end

  @doc """
  map over a list of items and apply the mapper function to every item, returning
  the result.
  """
  @expression_doc doc: "Map over the range of numbers, create a date in January for every number",
                  expression: "map(1..3, &date(2022, 1, &1))",
                  result: [~D[2022-01-01], ~D[2022-01-02], ~D[2022-01-03]]
  @expression_doc doc:
                    "Map over the range of numbers, multiple each by itself and return the result",
                  expression: "map(1..3, &(&1 * &1))",
                  result: [1, 4, 9]
  def map(_ctx, enumerable, mapper) do
    Enum.map(enumerable, mapper)
  end

  @doc """
  Return the division remainder of two integers.
  """
  @expression_doc expression: "rem(4, 2)",
                  result: 0
  @expression_doc expression: "rem(85, 3)",
                  result: 1
  def rem(_ctx, integer1, integer2) do
    rem(integer1, integer2)
  end

  @doc """
  Appends an item or a list of items to a given list.
  """
  @expression_doc expression: "append([\"A\", \"B\"], \"C\")",
                  result: ["A", "B", "C"]
  @expression_doc expression: "append([\"A\", \"B\"], [\"C\", \"B\"])",
                  result: ["A", "B", "C", "B"]
  def append(_ctx, list, payload) do
    enumerable = if is_list(payload), do: payload, else: [payload]

    Enum.concat(list, enumerable)
  end

  @doc """
  Deletes an element from a map by the given key.
  """
  @expression_doc expression: "delete(patient, \"gender\")",
                  context: %{"patient" => %{"gender" => "?", "age" => 32}},
                  result: %{"age" => 32}
  def delete(_ctx, map, key) do
    Map.delete(map, key)
  end
end
