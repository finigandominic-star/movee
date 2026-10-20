# Finds every email, UK phone number and UK post code in a text by looking for patterns.
# It can't tell whose they are; it lists what is really there, so the AI's answer can be checked against it.
class ContactDetailsFinder
  # check email address consists of sequence of:
  # 1 or more letters, digits or . _ % + -
  # an @
  # 1 or more letters, digits or, dots or dashes
  # a real dot
  # at least 2 letters
  EMAIL = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i # i: "ignore upper/lower case"

  # check phone consists of sequence of:
  # starts with: +44, an optional space, then an optional (0) with an optional space; a 0 at the start of a word
  # remaining digits: optional space or dash, one digit, maybe a separator then a digit (happening <= 9times)
  # ending: pattern must be a number
  PHONE = /(?:\+44\s?(?:\(0\)\s?)?|\b0)\d(?:[\s-]?\d){8,9}\b/

  # check post code consists of sequence of:
  # starts as a word with 1 or 2 letters
  # one digit
  # optionally one more letter or digit
  # any number of spaces (>= 0)
  # one digit
  # exactly 2 letter
  # end of word
  POST_CODE = /\b[A-Z]{1,2}\d[A-Z\d]?\s*\d[A-Z]{2}\b/i

  def initialize(text)
    # if nil is passed, the app won't crash because we always get an empty string returned
    @text = text.to_s
  end

  def emails
    # same email may appears several times in a letter -> remove duplicates with .uniq
    # downcase so that different ways of writting an email address are read as the same
    @text.scan(EMAIL).map(&:downcase).uniq
  end

  def phone_numbers
    # same phone may appear several times in a letter -> remove duplicates
    # squish several spaces into one and remove spaces at both ends
    @text.scan(PHONE).map(&:squish).uniq
  end

  def post_codes
    # same post code may appear several times in a letter -> remove duplicates
    # .self becahse post code doesn't need any text
    # also prep for tidying the PC the AI will give back
    @text.scan(POST_CODE).map { |post_code| self.class.format_post_code(post_code) }.uniq
  end

  # "sw1a2aa" → "SW1A 2AA": capitals, one space before the last three characters
  def self.format_post_code(post_code)
    post_code.upcase.delete(" ").insert(-4, " ")
  end
end
