//
//  LargeFileSaveSpec.swift
//  LarkAccountDevEEUnitTest
//
//  Created by Yiming Qu on 2020/12/31.
//

import XCTest
import ServerPB
@testable import LarkSecurityAudit

class LargeFileSaveSpec: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    func testPerformanceExample() throws {
        let service = PullPermissionService()
        var resp = ServerPB_Authorization_PullPermissionResponse()
        var permission = ServerPB_Authorization_OperatePermission()
        permission.permType = .fileAccessFolder
        var entity = ServerPB_Authorization_Entity()
        entity.id = UUID().uuidString
        entity.entityType = .user
        permission.object = entity
        permission.result = .allow
        resp.permissionData.operatePermissionData = Array(repeating: permission, count: 20000)
        resp.clearOld_p = true
        resp.permVersion = UUID().uuidString
        resp.permissionData.expireTime = Int64(Date().timeIntervalSinceNow)
        resp.permissionData.updateTime = Int64(Date().timeIntervalSinceNow)
        do {
           let data = try resp.serializedData()
            print("test serialized data len: \(data.count)")
        } catch {

        }

        // This is an example of a performance test case.
        if #available(iOS 13.0, *) {
            self.measure(metrics: [XCTClockMetric(), // to measure time
                                   XCTCPUMetric(), // to measure cpu cycles
                                   XCTStorageMetric(), // to measure storage consuming
                                   XCTMemoryMetric()]) { // to measeure RAM consuming

                service.mergeData(resp) // iPhone 11 耗时 3s
                service.cacheManager.writeCache(service.permissionResponse) // iPhone 11 耗时 5s
            }
        } else {
            // Fallback on earlier versions
        }
    }

}
