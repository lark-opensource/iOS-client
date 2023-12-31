//
//  DocsUrlUtilTest.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by 曾浩泓 on 2022/6/13.
//  

import Foundation
import XCTest
@testable import SKCommon
import SwiftyJSON
@testable import SKFoundation
import SKInfra

class DocsUrlUtilTest: XCTestCase {

    func testGetValueFromCurrentRevision() {
        let content = """
        revision:4f055fedeef95886e5edc2026635d7ef774547f0
        version:1.0.3.6575
        rn_folder:release_5.15
        pub date:2022-06-08 15:54:09
        is_slim:1
        channel:docs_channel
        release_version:5.15.0
        full_pkg_scm_version:1.0.3.6573
        full_pkg_url_home:http://lf26-cdn-tos.bytegecko.com/obj/ies.fe.gecko/b407b5b8c49cc6d6a76e4d9b39a31763
        full_pkg_url_oversea:http://lf19-geckocdn.bytegecko-i18n.com/obj/ies.fe.gecko.alisg/00742200a8e609c9e4f228a155494561
        """
        let version = DocsStringUtil.getValue(from: content, of: "version")
        XCTAssertTrue(version == "1.0.3.6575")
        let isSlim = DocsStringUtil.getValue(from: content, of: "is_slim")
        XCTAssertTrue(isSlim == "1")
        let releaseVersion = DocsStringUtil.getValue(from: content, of: "release_version")
        XCTAssertTrue(releaseVersion == "5.15.0")
        let fullPkgScmVersion = DocsStringUtil.getValue(from: content, of: "full_pkg_scm_version")
        XCTAssertTrue(fullPkgScmVersion == "1.0.3.6573")
        let urlHome = DocsStringUtil.getValue(from: content, of: "full_pkg_url_home")
        XCTAssertTrue(urlHome == "http://lf26-cdn-tos.bytegecko.com/obj/ies.fe.gecko/b407b5b8c49cc6d6a76e4d9b39a31763")
        let urlOversea = DocsStringUtil.getValue(from: content, of: "full_pkg_url_oversea")
        XCTAssertTrue(urlOversea == "http://lf19-geckocdn.bytegecko-i18n.com/obj/ies.fe.gecko.alisg/00742200a8e609c9e4f228a155494561")
    }

    func testGetVersionFromDifferentCurrentRevision() {
        let content1 = """
        revision:4f055fedeef95886e5edc2026635d7ef774547f0
        release_version:5.15.0
        version:1.0.3.6575
        rn_folder:release_5.15
        pub date:2022-06-08 15:54:09
        is_slim:1
        channel:docs_channel
        full_pkg_scm_version:1.0.3.6573
        full_pkg_url_home:http://lf26-cdn-tos.bytegecko.com/obj/ies.fe.gecko/b407b5b8c49cc6d6a76e4d9b39a31763
        full_pkg_url_oversea:http://lf19-geckocdn.bytegecko-i18n.com/obj/ies.fe.gecko.alisg/00742200a8e609c9e4f228a155494561
        """
        let version1 = DocsStringUtil.getValue(from: content1, of: "version")
        XCTAssertTrue(version1 == "1.0.3.6575")

        let content2 = """
        revision:4f055fedeef95886e5edc2026635d7ef774547f0
        version_xxx:5.15.0
        version:1.0.3.6575
        rn_folder:release_5.15
        pub date:2022-06-08 15:54:09
        is_slim:1
        channel:docs_channel
        full_pkg_scm_version:1.0.3.6573
        full_pkg_url_home:http://lf26-cdn-tos.bytegecko.com/obj/ies.fe.gecko/b407b5b8c49cc6d6a76e4d9b39a31763
        full_pkg_url_oversea:http://lf19-geckocdn.bytegecko-i18n.com/obj/ies.fe.gecko.alisg/00742200a8e609c9e4f228a155494561
        """
        let version2 = DocsStringUtil.getValue(from: content2, of: "version")
        XCTAssertTrue(version2 == "1.0.3.6575")
    }

