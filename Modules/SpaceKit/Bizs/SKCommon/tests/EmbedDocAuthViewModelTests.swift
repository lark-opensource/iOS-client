//
//  EmbedDocAuthViewModelTests.swift
//  SpaceDemoTests
//
//  Created by gupqingping on 2022/3/14.
//  Copyright © 2022 Bytedance. All rights reserved.
// swiftlint:disable force_try line_length


import XCTest
import OHHTTPStubs
@testable import SKCommon
@testable import SKUIKit
import RxSwift
import RxRelay
import SKFoundation
import SKInfra

class EmbedDocAuthViewModelTests: XCTestCase {

    var testObj: EmbedDocAuthViewModel!

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()

        let string = "https://applink.feishu.cn/client/docs/embed?chatAvatar=default-avatar_44ae0ca3-e140-494b-956f-78091e348435&type=22&chatId=7076065382133399572&chatDesc=&chatType=2&chatName=dingbing, chenweifeng, guoqingping&token=doxbcHKg6XobiaLoKTNW4qvOVpb&taskId=7076087668341325843&ownerId=7034431406486847508&ownerName=guoqingping"
        let url = try! URL.forceCreateURL(string: string)
        let queryDict = url.queryParameters
        let body = EmbedDocAuthControllerBody(queryDict: queryDict, fromVc: UIViewController())
        testObj = EmbedDocAuthViewModel(body: body)
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }


    func testEmbededDocAuthList() {
        print("start testEmbededDocAuthList")
        stub(condition: { [weak self] request in
            guard let self = self else { return false }
            let body = self.testObj.body
            var subpath = "?origin_object_type=\(body.docsType)"
            subpath = "\(subpath)&origin_object_token=\(body.objToken)"
            let path = OpenAPI.APIPath.embedDocAuthList(body.taskId) + subpath
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(path)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("embededDocAuthList.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        let expect = expectation(description: "test testEmbededDocAuthList")
        testObj.embededDocAuthList { result in
            switch result {
            case .Success:
                XCTAssertTrue(true)
            default:
                XCTFail("test testEmbededDocAuthList fail")
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        _ = testObj.hasPermissionCount
        _ = testObj.noPermissonCount
    }

    func testEmbededDocAuth() {
        print("start testEmbededDocAuth")

        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.embededDocAuth)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("embededDocAuth.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        let expect = expectation(description: "test EmbededDocAuth")

        let model = EmbedAuthModel(token: "docx_token2", type: 22, collaboratorId: "collaboratorId",
                                   collaboratorType: 0, collaboratorRole: .CanView)

        testObj.embededDocAuth(embedAuthModels: [model]) { result in
            switch result {
            case .Success:
                XCTAssertTrue(true)
            default:
                XCTFail("test EmbededDocAuth fail")
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testEmbededDocCancelAuth() {
        print("start EmbededDocCancelAuth")

        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.embededDocCancelAuth)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("embededDocCancelAuth.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        let expect = expectation(description: "test EmbededDocCancelAuth")

        let model = EmbedAuthModel(token: "docx_token2", type: 2, collaboratorId: "collaboratorId",
                                   collaboratorType: 0, collaboratorRole: .None)

        testObj.embededDocCancelAuth(embedAuthModels: [model]) { result in
            switch result {
            case .Success:
                XCTAssertTrue(true)
            default:
                XCTFail("test EmbededDocCancelAuth fail")
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testEmbedDocRecord() {
        print("start EmbedDocRecord")

        stub(condition: { [weak self] request in
            guard let self = self else { return false }
            let body = self.testObj.body
            let path = OpenAPI.APIPath.embedDocRecord(body.taskId)
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(path)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("embedDocRecord.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        let expect = expectation(description: "test EmbedDocRecord")
        let status = EmbedAuthRecodeStatus(token: "docx_token2", type: 22, permission: 0, permType: .container)
        testObj.embedDocRecord(status: [status]) { ret in
            XCTAssertTrue(ret)
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testEmbededDocUpdateCard() {
        print("start EmbededDocUpdateCard")

        stub(condition: { [weak self] request in
            guard let self = self else { return false }
            let body = self.testObj.body
            let path = OpenAPI.APIPath.embededDocUpdateCard(body.taskId)
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(path)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("embededDocUpdateCard.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        let expect = expectation(description: "test EmbededDocUpdateCard")
        testObj.embededDocUpdateCard { ret in
            XCTAssertTrue(ret)
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testGrantAllAccess() {
        print("start GrantAllAccess")
        
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.embededDocAuth)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("embededDocAuth.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        let expect = expectation(description: "test GrantAllAccess")

        let model = EmbedAuthModel(token: "docx_token2",
                                   type: 22,
                                   collaboratorId: "collaboratorId",
                                   collaboratorType: 0,
                                   collaboratorRole: .CanView)
        let embedDoc = EmbedDoc(objectToken: "docx_token2",
                                token: "token",
                                type: 22,
                                objectType: 22,
                                ownerId: "123",
                                ownerName: "123",
                                title: "123",
                                permType: .container,
                                chatHasPermission: false,
                                senderHasPermission: true,
                                senderHasSharePermission: true)
        testObj.embedDocAuthListModel.addEmbedDocs(nodes: [embedDoc])
        testObj.grantAllAccess(embedAuthModels: [model]) { result in
            switch result {
            case .Success:
                XCTAssertTrue(true)
            default:
                XCTFail("test GrantAllAccess fail")
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testRevokeAllAccess() {
        print("start RevokeAllAccess")
        
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.embededDocCancelAuth)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("embededDocCancelAuth.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        let expect = expectation(description: "test RevokeAllAccess")

        let model = EmbedAuthModel(token: "docx_token2",
                                   type: 2,
                                   collaboratorId: "collaboratorId",
                                   collaboratorType: 0,
                                   collaboratorRole: .None)
        let embedDoc = EmbedDoc(objectToken: "docx_token2",
                                token: "token",
                                type: 22,
                                objectType: 22,
                                ownerId: "123",
                                ownerName: "123",
                                title: "123",
                                permType: .container,
                                chatHasPermission: false,
                                senderHasPermission: true,
                                senderHasSharePermission: true)
        testObj.embedDocAuthListModel.addEmbedDocs(nodes: [embedDoc])
        testObj.revokeAllAccess(embedAuthModels: [model]) { result in
            switch result {
            case .Success:
                XCTAssertTrue(true)
            default:
                XCTFail("test RevokeAllAccess fail")
            }
            expect.fulfill()
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
}
