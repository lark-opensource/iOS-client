//
//  JiraPatternUtilTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by CJ on 2022/3/10.
//

import XCTest
@testable import SKFoundation

class JiraPatternUtilTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func testCheckIsJiraDomain() {
        var jiraUrl = "https://jira.bytedance.com/browse/SUITE-62740"
        var res = JiraPatternUtil.checkIsJiraDomain(url: jiraUrl)
        XCTAssertTrue(res)

        jiraUrl = "https://jira.bytedance.com/browse/DM-7059"
        res = JiraPatternUtil.checkIsJiraDomain(url: jiraUrl)
        XCTAssertTrue(res)

        jiraUrl = "https://bytedance.feishu.cn/docx/doxcn1nCKTXQKM6syx2DhUGriwe"
        res = JiraPatternUtil.checkIsJiraDomain(url: jiraUrl)
        XCTAssertFalse(res)

        jiraUrl = "https://jira.bytedance.com/projects/DM?selectedItem=com.atlassian.jira.jira-projects-plugin%3Arelease-page&status=unreleased"
        res = JiraPatternUtil.checkIsJiraDomain(url: jiraUrl)
        XCTAssertTrue(res)
    }

    func testCheckIsCommonJiraDomain() {
        var jiraUrl = "https://jira.bytedance.com/browse/SUITE-62740"
        var res = JiraPatternUtil.checkIsCommonJiraDomain(url: jiraUrl)
        XCTAssertFalse(res)

        jiraUrl = "https://bytedance.feishu.cn"
        res = JiraPatternUtil.checkIsCommonJiraDomain(url: jiraUrl)
        XCTAssertFalse(res)
    }
}
