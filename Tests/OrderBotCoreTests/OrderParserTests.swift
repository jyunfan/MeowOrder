import XCTest
@testable import OrderBotCore

final class OrderParserTests: XCTestCase {
    func testAddItemWithNote() {
        let parser = OrderParser()
        let result = parser.parse("我要一份雞腿飯，不要辣")

        XCTAssertEqual(result.intent, .addItem(itemName: "雞腿飯", quantity: 1, notes: ["不要辣"]))
    }

    func testModifyItem() {
        let parser = OrderParser()
        let result = parser.parse("雞腿飯改成兩份")

        XCTAssertEqual(result.intent, .modifyItem(itemName: "雞腿飯", quantity: 2, notes: []))
    }

    func testDeleteItem() {
        let parser = OrderParser()
        let result = parser.parse("貢丸湯不要了")

        XCTAssertEqual(result.intent, .deleteItem(itemName: "貢丸湯"))
    }

    func testFinishOrdering() {
        let parser = OrderParser()
        let result = parser.parse("好了")

        XCTAssertEqual(result.intent, .finishOrdering)
    }

    func testConfirmSubmitRequiresFinalConfirmation() {
        let parser = OrderParser()
        let applied = parser.apply(.confirmSubmit, to: Order())

        XCTAssertFalse(applied.order.isCompleted)
    }

    func testSimulatedOrderCanComplete() {
        let parser = OrderParser()
        var order = Order()

        order = parser.apply(parser.parse("我要一份雞腿飯").intent, to: order).order
        order = parser.apply(parser.parse("再加一碗貢丸湯").intent, to: order).order
        order = parser.apply(parser.parse("好了").intent, to: order).order
        order = parser.apply(parser.parse("確認").intent, to: order).order

        XCTAssertTrue(order.isCompleted)
        XCTAssertEqual(order.lines.count, 2)
    }
}
