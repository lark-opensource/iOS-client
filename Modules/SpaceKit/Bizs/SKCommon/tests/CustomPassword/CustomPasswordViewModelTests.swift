//
//  CustomPasswordViewModelTests.swift
//  SKCommon-Unit-Tests
//
//  Created by Weston Wu on 2023/12/7.
//

import Foundation
import SKInfra
import SKFoundation
@testable import SKCommon
import XCTest
import RxSwift
import OHHTTPStubs

class CustomPasswordViewModelTests: XCTestCase {
    func testRequirementModel() {
        let expression = try! NSRegularExpression(pattern: "a", options: [])
        let requirement = PasswordRequirement(matchExpressions: [expression], notMatchExpressions: [], message: "test")
        let model = CustomPasswordViewModel.RequirementModel(requirement: requirement)
        XCTAssertEqual(model.message, requirement.message)
        XCTAssertEqual(model.state, .notify)
        // state + edit
        // notify + edit/!match -> notify
        model.receive(input: .edit(password: "b"))
        XCTAssertEqual(model.state, .notify)

        // notify + edit/match -> pass
        model.receive(input: .edit(password: "a"))
        XCTAssertEqual(model.state, .pass)

        // pass + edit/match -> pass
        model.receive(input: .edit(password: "aa"))
        XCTAssertEqual(model.state, .pass)

        // pass + edit/!match -> notify
        model.receive(input: .edit(password: "bb"))
        XCTAssertEqual(model.state, .notify)

        model.receive(input: .commit(password: "bb"))
        XCTAssertEqual(model.state, .warning)
        // warning + edit/!match -> warning
        model.receive(input: .edit(password: "cc"))
        XCTAssertEqual(model.state, .warning)

        // warning + edit/match -> warning
        model.receive(input: .edit(password: "aa"))
        XCTAssertEqual(model.state, .pass)

        // state + commit
        model.receive(input: .reset)
        XCTAssertEqual(model.state, .notify)
        // notify + commit/!match -> warning
        model.receive(input: .commit(password: "bb"))
        XCTAssertEqual(model.state, .warning)

        model.receive(input: .reset)
        XCTAssertEqual(model.state, .notify)
        // notify + commit/match -> pass
        model.receive(input: .commit(password: "aa"))
        XCTAssertEqual(model.state, .pass)

        // pass + commit/match -> pass
        model.receive(input: .commit(password: "aaa"))
        XCTAssertEqual(model.state, .pass)

        // pass + commit/match -> warning
        model.receive(input: .commit(password: "bb"))
        XCTAssertEqual(model.state, .warning)

        // warning + commit/!match -> warning
        model.receive(input: .commit(password: "ccc"))
        XCTAssertEqual(model.state, .warning)

        // warning + commit/match -> pass
        model.receive(input: .commit(password: "aa"))
        XCTAssertEqual(model.state, .pass)

        // state + reset
        model.receive(input: .reset)
        XCTAssertEqual(model.state, .notify)
        // notify + reset -> notify
        model.receive(input: .reset)
        XCTAssertEqual(model.state, .notify)

        model.receive(input: .edit(password: "aa"))
        XCTAssertEqual(model.state, .pass)
        // pass + reset -> notify
        model.receive(input: .reset)
        XCTAssertEqual(model.state, .notify)

        model.receive(input: .commit(password: "cc"))
        XCTAssertEqual(model.state, .warning)
        // warning + reset -> notify
        model.receive(input: .reset)
        XCTAssertEqual(model.state, .notify)
    }

    func testForbiddenModel() {
        let expression = try! NSRegularExpression(pattern: "a", options: [])
        let requirement = PasswordRequirement(matchExpressions: [expression], notMatchExpressions: [], message: "test")
        let model = CustomPasswordViewModel.ForbiddenModel(requirement: requirement)
        XCTAssertEqual(model.message, requirement.message)
        XCTAssertEqual(model.state, .pass)

        model.receive(input: .edit(password: "a"))
        XCTAssertEqual(model.state, .warning)

        model.receive(input: .commit(password: "a"))
        XCTAssertEqual(model.state, .warning)

        model.receive(input: .edit(password: "b"))
        XCTAssertEqual(model.state, .pass)

        model.receive(input: .commit(password: "b"))
        XCTAssertEqual(model.state, .pass)

        model.receive(input: .edit(password: ""))
        XCTAssertEqual(model.state, .pass)

        model.receive(input: .commit(password: ""))
        XCTAssertEqual(model.state, .pass)

        model.receive(input: .reset)
        XCTAssertEqual(model.state, .pass)
        // 因为下面在用 popLast，这里的顺序要反过来
        var visableExpectValue = Array([false, true, false].reversed())
        let expect = expectation(description: "visable")
        expect.expectedFulfillmentCount = 3
        let bag = DisposeBag()
        model.visableDriver.drive(onNext: { visable in
            if let expectValue = visableExpectValue.popLast() {
                XCTAssertEqual(visable, expectValue)
            }
            expect.fulfill()
        }).disposed(by: bag)
        model.receive(input: .edit(password: "a"))
        model.receive(input: .commit(password: "b"))
        waitForExpectations(timeout: 1)
    }

