//
//  LarkResourceTest.swift
//  BDevEEUnitTest
//
//  Created by 董朝 on 2019/2/14.
//

import UIKit
import Foundation
import XCTest
import LKCommonsLogging
@testable import LarkResource

class LarkResourceTest: XCTestCase {

    static let logger: Log = Logger.log(LarkResourceTest.self, category: "TestResultLog")

    static var convertNumber = 0

    override func setUp() {
        super.setUp()
        LarkResourceTest.convertNumber = 0
        createMockIndexFile()
        ResourceManager.setup(indexTables: [])
    }

    override class func tearDown() {
        super.tearDown()
    }

    func testLoadIndexItems100() {
        let key = ResourceKey(baseKey: BaseKey(key: "1", extensionType: .image), env: Env())
        self.measure {
            if let indexPath = Bundle.main.path(
                forResource: "res-index100.plist",
                ofType: nil) {
                let index = ResourceIndexTable(
                   name: "res-index100",
                   indexFilePath: indexPath,
                   bundlePath: Bundle.main.bundlePath)!
                _ = index.resourceIndex(key: key)
            } else {
                XCTAssert(false, "not find index file")
            }
        }
    }

    func testLoadIndexItems500() {
        let key = ResourceKey(baseKey: BaseKey(key: "1", extensionType: .image), env: Env())
        self.measure {
            if let indexPath = Bundle.main.path(
                forResource: "res-index500.plist",
                ofType: nil) {
                let index = ResourceIndexTable(
                   name: "res-index500",
                   indexFilePath: indexPath,
                   bundlePath: Bundle.main.bundlePath)!
                _ = index.resourceIndex(key: key)
            } else {
                XCTAssert(false, "not find index file")
            }
        }

    }

    func testLoadIndexItems1000() {
        let key = ResourceKey(baseKey: BaseKey(key: "1", extensionType: .image), env: Env())
        self.measure {
            if let indexPath = Bundle.main.path(
                forResource: "res-index1000.plist",
                ofType: nil) {
                let index = ResourceIndexTable(
                   name: "res-index1000",
                   indexFilePath: indexPath,
                   bundlePath: Bundle.main.bundlePath)!
                _ = index.resourceIndex(key: key)
            } else {
                XCTAssert(false, "not find index file")
            }
        }
    }

    func testLoadIndexItems2000() {
        let key = ResourceKey(baseKey: BaseKey(key: "1", extensionType: .image), env: Env())
        self.measure {
            if let indexPath = Bundle.main.path(
                forResource: "res-index2000.plist",
                ofType: nil) {
                let index = ResourceIndexTable(
                   name: "res-index2000",
                   indexFilePath: indexPath,
                   bundlePath: Bundle.main.bundlePath)!
                _ = index.resourceIndex(key: key)
            } else {
                XCTAssert(false, "not find index file")
            }
        }

    }

    func testLoadIndexItemsLoad100() {
        self.measure {
            guard let indexPath = Bundle.main.path(
                forResource: "res-index100.plist",
                ofType: nil) else {
                XCTAssert(false)
                return
            }
            var propertyListFormat = PropertyListSerialization.PropertyListFormat.xml
            guard FileManager.default.fileExists(atPath: indexPath),
                let data = FileManager.default.contents(atPath: indexPath),
                (try? PropertyListSerialization.propertyList(
                    from: data,
                    options: .mutableContainersAndLeaves,
                    format: &propertyListFormat
                ) as? [String: AnyObject]) != nil else {
                    XCTAssert(false)
                    return
            }
        }
    }

    func testLoadIndexItemsLoad500() {
        self.measure {
            guard let indexPath = Bundle.main.path(
                forResource: "res-index500.plist",
                ofType: nil) else {
                XCTAssert(false)
                return
            }
            var propertyListFormat = PropertyListSerialization.PropertyListFormat.xml
            guard FileManager.default.fileExists(atPath: indexPath),
                let data = FileManager.default.contents(atPath: indexPath),
                (try? PropertyListSerialization.propertyList(
                    from: data,
                    options: .mutableContainersAndLeaves,
                    format: &propertyListFormat
                ) as? [String: AnyObject]) != nil else {
                    XCTAssert(false)
                    return
            }
        }
    }

