//
//  TestPointCutProvider.swift
//  LarkPolicyEngine-Unit-Tests
//
//  Created by Wujie on 2023/5/25.
//

import Foundation
@testable import LarkPolicyEngine
import LarkSnCService
import XCTest

class TestCombineAlgorithm: XCTestCase {

    let testStorage = TestStorage()
    let testStorageFailure = TestStorageFailure()
    let testHttpClient = TestHTTPClient()
    let testSettings = TestSettings()
    let testEnvironment = TestEnvironment()
    let testHTTPClientCodeNotZero = TestHTTPClientCodeNotZero()
    let testHTTPClientFailure = TestHTTPClientFailure()
    let testEnvironmentDomainFailure = TestEnvironmentDomainFailure()

    func testFirstApplicable() {
        // permit
        let policyCombinerPermit = CombineAlgorithmChecker<[String]>(algorithm: .firstApplicable)
        policyCombinerPermit.push(node: ["Action"], effect: .permit)
        let interruptPermit = policyCombinerPermit.interrupt()
        XCTAssertTrue(interruptPermit)
        let genResultPermit = policyCombinerPermit.genResult()
        XCTAssertTrue(genResultPermit.0 == .permit)

        // deny
        let policyCombinerDeny = CombineAlgorithmChecker<[String]>(algorithm: .firstApplicable)
        policyCombinerDeny.push(node: ["Action"], effect: .deny)
        let interruptDeny = policyCombinerDeny.interrupt()
        XCTAssertTrue(interruptDeny)
        let genResultDeny = policyCombinerDeny.genResult()
        XCTAssertTrue(genResultDeny.0 == .deny)

        // indeterminate
        let policyCombinerIndeterminate = CombineAlgorithmChecker<[String]>(algorithm: .firstApplicable)
        policyCombinerIndeterminate.push(node: ["Action"], effect: .indeterminate)
        let interruptIndeterminate = policyCombinerIndeterminate.interrupt()
        XCTAssertFalse(interruptIndeterminate)
        let genResultIndeterminate = policyCombinerIndeterminate.genResult()
        XCTAssertTrue(genResultIndeterminate.0 == .indeterminate)

        // notApplicable
        let policyCombinerNotApplicable = CombineAlgorithmChecker<[String]>(algorithm: .firstApplicable)
        policyCombinerNotApplicable.push(node: ["Action"], effect: .notApplicable)
        let interruptNotApplicable = policyCombinerNotApplicable.interrupt()
        XCTAssertFalse(interruptNotApplicable)
        let genResultNotApplicable = policyCombinerNotApplicable.genResult()
        XCTAssertTrue(genResultNotApplicable.0 == .notApplicable)

        // node > 1
        let policyCombinerNodes = CombineAlgorithmChecker<[String]>(algorithm: .firstApplicable)
        policyCombinerNodes.push(node: ["Action"], effect: .permit)
        policyCombinerNodes.push(node: ["Action"], effect: .deny)
        policyCombinerNodes.push(node: ["Action"], effect: .indeterminate)
        policyCombinerNodes.push(node: ["Action"], effect: .notApplicable)
        let interruptNodes = policyCombinerNodes.interrupt()
        XCTAssertTrue(interruptNodes)
        let genResultNodes = policyCombinerNodes.genResult()
        XCTAssertTrue(genResultNodes.0 == .deny)
    }