    func testGetRenderPath() {
        var fileURL = URL(string: "docsource://bytedance.feishu.cn/wiki/wikcnwd9Sth0q1km4mpQOxffnWe?wiki_version=2&ccm_open_type=lark_docs_home_Recent")

        var result = DocsUrlUtil.getRenderPath(fileURL!, isAgentRepeatModuleEnable: false)
        XCTAssertEqual(result, "/wiki/wikcnwd9Sth0q1km4mpQOxffnWe?wiki_version=2&ccm_open_type=lark_docs_home_Recent")

        result = DocsUrlUtil.getRenderPath(fileURL!, isAgentRepeatModuleEnable: true)
        XCTAssertEqual(result, "/wiki/wikcnwd9Sth0q1km4mpQOxffnWe?wiki_version=2&ccm_open_type=lark_docs_home_Recent")

        fileURL = URL(string: "http://192.169.0.10:3001/wiki/wikcnwd9Sth0q1km4mpQOxffnWe?wiki_version=2")

        result = DocsUrlUtil.getRenderPath(fileURL!, isAgentRepeatModuleEnable: true)
        XCTAssertEqual(result, "/wiki/wikcnwd9Sth0q1km4mpQOxffnWe?wiki_version=2")
    }

    func testGetPath() {
        var result = DocsUrlUtil.getPath(type: .docX, token: "doxcn123456789", originURL: nil, isPhoenixPath: false)
        var expect = "/docx/doxcn123456789"
        XCTAssertEqual(result, expect)

        result = DocsUrlUtil.getPath(type: .docX, token: "doxcn123456789", originURL: nil, isPhoenixPath: true)
        expect = "/workspace/docx/doxcn123456789"
        XCTAssertEqual(result, expect)

        result = DocsUrlUtil.getPath(type: .bitable, token: "btlcn123456789", originURL: URL(string: "https://www.feishu.cn/share/base/btlcn123456789"), isPhoenixPath: false)
        expect = "/share/base/btlcn123456789"
        XCTAssertEqual(result, expect)

        result = DocsUrlUtil.getPath(type: .bitable, token: "btlcn123456789", originURL: URL(string: "https://www.feishu.cn/share/base/btlcn123456789"), isPhoenixPath: true)
        expect = "/workspace/share/base/btlcn123456789"
        XCTAssertEqual(result, expect)
    }

    // swiftlint:disable line_length
    func testGetTokenFromDriveImageUrl() {
        let previewUrl: String = "docsource://internal-api-space.feishu.cn/space/api/box/stream/download/preview/boxcn1234567890/?mount_node_token=abcdefghijklmn&mount_point=docx_image&width=300&height=284&type=image&scale=1&contentType=jpeg"
        let allUrl: String = "docsource://internal-api-space.feishu.cn/space/api/box/stream/download/all/boxcn1234567890/?mount_node_token=abcdefghijklmn&mount_point=docx_image&width=300&height=284&type=image&scale=1&contentType=jpeg"
        XCTAssert(DocsUrlUtil.isDriveImageUrl(previewUrl))
        XCTAssert(DocsUrlUtil.isDriveImageUrl(allUrl))
        let previewToken = DocsUrlUtil.getTokenFromDriveImageUrl(URL(string: previewUrl)) ?? ""
        let allToken = DocsUrlUtil.getTokenFromDriveImageUrl(URL(string: allUrl)) ?? ""
        let expectToken = "boxcn1234567890"
        XCTAssertEqual(expectToken, previewToken)
        XCTAssertEqual(expectToken, previewToken)
    }

    func testWikiSpaceURL() {
        let url = DocsUrlUtil.wikiSpaceURL(spaceID: "7001")?.absoluteString
        let expect = "https://" + DomainConfig.userDomainForDocs + "/wiki/space/7001"
        XCTAssertEqual(url, expect)
    }
    
    func testUserDomain() {
        DomainConfig.updateUserDomain(nil)
        _ = DomainConfig.userDomain
        let domain1 = "www.feishu.cn"
        DomainConfig.updateUserDomain(domain1)
        let domain2 = DomainConfig.userDomain
        XCTAssertEqual(domain1, domain2)
    }
    
    func testJumpDirection() {
        var direction = DocsUrlUtil.jumpDirectionfor("/space/bitable/")
        XCTAssertTrue(direction == .bitableHome)

        direction = DocsUrlUtil.jumpDirectionfor("/bitable/")
        XCTAssertTrue(direction == .bitableHome)
    }

    func testDisableDestinationPathsInSimpleMode() {
        var direction = DocsUrlUtil.disableDestinationPathsInSimpleMode
        XCTAssertTrue(direction["/bitable/"] == "bitable_home")
    }
    
    func testMinuteLatestName() {
        XCTAssertEqual(H5UrlPathConfig.latestName(of: .minutes), "unknow")
    }
    