    func testLoadIndexItemsLoad1000() {
        self.measure {
            guard let indexPath = Bundle.main.path(
                forResource: "res-index1000.plist",
                ofType: nil) else {
                XCTAssert(false)
                return
            }
            var propertyListFormat = PropertyListSerialization.PropertyListFormat.xml
            guard FileManager.default.fileExists(atPath: indexPath),
                let data = FileManager.default.contents(atPath: indexPath),
                (try? PropertyListSerialization.propertyList(
                    from: data,
                    options: .mutableContainersAndLeaves,
                    format: &propertyListFormat
                ) as? [String: AnyObject]) != nil else {
                    XCTAssert(false)
                    return
            }
        }
    }

    func testLoadIndexItemsLoad2000() {
        self.measure {
            guard let indexPath = Bundle.main.path(
                forResource: "res-index2000.plist",
                ofType: nil) else {
                XCTAssert(false)
                return
            }
            var propertyListFormat = PropertyListSerialization.PropertyListFormat.xml
            guard FileManager.default.fileExists(atPath: indexPath),
                let data = FileManager.default.contents(atPath: indexPath),
                (try? PropertyListSerialization.propertyList(
                    from: data,
                    options: .mutableContainersAndLeaves,
                    format: &propertyListFormat
                ) as? [String: AnyObject]) != nil else {
                    XCTAssert(false)
                    return
            }
        }
    }

    func testPerformanceExample() {
        let start = Date()
        let key = ResourceKey(baseKey: BaseKey(key: "test", extensionType: .image), env: Env())
        self.measure {
            let bundle = Bundle(for: LarkResourceTest.self)
            let index = ResourceIndexTable(
               name: "mock",
               indexFilePath: bundle.path(forResource: "mock", ofType: "plist")!,
               bundlePath: bundle.bundlePath)!
            _ = index.resourceIndex(key: key)
        }
        let end = Date()
        XCTAssert((end.timeIntervalSince1970 - start.timeIntervalSince1970) / 10 < 1)
        LarkResourceTest.logger.info("test performance all time \(end.timeIntervalSince1970 - start.timeIntervalSince1970) each \((end.timeIntervalSince1970 - start.timeIntervalSince1970) / 10)")
    }

