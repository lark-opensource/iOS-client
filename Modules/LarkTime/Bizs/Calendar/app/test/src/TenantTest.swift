//
//  TenantTest.swift
//  CalendarDemo
//
//  Created by zhouyuan on 2019/5/9.
//

import XCTest

@testable import Calendar
@testable import CalendarFoundation
class TenantTest: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testCustomer() {
        let currentTenantId = Tenant.customerTenantId
        let tenant = Tenant(currentTenantId: currentTenantId)
        XCTAssertTrue(tenant.isCustomerTenant())

        XCTAssertFalse(tenant.isExternalTenant(isCrossTenant: false))
        XCTAssertFalse(tenant.isExternalTenant(isCrossTenant: true))
        XCTAssertFalse(tenant.isExternalTenant(tenantId: "2", isCrossTenant: false))
        XCTAssertFalse(tenant.isExternalTenant(tenantId: "2", isCrossTenant: true))
        XCTAssertFalse(tenant.isExternalTenant(tenantId: currentTenantId, isCrossTenant: true))
        XCTAssertFalse(tenant.isExternalTenant(tenantId: currentTenantId, isCrossTenant: false))

        XCTAssertFalse(tenant.isCurrentTenant(isCrossTenant: false))
        XCTAssertFalse(tenant.isCurrentTenant(isCrossTenant: true))
        XCTAssertFalse(tenant.isCurrentTenant(tenantId: "2", isCrossTenant: false))
        XCTAssertFalse(tenant.isCurrentTenant(tenantId: "2", isCrossTenant: true))
        XCTAssertFalse(tenant.isCurrentTenant(tenantId: currentTenantId, isCrossTenant: true))
        XCTAssertFalse(tenant.isCurrentTenant(tenantId: currentTenantId, isCrossTenant: false))
        XCTAssertFalse(tenant.isExternalTenant(tenantId: "-1", isCrossTenant: "1" == "-1"))
        XCTAssertFalse(tenant.isCurrentTenant(tenantId: "-1", isCrossTenant: "1" == "-1"))
    }

    func testBTenant() {
        let currentTenantId = "1"
        let tenant = Tenant(currentTenantId: currentTenantId)
        XCTAssertFalse(tenant.isCustomerTenant())

        XCTAssertFalse(tenant.isExternalTenant(isCrossTenant: false))
        XCTAssertTrue(tenant.isExternalTenant(isCrossTenant: true))
        XCTAssertTrue(tenant.isExternalTenant(tenantId: "2", isCrossTenant: false))
        XCTAssertTrue(tenant.isExternalTenant(tenantId: "2", isCrossTenant: true))
        XCTAssertTrue(tenant.isExternalTenant(tenantId: currentTenantId, isCrossTenant: true))
        XCTAssertFalse(tenant.isExternalTenant(tenantId: currentTenantId, isCrossTenant: false))

        XCTAssertTrue(tenant.isCurrentTenant(isCrossTenant: false))
        XCTAssertFalse(tenant.isCurrentTenant(isCrossTenant: true))
        XCTAssertFalse(tenant.isCurrentTenant(tenantId: "2", isCrossTenant: false))
        XCTAssertFalse(tenant.isCurrentTenant(tenantId: "2", isCrossTenant: true))
        XCTAssertFalse(tenant.isCurrentTenant(tenantId: currentTenantId, isCrossTenant: true))
        XCTAssertTrue(tenant.isCurrentTenant(tenantId: currentTenantId, isCrossTenant: false))

        XCTAssertFalse(tenant.isExternalTenant(tenantId: "-1", isCrossTenant: "1" == "-1"))
        XCTAssertTrue(tenant.isCurrentTenant(tenantId: "-1", isCrossTenant: "1" == "-1"))
    }
}
