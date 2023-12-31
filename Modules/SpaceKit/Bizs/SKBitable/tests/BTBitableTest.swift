//
//  BTBitableTest.swift
//  SKBitable_Tests-Unit-_Tests
//
//  Created by zengsenyuan on 2022/7/21.
//  


import XCTest
@testable import SKBitable
import RxSwift
import RxCocoa


func creatMockTableModel() throws -> BTTableModel {
    var tableModel = BTTableModel()
    let meta = try mockGetTableMeta()
    let value = try mockGetTableValue()
    tableModel.update(meta: meta, value: value, mode: .card, holdDataProvider: nil)
    return tableModel
}

struct TableModelTestError: Error {
    enum ErrorKind {
        case metaDeserializationFailure
        case valueDeserializationFailure
    }
    let errorKind: ErrorKind
    let detail: String

    init(kind: ErrorKind, detail: String) {
        self.errorKind = kind
        self.detail = detail
    }
}

func mockGetTableMeta() throws -> BTTableMeta {
    return MockJSONDataManager.getHandyJSONModelByParseData(filePath: "JSONDatas/tableJson/tableMeta")
}

func mockGetTableValue() throws -> BTTableValue {
    return  MockJSONDataManager.getHandyJSONModelByParseData(filePath: "JSONDatas/tableJson/tableData")
}