    func testPerformanceExample2() {
        let key = ResourceKey(baseKey: BaseKey(key: "1", extensionType: .image), env: Env())
        createMockPerfIndexFile(number: 500, depth: 1)
        let start = Date()
        self.measure {
            let index = ResourceIndexTable(
               name: "mockPerf",
               indexFilePath: mockPerformanceIndexFilePath,
               bundlePath: NSTemporaryDirectory())!
            _ = index.resourceIndex(key: key)
        }
        let end = Date()
        LarkResourceTest.logger.info("test performance 2 time \((end.timeIntervalSince1970 - start.timeIntervalSince1970) / 10), 索引文件大小 = \(fileSize(in: mockPerformanceIndexFilePath))")

    }
    func testPerformanceExample3() {
        let key = ResourceKey(baseKey: BaseKey(key: "1", extensionType: .image), env: Env())
        createMockPerfIndexFile(number: 500, depth: 2)
        let start = Date()
        self.measure {
            let index = ResourceIndexTable(
               name: "mockPerf",
               indexFilePath: mockPerformanceIndexFilePath,
               bundlePath: NSTemporaryDirectory())!
            _ = index.resourceIndex(key: key)
        }
        let end = Date()
        LarkResourceTest.logger.info("test performance 2 time \((end.timeIntervalSince1970 - start.timeIntervalSince1970) / 10), 索引文件大小 = \(fileSize(in: mockPerformanceIndexFilePath))")
    }
    func testPerformanceExample4() {
        let key = ResourceKey(baseKey: BaseKey(key: "1", extensionType: .image), env: Env())
        createMockPerfIndexFile(number: 1000, depth: 1)
        let start = Date()
        self.measure {
            let index = ResourceIndexTable(
               name: "mockPerf",
               indexFilePath: mockPerformanceIndexFilePath,
               bundlePath: NSTemporaryDirectory())!
            _ = index.resourceIndex(key: key)
        }
        let end = Date()
        LarkResourceTest.logger.info("test performance 2 time \((end.timeIntervalSince1970 - start.timeIntervalSince1970) / 10), 索引文件大小 = \(fileSize(in: mockPerformanceIndexFilePath))")
    }
    func testPerformanceExample5() {
        let key = ResourceKey(baseKey: BaseKey(key: "1", extensionType: .image), env: Env())
        createMockPerfIndexFile(number: 1000, depth: 2)
        let start = Date()
        self.measure {
            let index = ResourceIndexTable(
               name: "mockPerf",
               indexFilePath: mockPerformanceIndexFilePath,
               bundlePath: NSTemporaryDirectory())!
            _ = index.resourceIndex(key: key)
        }
        let end = Date()
        LarkResourceTest.logger.info("test performance 2 time \((end.timeIntervalSince1970 - start.timeIntervalSince1970) / 10), 索引文件大小 = \(fileSize(in: mockPerformanceIndexFilePath))")
    }
    func testPerformanceExample6() {
        let key = ResourceKey(baseKey: BaseKey(key: "1", extensionType: .image), env: Env())
        createMockPerfIndexFile(number: 1000, depth: 3)
        let start = Date()
        self.measure {
            let index = ResourceIndexTable(
               name: "mockPerf",
               indexFilePath: mockPerformanceIndexFilePath,
               bundlePath: NSTemporaryDirectory())!
            _ = index.resourceIndex(key: key)
        }
        let end = Date()
        LarkResourceTest.logger.info("test performance 2 time \((end.timeIntervalSince1970 - start.timeIntervalSince1970) / 10), 索引文件大小 = \(fileSize(in: mockPerformanceIndexFilePath))")
    }

    func testPerformanceTendency() {
        LarkResourceTest.logger.info("testPerformance tendency 1")
        let key = ResourceKey(baseKey: BaseKey(key: "1", extensionType: .image), env: Env())
        createMockPerfIndexFile(number: 1, depth: 1)
        var start = Date()
        var index = ResourceIndexTable(
           name: "mockPerf",
           indexFilePath: mockPerformanceIndexFilePath,
           bundlePath: NSTemporaryDirectory())!
        _ = index.resourceIndex(key: key)
        var end = Date()
        LarkResourceTest.logger.info("资源个数 1 depth 1 time \(end.timeIntervalSince1970 - start.timeIntervalSince1970), 索引文件大小 = \(fileSize(in: mockPerformanceIndexFilePath))")
        createMockPerfIndexFile(number: 300, depth: 1)
        start = Date()
        index = ResourceIndexTable(
           name: "mockPerf",
           indexFilePath: mockPerformanceIndexFilePath,
           bundlePath: NSTemporaryDirectory())!
        _ = index.resourceIndex(key: key)
        end = Date()
        LarkResourceTest.logger.info("资源个数 300 depth 1 time \(end.timeIntervalSince1970 - start.timeIntervalSince1970), 索引文件大小 = \(fileSize(in: mockPerformanceIndexFilePath))")
        createMockPerfIndexFile(number: 600, depth: 1)
        start = Date()
        index = ResourceIndexTable(
           name: "mockPerf",
           indexFilePath: mockPerformanceIndexFilePath,
           bundlePath: NSTemporaryDirectory())!
        _ = index.resourceIndex(key: key)
        end = Date()
        LarkResourceTest.logger.info("资源个数 600 depth 1 time \(end.timeIntervalSince1970 - start.timeIntervalSince1970), 索引文件大小 = \(fileSize(in: mockPerformanceIndexFilePath))")
        createMockPerfIndexFile(number: 900, depth: 1)
        start = Date()
        index = ResourceIndexTable(
           name: "mockPerf",
           indexFilePath: mockPerformanceIndexFilePath,
           bundlePath: NSTemporaryDirectory())!
        _ = index.resourceIndex(key: key)
        end = Date()
        LarkResourceTest.logger.info("资源个数 900 depth 1 time \(end.timeIntervalSince1970 - start.timeIntervalSince1970), 索引文件大小 = \(fileSize(in: mockPerformanceIndexFilePath))")
        createMockPerfIndexFile(number: 1200, depth: 1)
        start = Date()
        index = ResourceIndexTable(
           name: "mockPerf",
           indexFilePath: mockPerformanceIndexFilePath,
           bundlePath: NSTemporaryDirectory())!
        _ = index.resourceIndex(key: key)
        end = Date()
        LarkResourceTest.logger.info("资源个数 1200 depth 1 time \(end.timeIntervalSince1970 - start.timeIntervalSince1970), 索引文件大小 = \(fileSize(in: mockPerformanceIndexFilePath))")
    }