    func testLevelModel() {
        var visableExpectValue = Array([
            false,
            true,
            true,
            true,
            true,
            false,
            false
        ].reversed())
        var levelExpectValue: [PasswordLevelRule.Level] = Array([
            .unknown,
            .weak(message: "weak"),
            .middle(message: "middle"),
            .strong(message: "strong"),
            .weak(message: "weak2"),
            .unknown,
            .unknown
        ].reversed())
        let strong = PasswordRequirement(matchExpressions: [try! NSRegularExpression(pattern: "a", options: [])],
                                         notMatchExpressions: [],
                                         message: "strong")
        let middle = PasswordRequirement(matchExpressions: [try! NSRegularExpression(pattern: "b", options: [])],
                                         notMatchExpressions: [],
                                         message: "middle")
        let weak = PasswordRequirement(matchExpressions: [try! NSRegularExpression(pattern: "c", options: [])],
                                       notMatchExpressions: [],
                                       message: "weak")
        let weak2 = PasswordRequirement(matchExpressions: [try! NSRegularExpression(pattern: "d", options: [])],
                                        notMatchExpressions: [],
                                        message: "weak2")
        let rule = PasswordLevelRule(strongRequirements: [strong],
                                     middleRequirements: [middle],
                                     weakRequirements: [weak, weak2])
        let model = CustomPasswordViewModel.LevelModel(levelRule: rule)
        let bag = DisposeBag()
        
        let visableExpect = expectation(description: "visableExpect")
        visableExpect.expectedFulfillmentCount = 7
        let levelExpect = expectation(description: "levelExpect")
        levelExpect.expectedFulfillmentCount = 7

        model.visableDriver.drive(onNext: { visable in
            if let expectValue = visableExpectValue.popLast() {
                XCTAssertEqual(visable, expectValue)
            }
            visableExpect.fulfill()
        }).disposed(by: bag)

        model.levelDriver.drive(onNext: { level in
            if let expectValue = levelExpectValue.popLast() {
                XCTAssertEqual(level, expectValue)
            }
            levelExpect.fulfill()
        }).disposed(by: bag)
        model.receive(input: .edit(password: "c"))
        model.receive(input: .edit(password: "b"))
        model.receive(input: .edit(password: "a"))
        model.receive(input: .edit(password: "d"))
        model.receive(input: .edit(password: "e"))
        model.receive(input: .edit(password: ""))
        waitForExpectations(timeout: 1)
    }

    func testVMGetSubModels() {
        let match = PasswordRequirement(matchExpressions: [try! NSRegularExpression(pattern: "a", options: [])],
                                        notMatchExpressions: [],
                                        message: "match")
        let notMatch = PasswordRequirement(matchExpressions: [try! NSRegularExpression(pattern: "b", options: [])],
                                        notMatchExpressions: [],
                                        message: "notMatch")
        let ruleSet = PasswordRuleSet(matchRequirements: [match],
                                      notMatchRequirements: [notMatch],
                                      passwordLevelRule: .empty)
        let viewModel = CustomPasswordViewModel(objToken: "mock", objType: .docX, ruleSet: ruleSet)
        XCTAssertEqual(viewModel.objToken, "mock")
        XCTAssertEqual(viewModel.objType, .docX)
        let subModels = viewModel.getSubModels()
        XCTAssertEqual(subModels.count, 2)
    }

