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