    func testPerformanceTendency2() {
        LarkResourceTest.logger.info("testPerformance tendency 2")
        let key = ResourceKey(baseKey: BaseKey(key: "1", extensionType: .image), env: Env())
        createMockPerfIndexFile(number: 500, depth: 1)
        var start = Date()
        var index = ResourceIndexTable(
           name: "mockPerf",
           indexFilePath: mockPerformanceIndexFilePath,
           bundlePath: NSTemporaryDirectory())!
        _ = index.resourceIndex(key: key)
        var end = Date()
        LarkResourceTest.logger.info("资源个数 500 depth 1 time \(end.timeIntervalSince1970 - start.timeIntervalSince1970), 索引文件大小 = \(fileSize(in: mockPerformanceIndexFilePath))")
        createMockPerfIndexFile(number: 500, depth: 2)
        start = Date()
        index = ResourceIndexTable(
           name: "mockPerf",
           indexFilePath: mockPerformanceIndexFilePath,
           bundlePath: NSTemporaryDirectory())!
        _ = index.resourceIndex(key: key)
        end = Date()
        LarkResourceTest.logger.info("资源个数 500 depth 2 time \(end.timeIntervalSince1970 - start.timeIntervalSince1970), 索引文件大小 = \(fileSize(in: mockPerformanceIndexFilePath))")
        createMockPerfIndexFile(number: 500, depth: 3)
        start = Date()
        index = ResourceIndexTable(
           name: "mockPerf",
           indexFilePath: mockPerformanceIndexFilePath,
           bundlePath: NSTemporaryDirectory())!
        _ = index.resourceIndex(key: key)
        end = Date()
        LarkResourceTest.logger.info("资源个数 500 depth 3 time \(end.timeIntervalSince1970 - start.timeIntervalSince1970), 索引文件大小 = \(fileSize(in: mockPerformanceIndexFilePath))")
        createMockPerfIndexFile(number: 500, depth: 4)
        start = Date()
        index = ResourceIndexTable(
           name: "mockPerf",
           indexFilePath: mockPerformanceIndexFilePath,
           bundlePath: NSTemporaryDirectory())!
        _ = index.resourceIndex(key: key)
        end = Date()
        LarkResourceTest.logger.info("资源个数 500 depth 4 time \(end.timeIntervalSince1970 - start.timeIntervalSince1970), 索引文件大小 = \(fileSize(in: mockPerformanceIndexFilePath))")
    }

    func testResourceTextAPI() {
        if let indexPath = Bundle.main.path(
            forResource: "res-index.plist",
            ofType: nil) {
            let indexTable = ResourceIndexTable(
               name: "res-index",
               indexFilePath: indexPath,
               bundlePath: Bundle.main.bundlePath)!
            ResourceManager.setup(indexTables: [indexTable])
            DispatchQueue.main.async {
                let text: String? = ResourceManager.get(key: "Lark_Legacy_MessengerTab", type: "text")
                XCTAssert(text != nil)
            }
        }
    }