    func testVMInput() {
        let match = PasswordRequirement(matchExpressions: [try! NSRegularExpression(pattern: "a", options: [])],
                                        notMatchExpressions: [],
                                        message: "match")
        let notMatch = PasswordRequirement(matchExpressions: [try! NSRegularExpression(pattern: "b", options: [])],
                                        notMatchExpressions: [],
                                        message: "notMatch")
        let ruleSet = PasswordRuleSet(matchRequirements: [match],
                                      notMatchRequirements: [notMatch],
                                      passwordLevelRule: .empty)
        let viewModel = CustomPasswordViewModel(objToken: "", objType: .docX, ruleSet: ruleSet)
        XCTAssertFalse(viewModel.pass)
        XCTAssertFalse(viewModel.showingWarning)

        viewModel.edit(password: "a")
        XCTAssertTrue(viewModel.pass)
        XCTAssertFalse(viewModel.showingWarning)

        viewModel.edit(password: "c")
        XCTAssertFalse(viewModel.pass)
        XCTAssertFalse(viewModel.showingWarning)

        viewModel.edit(password: "ab")
        XCTAssertFalse(viewModel.pass)
        XCTAssertTrue(viewModel.showingWarning)

        viewModel.reset()
        XCTAssertFalse(viewModel.pass)
        XCTAssertFalse(viewModel.showingWarning)

        viewModel.commit(password: "c")
        XCTAssertFalse(viewModel.pass)
        XCTAssertTrue(viewModel.showingWarning)
    }

    func testSave() {
        let disposeBag = DisposeBag()
        let match = PasswordRequirement(matchExpressions: [try! NSRegularExpression(pattern: "a", options: [])],
                                        notMatchExpressions: [],
                                        message: "match")
        let notMatch = PasswordRequirement(matchExpressions: [try! NSRegularExpression(pattern: "b", options: [])],
                                        notMatchExpressions: [],
                                        message: "notMatch")
        let ruleSet = PasswordRuleSet(matchRequirements: [match],
                                      notMatchRequirements: [notMatch],
                                      passwordLevelRule: .empty)
        let viewModel = CustomPasswordViewModel(objToken: "mock", objType: .docX, ruleSet: ruleSet)
        viewModel.commit(password: "b")
        var expect = expectation(description: "save failed")
        viewModel.save(password: "b").subscribe {
            XCTFail("un-expected success")
            expect.fulfill()
        } onError: { error in
            if let error = error as? CustomPasswordViewModel.ValidationError {
                XCTAssertEqual(error, .invalidPassword)
            } else {
                XCTFail("un-expected error: \(error)")
            }
            expect.fulfill()
        }.disposed(by: disposeBag)
        
        waitForExpectations(timeout: 1)

        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.suitePermissionPasswordCommit)
            return contain
        }, response: { request in
            let response = HTTPStubsResponse(jsonObject: ["code": 0,
                                                          "msg": "success",
                                                          "data": [:]],
                                             statusCode: 200,
                                             headers: ["Content-Type": "application/json"])

            if let body = request.ohhttpStubs_httpBody,
                  let data = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                XCTAssertEqual(data["token"] as? String, "mock")
                XCTAssertEqual(data["type"] as? Int, 22)
                XCTAssertEqual(data["password"] as? String, "a")
            } else {
                XCTFail("request body not found")
            }
            return response
        })
        expect = expectation(description: "save success")
        viewModel.commit(password: "a")
        viewModel.save(password: "a").subscribe {
            expect.fulfill()
        } onError: { error in
            XCTFail("un-expected error: \(error)")
            expect.fulfill()
        }.disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }

    func testGetRandomPassword() {
        let disposeBag = DisposeBag()
        let viewModel = CustomPasswordViewModel(objToken: "mock", objType: .docX, ruleSet: .empty)
        var expect = expectation(description: "random password success")
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.suitePermissionPasswordRandom)
            return contain
        }, response: { request in
            HTTPStubsResponse(jsonObject: ["code": 0,
                                           "msg": "success",
                                           "data": ["password": "password"]],
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        viewModel.getRandomPassword().subscribe { password in
            XCTAssertEqual(password, "password")
            expect.fulfill()
        } onError: { error in
            XCTFail("un-expected error: \(error)")
            expect.fulfill()
        }.disposed(by: disposeBag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "random password failed")
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.suitePermissionPasswordRandom)
            return contain
        }, response: { request in
            HTTPStubsResponse(jsonObject: ["code": 0,
                                           "msg": "success",
                                           "data": [:]],
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        viewModel.getRandomPassword().subscribe { _ in
            XCTFail("un-expected success")
            expect.fulfill()
        } onError: { error in
            if let error = error as? DocsNetworkError {
                XCTAssertEqual(error.code, .invalidData)
            } else {
                XCTFail("un-expected error: \(error)")
            }
            expect.fulfill()
        }.disposed(by: disposeBag)
        waitForExpectations(timeout: 1)
    }
}
