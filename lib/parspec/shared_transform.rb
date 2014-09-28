module Parspec
  class SharedTransform < Parslet::Transform

    rule(status: simple(:status)) { status == 'OK' }
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