    func testDenyOverride() {
        // permit
        let policyCombinerPermit = CombineAlgorithmChecker<[String]>(algorithm: .denyOverride)
        policyCombinerPermit.push(node: ["Action"], effect: .permit)
        let interruptPermit = policyCombinerPermit.interrupt()
        XCTAssertFalse(interruptPermit)
        let genResultPermit = policyCombinerPermit.genResult()
        XCTAssertTrue(genResultPermit.0 == .permit)

        // deny
        let policyCombinerDeny = CombineAlgorithmChecker<[String]>(algorithm: .denyOverride)
        policyCombinerDeny.push(node: ["Action"], effect: .deny)
        let interruptDeny = policyCombinerDeny.interrupt()
        XCTAssertFalse(interruptDeny)
        let genResultDeny = policyCombinerDeny.genResult()
        XCTAssertTrue(genResultDeny.0 == .deny)

        // indeterminate
        let policyCombinerIndeterminate = CombineAlgorithmChecker<[String]>(algorithm: .denyOverride)
        policyCombinerIndeterminate.push(node: ["Action"], effect: .indeterminate)
        let interruptIndeterminate = policyCombinerIndeterminate.interrupt()
        XCTAssertFalse(interruptIndeterminate)
        let genResultIndeterminate = policyCombinerIndeterminate.genResult()
        XCTAssertTrue(genResultIndeterminate.0 == .indeterminate)

        // notApplicable
        let policyCombinerNotApplicable = CombineAlgorithmChecker<[String]>(algorithm: .denyOverride)
        policyCombinerNotApplicable.push(node: ["Action"], effect: .notApplicable)
        let interruptNotApplicable = policyCombinerNotApplicable.interrupt()
        XCTAssertFalse(interruptNotApplicable)
        let genResultNotApplicable = policyCombinerNotApplicable.genResult()
        XCTAssertTrue(genResultNotApplicable.0 == .notApplicable)

        // node > 1
        let policyCombinerNodes = CombineAlgorithmChecker<[String]>(algorithm: .denyOverride)
        policyCombinerNodes.push(node: ["Action"], effect: .permit)
        policyCombinerNodes.push(node: ["Action"], effect: .deny)
        policyCombinerNodes.push(node: ["Action"], effect: .indeterminate)
        policyCombinerNodes.push(node: ["Action"], effect: .notApplicable)
        let interruptNodes = policyCombinerNodes.interrupt()
        XCTAssertFalse(interruptNodes)
        let genResultNodes = policyCombinerNodes.genResult()
        XCTAssertTrue(genResultNodes.0 == .deny)
    }

    func testFirstDenyApplicable() {
        // permit
        let policyCombinerPermit = CombineAlgorithmChecker<[String]>(algorithm: .firstDenyApplicable)
        policyCombinerPermit.push(node: ["Action"], effect: .permit)
        let interruptPermit = policyCombinerPermit.interrupt()
        XCTAssertFalse(interruptPermit)
        let genResultPermit = policyCombinerPermit.genResult()
        XCTAssertTrue(genResultPermit.0 == .permit)

        // deny
        let policyCombinerDeny = CombineAlgorithmChecker<[String]>(algorithm: .firstDenyApplicable)
        policyCombinerDeny.push(node: ["Action"], effect: .deny)
        let interruptDeny = policyCombinerDeny.interrupt()
        XCTAssertTrue(interruptDeny)
        let genResultDeny = policyCombinerDeny.genResult()
        XCTAssertTrue(genResultDeny.0 == .deny)

        // indeterminate
        let policyCombinerIndeterminate = CombineAlgorithmChecker<[String]>(algorithm: .firstDenyApplicable)
        policyCombinerIndeterminate.push(node: ["Action"], effect: .indeterminate)
        let interruptIndeterminate = policyCombinerIndeterminate.interrupt()
        XCTAssertFalse(interruptIndeterminate)
        let genResultIndeterminate = policyCombinerIndeterminate.genResult()
        XCTAssertTrue(genResultIndeterminate.0 == .indeterminate)

        // notApplicable
        let policyCombinerNotApplicable = CombineAlgorithmChecker<[String]>(algorithm: .firstDenyApplicable)
        policyCombinerNotApplicable.push(node: ["Action"], effect: .notApplicable)
        let interruptNotApplicable = policyCombinerNotApplicable.interrupt()
        XCTAssertFalse(interruptNotApplicable)
        let genResultNotApplicable = policyCombinerNotApplicable.genResult()
        XCTAssertTrue(genResultNotApplicable.0 == .notApplicable)

        // node > 1
        let policyCombinerNodes = CombineAlgorithmChecker<[String]>(algorithm: .firstDenyApplicable)
        policyCombinerNodes.push(node: ["Action"], effect: .permit)
        policyCombinerNodes.push(node: ["Action"], effect: .deny)
        policyCombinerNodes.push(node: ["Action"], effect: .indeterminate)
        policyCombinerNodes.push(node: ["Action"], effect: .notApplicable)
        let interruptNodes = policyCombinerNodes.interrupt()
        XCTAssertTrue(interruptNodes)
        let genResultNodes = policyCombinerNodes.genResult()
        XCTAssertTrue(genResultNodes.0 == .deny)
    }

