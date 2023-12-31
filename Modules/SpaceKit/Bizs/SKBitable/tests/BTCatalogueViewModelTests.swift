//
//  BTCatalogueViewModelTests.swift
//  SpaceDemoTests
//
//  Created by huayufan on 2022/3/4.
//  Copyright © 2022 Bytedance. All rights reserved.


import XCTest
@testable import SKBitable
import RxSwift
import RxCocoa
@testable import SKFoundation

class BTCatalogueViewModelTests: XCTestCase {

    let sourceView = UIView()
    
    override func setUp() {
        super.setUp()
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.mobile.expose_catalog", value: true)
    }

    override func tearDown() {
        super.tearDown()
        UserScopeNoChangeFG.removeMockFG(key: "ccm.bitable.mobile.expose_catalog")
    }


    class MockAPI: CatalogueServiceAPI {
        enum Action: String {
            case addTable = "add_table"
            case dismiss = "exit"
        }
        let action: Action
        
        var requestClosure: ((String, [String: Any]) -> Void)?
        
        init(action: Action) {
            self.action = action
        }
        
        func request(callback: String, params: [String: Any]) {
            requestClosure?(callback, params)
        }
        
        func shouldPopoverDisplay() -> Bool {
            return true
        }
    }

    func loadList() -> [String: Any] {
        guard let path = Bundle(for: BTCatalogueViewModelTests.self).path(forResource: "catalogue_dictionary", ofType: "plist"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
               return [:]
        }
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return [:]
        }
        return plist
    }
    
    func testOutput() {
        let disposeBag = DisposeBag()
        let api = MockAPI(action: .addTable)
        let viewModel = BTCatalogueViewModel(api: api)
        let triggerRelay = PublishRelay<[String: Any]>()
        let eventDrive = PublishRelay<BTCatalogueViewController.Event>()
        let input = BTCatalogueViewModel.Input(trigger: triggerRelay,
                                               eventDrive: eventDrive.asDriver(onErrorJustReturn: .none))
        let output = viewModel.transform(input: input)
        let params = loadList()
        XCTAssertFalse(params.isEmpty)
        
        var title = ""
        var model: CatalogueCreateViewData?
        var state: BTCatalogueView.State?
        
        output.title.subscribe { title = $0 }.disposed(by: disposeBag)
        output.catalogue.subscribe { state = $0 }.disposed(by: disposeBag)
        output.bottomData.subscribe { model = $0 }.disposed(by: disposeBag)
        
        triggerRelay.accept(params)
        XCTAssertFalse(title.isEmpty)
        XCTAssertNotNil(model)
        if case let .reload(result, autoAdjust) = state {
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(autoAdjust)
        } else {
            XCTAssertNotNil(nil)
        }
        
        api.requestClosure = { (callback, params) in
            let sourceViewID = params["sourceViewID"]
            XCTAssertNotNil(sourceViewID)
        }
        eventDrive.accept(.add(Weak(sourceView), nil))
        
        api.requestClosure = { (callback, params) in
            let sourceViewID = params["sourceViewID"]
            XCTAssertNotNil(sourceViewID)
        }
        eventDrive.accept(.slide(.init(row: 0, section: 0), .add, Weak(sourceView)))
        
        api.requestClosure = { (callback, params) in
            let sourceViewID = params["sourceViewID"]
            XCTAssertNotNil(sourceViewID)
        }
        eventDrive.accept(.slide(.init(row: 1, section: 0), .add, Weak(sourceView)))
        
        print(api)  // 持有 api，防止被提前释放
    }
    
    func testAction() {
        let addTableAPI = MockAPI(action: .addTable)
        addTableAPI.requestClosure = { (callback, params) in
            XCTAssertEqual(callback, "window.lark.callback.func_bizbitablemanagerPanel1646388703627_8485")
            let id = (params["id"] as? String) ?? "mock"
            XCTAssertEqual(id, "add_table")
        }
        var viewModel = BTCatalogueViewModel(api: addTableAPI)
        viewModel.addAction(sourceView: Weak(sourceView))
        
        let dismissAPI = MockAPI(action: .addTable)
        addTableAPI.requestClosure = { (callback, params) in
            let id = (params["id"] as? String) ?? "mock"
            XCTAssertEqual(id, "exit")
        }
        viewModel = BTCatalogueViewModel(api: dismissAPI)
        viewModel.dismissAction()
    }
}
