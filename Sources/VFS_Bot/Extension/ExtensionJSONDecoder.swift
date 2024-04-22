import Foundation

extension JSONDecoder {
    static func wiht(dateFormatter: DateFormatter) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }

    enum DateDecodingStrategyy {
        case multipleFormatters([DateFormatter])
    }

    func setDateDecodingStrategy(_ strategy: DateDecodingStrategyy) {
        switch strategy {
        case .multipleFormatters(let formatters):
            self.dateDecodingStrategy = .custom { decoder -> Date in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                for formatter in formatters {
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
            }
        }
    }
}


extension JSONEncoder {
    // Factory method to create a JSONEncoder with a specific date formatter
    static func with(dateFormatter: DateFormatter) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        return encoder
    }

    // Enhanced enum to handle multiple date encoding strategies
    enum DateEncodingStrategyy {
        case multipleFormatters([DateFormatter])
    }

    // Method to set the date encoding strategy on an encoder instance
    func setDateEncodingStrategy(_ strategy: DateEncodingStrategyy) {
        switch strategy {
        case .multipleFormatters(let formatters):
            self.dateEncodingStrategy = .custom { date, encoder throws in
                var dateString: String?
                for formatter in formatters {
                    let formattedDate = formatter.string(from: date)
                    dateString = formattedDate

                }
                guard let validDateString = dateString else {
                    throw EncodingError.invalidValue(date, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "None of the formatters could format the date."))
                }
                var container = encoder.singleValueContainer()
                try container.encode(validDateString)
            }
        }
    }
}