    func testResourceAPI() {
        let indexTable = ResourceIndexTable(
            name: "test",
            indexFilePath: mockIndexFilePath,
            bundlePath: Bundle.main.bundlePath)!
        let key = ResourceKey(baseKey: BaseKey(key: "test", extensionType: .image), env: Env())
        ResourceManager.setup(indexTables: [indexTable])

        DispatchQueue.main.async {
            let image: UIImage? = ResourceManager.get(key: "test", type: "image")
            XCTAssert(image != nil)
        }

        DispatchQueue.main.async {
            let result: ResourceResult<UIImage> = ResourceManager.resource(key: key)
            let image: UIImage? = ResourceManager.resource(key: key)
            XCTAssert((try? result.get()) != nil)
            XCTAssert(image != nil)
        }
        DispatchQueue.global().async {
            let result: ResourceResult<UIImage> = ResourceManager.resource(key: key)
            let image: UIImage? = ResourceManager.resource(key: key)
            XCTAssert((try? result.get()) != nil)
            XCTAssert(image != nil)
        }

        DispatchQueue.main.async {
            let result: MetaResourceResult = ResourceManager.metaResource(key: key)
            let resource: MetaResource? = ResourceManager.metaResource(key: key)
            XCTAssert((try? result.get()) != nil)
            XCTAssert(resource != nil)
        }
        DispatchQueue.global().async {
            let result: MetaResourceResult = ResourceManager.metaResource(key: key)
            let resource: MetaResource? = ResourceManager.metaResource(key: key)
            XCTAssert((try? result.get()) != nil)
            XCTAssert(resource != nil)
        }

        let expectation = self.expectation(description: "expectation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

    func testIndexTable() {
        let indexTable = ResourceIndexTable(
            name: "test",
            indexFilePath: mockIndexFilePath,
            bundlePath: NSTemporaryDirectory())!

        let expectation = self.expectation(description: "expectation")

        DispatchQueue.main.async {
            ResourceManager.setup(indexTables: [indexTable])
        }
        DispatchQueue.global().async {
            ResourceManager.setup(indexTables: [indexTable])
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssert(ResourceManager.shared.indexTables.count == 1)
            XCTAssert(ResourceManager.mainThreadShared.indexTables.count == 1)
            let indexTable2 = ResourceIndexTable(
                name: "test2",
                indexFilePath: mockIndexFilePath,
                bundlePath: NSTemporaryDirectory())!

            DispatchQueue.main.async {
                ResourceManager.insertOrUpdate(indexTables: [indexTable2])
            }
            DispatchQueue.global().async {
                ResourceManager.insertOrUpdate(indexTables: [indexTable2])
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                XCTAssert(ResourceManager.shared.indexTables.count == 2)
                XCTAssert(ResourceManager.mainThreadShared.indexTables.count == 2)

                DispatchQueue.main.async {
                    ResourceManager.remove(indexTableIDs: ["test"])
                }
                DispatchQueue.global().async {
                    ResourceManager.remove(indexTableIDs: ["test2"])
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                    XCTAssert(ResourceManager.shared.indexTables.count == 0)
//                    XCTAssert(ResourceManager.mainThreadShared.indexTables.count == 0)
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: 5)
    }

    func testOptions() {
        let indexTable = ResourceIndexTable(
            name: "test",
            indexFilePath: mockIndexFilePath,
            bundlePath: Bundle.main.bundlePath)!

        let _: ResourceResult<MockData> = ResourceManager.resource(
            key: ResourceKey(
                baseKey: BaseKey(
                    key: "test",
                    extensionType: .image),
                env: Env()
            ),
            options: [
            .extraIndexTables([indexTable])
        ])
        XCTAssert(LarkResourceTest.convertNumber == 1)

        let _: ResourceResult<MockData> = ResourceManager.resource(
            key: ResourceKey(
                baseKey: BaseKey(
                    key: "test",
                    extensionType: .image),
                env: Env()
            ),
            options: [
            .baseIndexTables([indexTable])
        ])
        XCTAssert(LarkResourceTest.convertNumber == 2)

        let _: ResourceResult<MockData> = ResourceManager.resource(
            key: ResourceKey(
                baseKey: BaseKey(
                    key: "test",
                    extensionType: .image),
                env: Env()
            ),
            options: [
                .baseIndexTables([indexTable]),
                .convertEntry([
                    ConvertKey(resourceType: MockData.self):
                    ConvertibleEntry<MockData> { (_: MetaResource, _: OptionsInfoSet) throws -> MockData in
                        LarkResourceTest.convertNumber -= 1
                        return MockData()
                    }
                ])
        ])
        XCTAssert(LarkResourceTest.convertNumber == 1)

        let url: URL? = ResourceManager.get(key: "sdfadsfs", type: "", options: [.baseIndexTables([indexTable])])
        XCTAssert(url != nil)
    }

    func testBaseKey() {
        let key1 = BaseKey(key: "test", extensionType: .image)
        XCTAssert(key1.fullKey == "test.image")
        let key2 = BaseKey(key: "test", extensionType: .audio)
        XCTAssert(key2.fullKey == "test.audio")
    }

    func testResourceKey() {
        let key1 = ResourceKey.image(key: "123")
        XCTAssert(key1.baseKey.fullKey == "123.image")
        let key2 = ResourceKey.color(key: "123")
        XCTAssert(key2.baseKey.fullKey == "123.color")
        let custom = ResourceKey.key("123", type: "custom")
        XCTAssert(custom.baseKey.fullKey == "123.custom")
    }

    func fileSize(in path: String) -> String {
        var fromByteCount: Int64 = 0

        if let attr = try? FileManager.default.attributesOfItem(atPath: path),
            let count = attr[FileAttributeKey.size] as? Int64 {
            fromByteCount = count
        }

        return ByteCountFormatter.string(
            fromByteCount: fromByteCount,
            countStyle: .binary)
    }
}

let mockIndexFilePath = NSTemporaryDirectory() + "/mock.plist"

func createMockIndexFile() {
    try? FileManager.default.removeItem(atPath: mockIndexFilePath)
    try? mockIndexData().write(to: URL(fileURLWithPath: mockIndexFilePath))
}

func mockIndexData() -> NSDictionary {
    return [
        "keys": [
            "test.image": [
                "bundle-path",
                "feed_top_bar@2x.png"
            ]
        ]
    ]
}

let mockPerformanceIndexFilePath = NSTemporaryDirectory() + "/mockPerf.plist"

func createMockPerfIndexFile(number: Int = 1, depth: Int = 1) {
    try? FileManager.default.removeItem(atPath: mockPerformanceIndexFilePath)
    try? mockPerformanceIndexData(number, depth)
        .write(to: URL(fileURLWithPath: mockPerformanceIndexFilePath))
}

func mockPerformanceIndexData(_ number: Int, _ depth: Int) -> NSDictionary {
    var values: [String: AnyObject] = [:]

    for n in 0..<number {
        let object = mockPerformanceData(current: 0, depth: depth)
        values["\(n).image"] = object
    }
    return [
        "keys": values
    ]
}

func mockPerformanceData(current: Int, depth: Int) -> NSArray {
    let array = NSMutableArray()
    if depth - current <= 1 {
        array.add("bundle-path")
        array.add("feed_top_bar")
    } else {
        array.add("theme")
        let dic: NSMutableDictionary = NSMutableDictionary()
        dic["$base"] = mockPerformanceData(current: current + 1, depth: depth)
        dic["light"] = mockPerformanceData(current: current + 1, depth: depth)
        dic["dark"] = mockPerformanceData(current: current + 1, depth: depth)
        array.add(dic)
    }
    return array
}

struct MockData: ResourceConvertible {
    static var convertEntry: ConvertibleEntryProtocol = ConvertibleEntry<MockData> { (_: MetaResource, _: OptionsInfoSet) throws -> MockData in
        LarkResourceTest.convertNumber += 1
        return MockData()
    }
}
