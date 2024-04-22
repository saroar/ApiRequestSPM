
import Foundation


import Foundation
import NIOCore

protocol URLEncodedFormConvertible {
    func toURLEncodedFormData() -> String
}

extension Encodable {
    func toURLEncodedFormData() -> String? {
        (self as? URLEncodedFormConvertible)?.toURLEncodedFormData()
    }
}


extension Encodable {
    /// Converts an `Encodable` instance to a `ByteBuffer`.
    /// - Parameters:
    ///   - allocator: The `ByteBufferAllocator` used to allocate the `ByteBuffer`.
    /// - Returns: A `ByteBuffer` containing the JSON-encoded representation of the instance.
    /// - Throws: An error if the instance could not be encoded.
    public func toByteBuffer(allocator: ByteBufferAllocator = ByteBufferAllocator()) throws -> ByteBuffer {
        let jsonData = try JSONEncoder().encode(self)
        var buffer = allocator.buffer(capacity: jsonData.count)
        buffer.writeBytes(jsonData)
        return buffer
    }
}

extension Encodable {

    func toJSONString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            } else {
                return "Error converting JSON data to string"
            }
        } catch {
            return "Error encoding object to JSON: \(error)"
        }
    }
}

extension Date {
    /// Converts the date to a string formatted as "dd/MM/yyyy".
    ///
    /// This method utilizes `DateFormatter` internally to convert the `Date` instance into a string
    /// representation following the "day/month/year" format. It's particularly useful for creating
    /// user-friendly date strings for UI display or API requests.
    ///
    /// - Returns: A `String` representing the formatted date.
    func toFormattedString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") // Add this line
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: self)
    }


    /// Converts the Date instance to DateComponents.
    ///
    /// - Parameters:
    ///   - calendar: The calendar to use for the conversion. Defaults to the current calendar.
    /// - Returns: DateComponents containing the year, month, and day of the Date instance.
    func toDateComponents(calendar: Calendar = .current) -> DateComponents {
        return calendar.dateComponents([.year, .month, .day], from: self)
    }

    func fromDateDdMMyyyy() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.string(from: self)
    }
}

extension Date {
    /// Adds a specified number of days to the date.
    ///
    /// This method calculates a new `Date` by adding the given number of days to the current date instance.
    /// It leverages the current calendar to perform the date arithmetic.
    ///
    /// - Parameter days: The number of days to add to the date. Can be negative to subtract days.
    /// - Returns: A new `Date` instance with the added days, or `nil` if the operation could not be performed.
    func addingDays(_ days: Int) -> Date? {
        return Calendar.current.date(byAdding: .day, value: days, to: self)
    }
    
    /// Adds a specified number of years to the date.
    ///
    /// This method calculates a new `Date` by adding the given number of years to the current date instance.
    /// It leverages the current calendar to perform the date arithmetic.
    ///
    /// - Parameter years: The number of years to add to the date. Can be negative to subtract years.
    /// - Returns: A new `Date` instance with the added years, or `nil` if the operation could not be performed.
    func addingYears(_ years: Int) -> Date? {
        return Calendar.current.date(byAdding: .year, value: years, to: self)
    }
}

extension Date {
    func calculateStartDate() -> Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        // Determine if earliestDate is the last day of its month
        let isLastDayOfMonth = calendar.isDate(self, equalTo: calendar.endOfMonth(for: self), toGranularity: .day)

        if calendar.isDateInCurrentMonth(self) {

            if isLastDayOfMonth {
                return calendar.startOfFutureMonthFromLastDayCurrentMonth(for: self)
            }

            return calendar.date(byAdding: .day, value: 1, to: self)!

        } else {
            return calendar.startOfMonth(for: self)
        }
    }
}

extension Calendar {

    func isDateInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let currentDate = Date()

        let currentComponents = calendar.dateComponents([.year, .month], from: currentDate)
        let dateComponents = calendar.dateComponents([.year, .month], from: date)

        return currentComponents.year == dateComponents.year && currentComponents.month == dateComponents.month
    }

    func endOfMonth(for date: Date) -> Date {
        var components = dateComponents([.year, .month], from: date)
        components.month! += 1
        components.day = 0 // Move to the last day of the previous month, which is the end of the current month
        return self.date(from: components)!
    }


    func startOfMonth(for date: Date) -> Date {
        var components = dateComponents([.year, .month], from: date)
        components.day = 1 // Set to the first day of the month
        return self.date(from: components)!
    }

    func startOfFutureMonthFromLastDayCurrentMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: date)
        let components = dateComponents([.year, .month], from: nextMonthDate!)
        return self.date(from: components)!
    }
}
// logger.error("\(#line) \(#function) gaurd becomde issue")

//// Start measuring time
//let startTime = Date()
//let formatter = DateFormatter()
//formatter.dateFormat = "dd/MM/yyyy"
//
//// Adjusting for the test cases based on your requirements
//let earliestDate_current_month = formatter.date(from: "10/04/2024")! // Should give 11/04/2024
//let calculatedStartDate_c_m = earliestDate_current_month.calculateStartDate()
//print("Calculated Start Date c m:", formatter.string(from: calculatedStartDate_c_m))
//// Calculate the elapsed time
//let elapsedTime = Date().timeIntervalSince(startTime)
//print("Elapsed time: \(elapsedTime) seconds")
//
//let earliestDate_current_month_end = formatter.date(from: "30/04/2024")! // Should give 01/05/2024 as it's the end of the month
//let calculatedStartDate_c_m_e = earliestDate_current_month_end.calculateStartDate()
//print("Calculated Start Date c m e:", formatter.string(from: calculatedStartDate_c_m_e))
//
//let earliestDate_next_month = formatter.date(from: "15/06/2024")! // Should give 01/06/2024 as it's a future month
//let calculatedStartDate_n_m = earliestDate_next_month.calculateStartDate()
//print("Calculated Start Date n m:", formatter.string(from: calculatedStartDate_n_m))
//
//let earliestDate_future_month = formatter.date(from: "15/09/2024")! // Also a future month, should give 01/07/2024
//let calculatedStartDate_future_m = earliestDate_future_month.calculateStartDate()
//print("Calculated Start Date future m:", formatter.string(from: calculatedStartDate_future_m))
//
//Calculated Start Date c m: 11/04/2024
//Elapsed time: 0.034432053565979004 seconds
//Calculated Start Date c m e: 01/05/2024
//Calculated Start Date n m: 01/06/2024
//Calculated Start Date future m: 01/09/2024