    func testFirstPermitApplicable() {
        // permit
        let policyCombinerPermit = CombineAlgorithmChecker<[String]>(algorithm: .firstPermitApplicable)
        policyCombinerPermit.push(node: ["Action"], effect: .permit)
        let interruptPermit = policyCombinerPermit.interrupt()
        XCTAssertTrue(interruptPermit)
        let genResultPermit = policyCombinerPermit.genResult()
        XCTAssertTrue(genResultPermit.0 == .permit)

        // deny
        let policyCombinerDeny = CombineAlgorithmChecker<[String]>(algorithm: .firstPermitApplicable)
        policyCombinerDeny.push(node: ["Action"], effect: .deny)
        let interruptDeny = policyCombinerDeny.interrupt()
        XCTAssertFalse(interruptDeny)
        let genResultDeny = policyCombinerDeny.genResult()
        XCTAssertTrue(genResultDeny.0 == .deny)

        // indeterminate
        let policyCombinerIndeterminate = CombineAlgorithmChecker<[String]>(algorithm: .firstPermitApplicable)
        policyCombinerIndeterminate.push(node: ["Action"], effect: .indeterminate)
        let interruptIndeterminate = policyCombinerIndeterminate.interrupt()
        XCTAssertFalse(interruptIndeterminate)
        let genResultIndeterminate = policyCombinerIndeterminate.genResult()
        XCTAssertTrue(genResultIndeterminate.0 == .indeterminate)

        // notApplicable
        let policyCombinerNotApplicable = CombineAlgorithmChecker<[String]>(algorithm: .firstPermitApplicable)
        policyCombinerNotApplicable.push(node: ["Action"], effect: .notApplicable)
        let interruptNotApplicable = policyCombinerNotApplicable.interrupt()
        XCTAssertFalse(interruptNotApplicable)
        let genResultNotApplicable = policyCombinerNotApplicable.genResult()
        XCTAssertTrue(genResultNotApplicable.0 == .notApplicable)

        // node > 1
        let policyCombinerNodes = CombineAlgorithmChecker<[String]>(algorithm: .firstPermitApplicable)
        policyCombinerNodes.push(node: ["Action"], effect: .permit)
        policyCombinerNodes.push(node: ["Action"], effect: .deny)
        policyCombinerNodes.push(node: ["Action"], effect: .indeterminate)
        policyCombinerNodes.push(node: ["Action"], effect: .notApplicable)
        let interruptNodes = policyCombinerNodes.interrupt()
        XCTAssertTrue(interruptNodes)
        let genResultNodes = policyCombinerNodes.genResult()
        XCTAssertTrue(genResultNodes.0 == .permit)
    }

    func testOnlyOneApplicable() {
        // permit
        let policyCombinerPermit = CombineAlgorithmChecker<[String]>(algorithm: .onlyOneApplicable)
        policyCombinerPermit.push(node: ["Action"], effect: .permit)
        let interruptPermit = policyCombinerPermit.interrupt()
        XCTAssertFalse(interruptPermit)
        let genResultPermit = policyCombinerPermit.genResult()
        XCTAssertTrue(genResultPermit.0 == .permit)

        // deny
        let policyCombinerDeny = CombineAlgorithmChecker<[String]>(algorithm: .onlyOneApplicable)
        policyCombinerDeny.push(node: ["Action"], effect: .deny)
        let interruptDeny = policyCombinerDeny.interrupt()
        XCTAssertFalse(interruptDeny)
        let genResultDeny = policyCombinerDeny.genResult()
        XCTAssertTrue(genResultDeny.0 == .deny)

        // indeterminate
        let policyCombinerIndeterminate = CombineAlgorithmChecker<[String]>(algorithm: .onlyOneApplicable)
        // node >= 2
        policyCombinerIndeterminate.push(node: ["Action"], effect: .indeterminate)
        policyCombinerIndeterminate.push(node: ["Action"], effect: .indeterminate)
        let interruptIndeterminate = policyCombinerIndeterminate.interrupt()
        XCTAssertFalse(interruptIndeterminate)
        let genResultIndeterminate = policyCombinerIndeterminate.genResult()
        XCTAssertTrue(genResultIndeterminate.0 == .indeterminate)

        // notApplicable
        let policyCombinerNotApplicable = CombineAlgorithmChecker<[String]>(algorithm: .onlyOneApplicable)
        policyCombinerNotApplicable.push(node: ["Action"], effect: .notApplicable)
        let interruptNotApplicable = policyCombinerNotApplicable.interrupt()
        XCTAssertFalse(interruptNotApplicable)
        let genResultNotApplicable = policyCombinerNotApplicable.genResult()
        XCTAssertTrue(genResultNotApplicable.0 == .notApplicable)

        // notApplicable,no push
        let policyCombinerNotApplicableNoPush = CombineAlgorithmChecker<[String]>(algorithm: .onlyOneApplicable)
        let interruptNotApplicableNoPush = policyCombinerNotApplicableNoPush.interrupt()
        XCTAssertFalse(interruptNotApplicableNoPush)
        let genResultNotApplicableNoPush = policyCombinerNotApplicableNoPush.genResult()
        XCTAssertTrue(genResultNotApplicableNoPush.0 == .notApplicable)

        // node > 1
        let policyCombinerNodes = CombineAlgorithmChecker<[String]>(algorithm: .onlyOneApplicable)
        policyCombinerNodes.push(node: ["Action"], effect: .permit)
        policyCombinerNodes.push(node: ["Action"], effect: .deny)
        policyCombinerNodes.push(node: ["Action"], effect: .indeterminate)
        policyCombinerNodes.push(node: ["Action"], effect: .notApplicable)
        let interruptNodes = policyCombinerNodes.interrupt()
        XCTAssertFalse(interruptNodes)
        let genResultNodes = policyCombinerNodes.genResult()
        XCTAssertTrue(genResultNodes.0 == .indeterminate)
    }

