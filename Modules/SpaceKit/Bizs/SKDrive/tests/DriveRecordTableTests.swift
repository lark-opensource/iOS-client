//
//  DriveRecordTableTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/3/21.
//

import XCTest
@testable import SKDrive
import SKFoundation
import SKCommon
import SQLite

class DriveRecordTableTests: XCTestCase {
    typealias Record = DriveCache.Record
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        let dbFileURL = DriveFileMetaDB.dbFolderPath.appendingRelativePath("testDB")
        try? dbFileURL.removeItem()
    }
    
    func testInsertRecordsPerformance() {
        let rs = records()
        guard let sut = createSut() else {
            XCTAssertTrue(false)
            return
        }
        let start = CFAbsoluteTimeGetCurrent()
        do {
            try sut.setup()
            try sut.insert(records: rs)
            let cost = CFAbsoluteTimeGetCurrent() - start
            print("xxxxxx - cost: \(cost)")
            XCTAssertTrue(cost < 100000)
        } catch {
            XCTFail("setup table failed")
        }
    }

    private func records() -> Set<Record> {
        var records = Set<Record>()
        for i in 0...200000 {
            let token = "test token \(i)"
            let version = "version \(i)"
            let name = "filename\(i)"
            let type: DriveCacheType = (i % 2 == 0) ? .origin : .preview
            let size = i * 10
            let filetype = "type\(i)"
            let cacheType = DriveCacheService.CacheType.transient
            let r = Record(token: token,
                            version: version,
                            recordType: type,
                            originName: name,
                            originFileSize: UInt64(size),
                            fileType: filetype,
                            cacheType: cacheType)
            records.insert(r)
        }
        return records
    }
    private func createSut() -> DriveRecordTable? {
        DriveFileMetaDB.dbFolderPath.createDirectoryIfNeeded()
        let dbFileURL = DriveFileMetaDB.dbFolderPath.appendingRelativePath("testDB")
        let (_, connection) = Connection.getEncryptDatabase(unEncryptPath: nil,
                                                            encryptPath: dbFileURL,
                                                            readonly: false,
                                                            fromsource: .driveMeta)
        if let db = connection {
            return DriveRecordTable(connection: db)
        } else {
            return nil
        }
    }
}
