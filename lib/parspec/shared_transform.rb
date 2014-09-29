module Parspec
  class SharedTransform < Parslet::Transform

    rule(status: simple(:status)) { status.to_s.upcase == 'OK' }
    rule(string: simple(:string)) do
      string.to_s.gsub(
          /\\[tnr"\/\\]/,
          "\\t" => "\t",
          "\\n" => "\n",
          "\\r" => "\r",
          '\\"' => '"',
          "\\\\" => "\\"
      )
    end

  end
end
