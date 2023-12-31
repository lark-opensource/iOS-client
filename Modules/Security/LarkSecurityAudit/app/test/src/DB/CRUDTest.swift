//
//  RepleacemeSpec.swift
//  BDevEEUnitTest
//
//  Created by 董朝 on 2019/2/14.
//

import XCTest
@testable import LarkSecurityAudit

extension Event {
    static let place: Event = {
        var evt = Event()
        evt.module = .moduleBitable
        evt.operation = .operationComment
        return evt
    }()
}
extension Database {
    func removeAllData() {
        var result = self.aduitLogTable.read(limit: 200)
        while !result.isEmpty {
            self.aduitLogTable.delete(result.map({ $0.id }))
            result = self.aduitLogTable.read(limit: 200)
        }
    }
}

class CRUDSpec: XCTestCase {

    lazy var dataBase: Database = Database()

    override func setUp() {
        super.setUp()
        self.dataBase.removeAllData()
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        self.dataBase.removeAllData()
    }

    func testInsert() {
        let expect = Array(repeating: Event.place.fillCommonFields(), count: 200)
        for evt in expect {
            dataBase.aduitLogTable.insert(event: evt)
        }
        let fromDb = dataBase.aduitLogTable.read(limit: 200).map({ $0.event })

        XCTAssertEqual(fromDb, expect)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