    func testHandleRemoteComputeDomain() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.mobile.support_remote_compute", value: true)
        let dictionary: [String: Any] = [
            "data": [
                "overload_static_domain": ["a", "b"],
                "common": [
                    "domain": [
                        "helpcenter": "c"
                    ]
                ]
            ]
        ]
        DomainConfig.handleRemoteComputeDomain(result: JSON(dictionary))
        XCTAssertTrue(true)
    }
    
    func testGetDocsCurrentUrlInfo() {
        
        let docsMgBrandRegex = DomainConfig.ka.docsMgBrandRegex
        let docsMgGeoRegex = DomainConfig.ka.docsMgGeoRegex
        let docsMgApi = DomainConfig.ka.docsMgApi
        let docsMgFrontier = DomainConfig.ka.docsMgFrontier
        
        let pathPrefix = DomainConfig.pathPrefix
        
        DomainConfig.ka.docsMgBrandRegex = "\\.feishu\\.|\\.larksuite\\."
        DomainConfig.ka.docsMgGeoRegex = "\\.sg\\.|\\.us\\.|\\.jp\\."
        DomainConfig.ka.docsMgApi = [
            "feishu": ["sg": "internal-api-space-sg.feishu.cn", "us": "internal-api-space-us.feishu.cn", "jp": "internal-api-space-jp.feishu.cn", "": "internal-api-space.feishu.cn"],
            "larksuite": ["sg": "internal-api-space-sg.larksuite.cn", "us": "internal-api-space-us.larksuite.cn", "jp": "internal-api-space-jp.larksuite.cn", "": "internal-api-space.larksuite.com"],
        ]
        DomainConfig.ka.docsMgFrontier = [
            "feishu": ["sg": ["ccm16-frontier-sg.feishu.cn","ccm-frontier-sg.feishu.cn"],
                       "us": ["ccm16-frontier-us.feishu.cn","ccm-frontier-us.feishu.cn"],
                       "jp": ["ccm16-frontier-jp.feishu.cn","ccm-frontier-jp.feishu.cn"],
                       "": ["ccm-frontier.feishu.cn"]],
            "larksuite": ["sg": ["ccm16-frontier-sg.larksuite.com","ccm-frontier-sg.larksuite.com"],
                          "jp": ["ccm16-frontier-jp.larksuite.com","ccm-frontier-jp.larksuite.com"],
                          "": ["ccm-frontier.larksuite.com"]]
        ]
        
        let urlStr = "https://bytedance.us.feishu.cn/docx/doxcnJ0ZVLDIZjYNnapJM5rNdqg"
        let result = DocsUrlUtil.getDocsCurrentUrlInfo(URL(string: urlStr)!)
        
        
        XCTAssertEqual(result.brand, "feishu")
        XCTAssertEqual(result.unit, "us")
        XCTAssertEqual(result.docsApiPrefix, "https://internal-api-space-us.feishu.cn" + pathPrefix)
        XCTAssertEqual(result.frontierDomain, ["ccm16-frontier-us.feishu.cn","ccm-frontier-us.feishu.cn"])
        XCTAssertEqual(result.srcHost, "bytedance.us.feishu.cn")
        XCTAssertEqual(result.srcUrl, urlStr)
        

        let urlStr1 = "https://g2nzizjh5s.larksuite.com/docs/docusJ92UylFVLbTYJEs39q9e0f"
        let result1 = DocsUrlUtil.getDocsCurrentUrlInfo(URL(string: urlStr1)!)
        
        XCTAssertEqual(result1.brand, "larksuite")
        XCTAssertEqual(result1.unit, "")
        XCTAssertEqual(result1.docsApiPrefix, "https://internal-api-space.larksuite.com" + pathPrefix)
        XCTAssertEqual(result1.frontierDomain, ["ccm-frontier.larksuite.com"])
        XCTAssertEqual(result1.srcHost, "g2nzizjh5s.larksuite.com")
        XCTAssertEqual(result1.srcUrl, urlStr1)
        
        
        DomainConfig.ka.docsMgBrandRegex = docsMgBrandRegex
        DomainConfig.ka.docsMgGeoRegex = docsMgGeoRegex
        DomainConfig.ka.docsMgApi = docsMgApi
        DomainConfig.ka.docsMgFrontier = docsMgFrontier
        
    }

    func testHelperCenterDomain() {
        _ = DomainConfig.helperCenterDomain
        XCTAssert(true)
    }
}