    func testPermitOverride() {
        // permit
        let policyCombinerPermit = CombineAlgorithmChecker<[String]>(algorithm: .permitOverride)
        policyCombinerPermit.push(node: ["Action"], effect: .permit)
        let interruptPermit = policyCombinerPermit.interrupt()
        XCTAssertFalse(interruptPermit)
        let genResultPermit = policyCombinerPermit.genResult()
        XCTAssertTrue(genResultPermit.0 == .permit)

        // deny
        let policyCombinerDeny = CombineAlgorithmChecker<[String]>(algorithm: .permitOverride)
        policyCombinerDeny.push(node: ["Action"], effect: .deny)
        let interruptDeny = policyCombinerDeny.interrupt()
        XCTAssertFalse(interruptDeny)
        let genResultDeny = policyCombinerDeny.genResult()
        XCTAssertTrue(genResultDeny.0 == .deny)

        // indeterminate
        let policyCombinerIndeterminate = CombineAlgorithmChecker<[String]>(algorithm: .permitOverride)
        policyCombinerIndeterminate.push(node: ["Action"], effect: .indeterminate)
        let interruptIndeterminate = policyCombinerIndeterminate.interrupt()
        XCTAssertFalse(interruptIndeterminate)
        let genResultIndeterminate = policyCombinerIndeterminate.genResult()
        XCTAssertTrue(genResultIndeterminate.0 == .indeterminate)

        // notApplicable
        let policyCombinerNotApplicable = CombineAlgorithmChecker<[String]>(algorithm: .permitOverride)
        policyCombinerNotApplicable.push(node: ["Action"], effect: .notApplicable)
        let interruptNotApplicable = policyCombinerNotApplicable.interrupt()
        XCTAssertFalse(interruptNotApplicable)
        let genResultNotApplicable = policyCombinerNotApplicable.genResult()
        XCTAssertTrue(genResultNotApplicable.0 == .notApplicable)

        // node > 1
        let policyCombinerNodes = CombineAlgorithmChecker<[String]>(algorithm: .permitOverride)
        policyCombinerNodes.push(node: ["Action"], effect: .permit)
        policyCombinerNodes.push(node: ["Action"], effect: .deny)
        policyCombinerNodes.push(node: ["Action"], effect: .indeterminate)
        policyCombinerNodes.push(node: ["Action"], effect: .notApplicable)
        let interruptNodes = policyCombinerNodes.interrupt()
        XCTAssertFalse(interruptNodes)
        let genResultNodes = policyCombinerNodes.genResult()
        XCTAssertTrue(genResultNodes.0 == .permit)
    }

    func testCombineAlgorithmType() {
        let combineAlgorithmType = CombineAlgorithmType<String>()
        combineAlgorithmType.push(node: "Action", effect: .deny)
        XCTAssertTrue(combineAlgorithmType.interrupt())
        XCTAssertTrue(combineAlgorithmType.genResult().0 == .permit)
    }

}
