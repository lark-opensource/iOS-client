//
//  DocsReadingInfoViewModelTests.swift
//  SpaceDemoTests
//
//  Created by huayufan on 2022/3/1.
//  Copyright © 2022 Bytedance. All rights reserved.


import XCTest
@testable import SKCommon
import SKResource
import RxSwift
import RxCocoa

class DocsReadingInfoViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func testFormatNumber() {
        let viewModel = DocsReadingInfoViewModel(docsInfo: DocsInfo(type: .doc, objToken: "abc"),
                                                 permission: nil, permissionService: nil)
        let K = BundleI18n.SKResource.CreationMobile_Common_Units_thousand
        let M = BundleI18n.SKResource.CreationMobile_Common_Units_million
        let numbers = [-1, 0, 888, 1200, 600000, 1100000]
        let results = ["N/A", "0", "888", "1\(K)", "600\(K)", "1\(M)"]
        for (number, expect) in zip(numbers, results) {
            let value = viewModel.formatNumber(number)
            XCTAssertEqual(value, expect)
        }
    }

    func testStatus() {
        let detail: DocsReadingData = .details(DocsReadingInfoModel(params: [:], ownerId: "fakeid001"))
        let word: DocsReadingData = .words([ReadingItemInfo(.charNumber, "1")])
        let pairs: [[DocsReadingData]] = [[detail, word], [detail, .words(nil)], [.details(nil), word], [.details(nil), .words(nil)]]
        let expects: [DocsReadingInfoViewModel.Status] = [.none, .needReload, .needReload, .fetchFail]

        for (idx, pair) in pairs.enumerated() {
            let viewModel = DocsReadingInfoViewModel(docsInfo: DocsInfo(type: .doc, objToken: "abc"),
                                                     permission: nil, permissionService: nil)
            let triggerRelay = BehaviorRelay<DocsReadingData?>(value: nil)
            let eventRelay = PublishRelay<DocDetailInfoViewController.Event>()
            let output = viewModel.transform(input: .init(trigger: triggerRelay,
                                                          event: eventRelay))
            let disposeBag = DisposeBag()
            var status: DocsReadingInfoViewModel.Status = .none
            output.status.subscribe(onNext: { (st) in
                status = st
            }).disposed(by: disposeBag)

            triggerRelay.accept(pair[0])
            XCTAssertEqual(DocsReadingInfoViewModel.Status.loading, status)
            triggerRelay.accept(pair[1])
            XCTAssertEqual(expects[idx], status)
        }
    }
    
    func testRecordInfoEntrance() {
        let permissions: [UserPermissionMask?] = [UserPermissionMask.read, UserPermissionMask.fullAccess, nil]
        let expects = [false, true, false]
        for (idx, permission) in permissions.enumerated() {
            let viewModel = DocsReadingInfoViewModel(docsInfo: DocsInfo(type: .doc, objToken: "abc"),
                                                     permission: permissions[idx], permissionService: nil)
            let triggerRelay = BehaviorRelay<DocsReadingData?>(value: nil)
            let eventRelay = PublishRelay<DocDetailInfoViewController.Event>()
            let output = viewModel.transform(input: .init(trigger: triggerRelay,
                                                          event: eventRelay))
            let disposeBag = DisposeBag()
            var status: DocsReadingInfoViewModel.Status = .none
            output.status.subscribe(onNext: { (st) in
                status = st
            }).disposed(by: disposeBag)
            let detail: DocsReadingData = .details(DocsReadingInfoModel(params: [:], ownerId: "fakeid001"))
            let word: DocsReadingData = .words([ReadingItemInfo(.charNumber, "1")])
            triggerRelay.accept(detail)
            triggerRelay.accept(word)
            var contain = false
            for sectionType in viewModel.data {
                if case .readRecordInfo = sectionType {
                    contain = true
                    break
                }
            }
            XCTAssertEqual(expects[idx], contain)
        }
    }
}
