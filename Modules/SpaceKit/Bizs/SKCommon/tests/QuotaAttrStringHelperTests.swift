//
//  QuotaAttrStringHelperTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by ByteDance on 2022/9/20.
//

import XCTest
@testable import SKCommon

class QuotaAttrStringHelperTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testTipsWithAdmin() {
        let str = QuotaAttrStringHelper.tipsWithAdmin(template: "你的云文档存储空间为 {{num1}} GB，已使用 {{num2}} GB。你可以删除并清空不必要的文件以释放存储空间，或联系管理员（{{name}}）提高你的存储空间上限",
                                                      usage: 1024 * 1024 * 1024,
                                                      limited: 1024 * 1024 * 1024,
                                                      admins: [QuotaContact(uid: "111", name: "宇智波斑", enName: "are You Ok?", display_name: nil, isAdmin: true)], limitSize: 3)
        if DocsSDK.currentLanguage == .en_US {
            XCTAssertEqual(str.string, "你的云文档存储空间为 1.00 GB，已使用 1.00 GB。你可以删除并清空不必要的文件以释放存储空间，或联系管理员（@are You Ok?）提高你的存储空间上限")
        } else {
            XCTAssertEqual(str.string, "你的云文档存储空间为 1.00 GB，已使用 1.00 GB。你可以删除并清空不必要的文件以释放存储空间，或联系管理员（@宇智波斑）提高你的存储空间上限")
        }
    }
    
    func testTipsWithUrlAdmin() {
        let str = QuotaAttrStringHelper.tipsWithUrlAdmin(template: "你的云文档存储空间为 {{num1}} GB，已使用 {{num2}} GB 。你可以删除不必要的文件以释放存储空间，或查看 {{link}} 了解更多详情",
                                                         usage: 1024 * 1024 * 1024,
                                                         limited: 1024 * 1024 * 1024,
                                                         admins: QuotaUrl(title: "指导文档", url: "https://www.bytedance.com/"))
        XCTAssertEqual(str.string, "你的云文档存储空间为 1.00 GB，已使用 1.00 GB 。你可以删除不必要的文件以释放存储空间，或查看 指导文档 了解更多详情")
    }
    
    func testipsWithOriginAdmin() {
        let str = QuotaAttrStringHelper.tipsWithOriginAdmin(template: "你的云文档存储空间为 {{limited}} GB，已使用 {{usage}} GB。你可以删除并清空不必要的文件以释放存储空间，或联系管理员（{{admins}}）提高你的存储空间上限", usage: 1024 * 1024 * 1024,
                                                      limited: 1024 * 1024 * 1024,
                                                            admins: [QuotaContact(uid: "111", name: "宇智波斑", enName: "are You Ok?", display_name: nil, isAdmin: true)])
        if DocsSDK.currentLanguage == .en_US {
            XCTAssertEqual(str.string, "你的云文档存储空间为 1.00 GB，已使用 1.00 GB。你可以删除并清空不必要的文件以释放存储空间，或联系管理员（@are You Ok?）提高你的存储空间上限")
        } else {
            XCTAssertEqual(str.string, "你的云文档存储空间为 1.00 GB，已使用 1.00 GB。你可以删除并清空不必要的文件以释放存储空间，或联系管理员（@宇智波斑）提高你的存储空间上限")
        }
    }
    
    func testTipsWithOwner() {
        let str = QuotaAttrStringHelper.tipsWithOwner(template: "文档所有者 {{owner}} 的云文档存储空间为 {{limited}} GB，已使用 {{usage}} GB。请等待该用户释放一部分存储空间后，再继续操作",
                                                      usage: 1024 * 1024 * 1024,
                                                      limited: 1024 * 1024 * 1024, owner: QuotaContact(uid: "111", name: "宇智波斑", enName: "are You Ok?", display_name: nil, isAdmin: true))
        if DocsSDK.currentLanguage == .en_US {
            XCTAssertEqual(str.string, "文档所有者 @are You Ok? 的云文档存储空间为 1.00 GB，已使用 1.00 GB。请等待该用户释放一部分存储空间后，再继续操作")
        } else {
            XCTAssertEqual(str.string, "文档所有者 @宇智波斑 的云文档存储空间为 1.00 GB，已使用 1.00 GB。请等待该用户释放一部分存储空间后，再继续操作")
        }
    }
    
    
    func testTipsOfFileUploadWithOwner() {
        let testString = "你所在的企业当前使用{{APP_DISPLAY_NAME}}{{version}}，{{max_statement}}，如需升级版本，请联系客服"
        let str = QuotaAttrStringHelper.tipsOfFileUploadWithOwner(type: .bigFileUpload,
                                                                  template: testString,
                                                                  version: "标准版",
                                                                  maxSize: "1",
                                                                  verifiledSize: nil)
        XCTAssertEqual(str.string, "你所在的企业当前使用Docs标准版，You can upload files that are smaller than 1，如需升级版本，请联系客服")
    }
    
    func testTipsOfFileUploadWithOwnerVerifiledSize() {
        let testString = "你所在的企业当前使用{{APP_DISPLAY_NAME}}{{version}}，{{max_statement}}，如需升级版本，请联系客服"
        let str = QuotaAttrStringHelper.tipsOfFileUploadWithOwner(type: .bigFileUpload,
                                                                  template: testString,
                                                                  version: "标准版",
                                                                  maxSize: "1",
                                                                  verifiledSize: "123")
        print("typ:xxxxx,str.string:\(str.string)")
        XCTAssertNotEqual(str.string, "你所在的企业当前使用Docs标准版，You can upload files that are smaller than 1，如需升级版本，请联系客服")
    }
    
    func testTipsOfFileUploadWithAdmin() {
        let testString = "你所在的企业当前使用{{APP_DISPLAY_NAME}}{{version}}，{{max_statement}}，如需升级版本，请联系管理员（{{admin}}）"
        let testQuotaUploadInfo = QuotaUploadInfo(suiteType: .legacyFree,
                                                  suiteToQuota: SuiteToQuota(legacyFreeMaxSize: 1024,
                                                                             legacyEnterpriseMaxSize: 1024,
                                                                             standardMaxSize: 1024,
                                                                             certStandardMaxSize: 1024,
                                                                             businessMaxSize: 1024,
                                                                             enterpriseMaxSize: 1024),
                                                  admins: [Admin(uid: "xxx", name: "谭云鹏", enName: "Bob")], isAdmin: true)
        let context = TipsOfFileUploadContext(type: .bigFileUpload, template: testString, version: "标准版", maxSize: "1", verifiledSize: nil)
        let str = QuotaAttrStringHelper.tipsOfFileUploadWithAdmin(context: context,
                                                                  info: testQuotaUploadInfo)
        if DocsSDK.currentLanguage == .en_US {
            XCTAssertEqual(str.string, "你所在的企业当前使用Docs标准版，You can upload files that are smaller than 1，如需升级版本，请联系管理员（@Bob）")
        } else {
            XCTAssertEqual(str.string, "你所在的企业当前使用Docs标准版，You can upload files that are smaller than 1，如需升级版本，请联系管理员（@谭云鹏）")
        }
    }
    
}
