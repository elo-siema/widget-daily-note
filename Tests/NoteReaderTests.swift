import XCTest
@testable import DailyNote

final class MomentToSwiftTests: XCTestCase {
    func testDefaultFormat() {
        XCTAssertEqual(NoteReader.momentToSwift("YYYY-MM-DD"), "yyyy-MM-dd")
    }

    func testYearFormats() {
        XCTAssertEqual(NoteReader.momentToSwift("YYYY"), "yyyy")
        XCTAssertEqual(NoteReader.momentToSwift("YY"), "yy")
    }

    func testMonthFormats() {
        XCTAssertEqual(NoteReader.momentToSwift("MM"), "MM")
        XCTAssertEqual(NoteReader.momentToSwift("M"), "M")
        XCTAssertEqual(NoteReader.momentToSwift("MMM"), "MMM")
        XCTAssertEqual(NoteReader.momentToSwift("MMMM"), "MMMM")
    }

    func testDayFormats() {
        XCTAssertEqual(NoteReader.momentToSwift("DD"), "dd")
        XCTAssertEqual(NoteReader.momentToSwift("D"), "d")
    }

    func testDayOfWeek() {
        XCTAssertEqual(NoteReader.momentToSwift("dddd"), "EEEE")
        XCTAssertEqual(NoteReader.momentToSwift("ddd"), "EEE")
    }

    func testTimeFormats() {
        XCTAssertEqual(NoteReader.momentToSwift("HH:mm:ss"), "HH:mm:ss")
        XCTAssertEqual(NoteReader.momentToSwift("hh:mm A"), "hh:mm a")
        XCTAssertEqual(NoteReader.momentToSwift("H:m:s"), "H:m:s")
    }

    func testComplexFormat() {
        XCTAssertEqual(NoteReader.momentToSwift("YYYY/MM/DD"), "yyyy/MM/dd")
        XCTAssertEqual(NoteReader.momentToSwift("DD-MM-YYYY"), "dd-MM-yyyy")
        XCTAssertEqual(NoteReader.momentToSwift("YYYY.MM.DD"), "yyyy.MM.dd")
    }

    func testLiteralBrackets() {
        XCTAssertEqual(NoteReader.momentToSwift("[Day] DD"), "'Day' dd")
        XCTAssertEqual(NoteReader.momentToSwift("YYYY [year]"), "yyyy 'year'")
    }

    func testDayOfYear() {
        XCTAssertEqual(NoteReader.momentToSwift("DDDD"), "DDD")
    }

    func testProducesCorrectDate() {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = NoteReader.momentToSwift("YYYY-MM-DD")

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: Date())

        let result = fmt.string(from: Date())
        let parts = result.split(separator: "-")
        XCTAssertEqual(Int(parts[0]), components.year)
        XCTAssertEqual(Int(parts[1]), components.month)
        XCTAssertEqual(Int(parts[2]), components.day)
    }
}
