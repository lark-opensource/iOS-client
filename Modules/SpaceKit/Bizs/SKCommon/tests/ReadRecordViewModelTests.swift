//
//  ReadRecordViewModelTests.swift
//  SpaceDemoTests
//
//  Created by huayufan on 2022/3/2.
//  Copyright © 2022 Bytedance. All rights reserved.


import XCTest
@testable import SKCommon
import SKResource
import RxSwift
import RxCocoa
import SwiftyJSON

class ReadRecordViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    
    class MockRequest: ReadRecordListRequestType {
        
        var testJson: JSON? {
            if let path = Bundle(for: MockRequest.self).path(forResource: "get_view_detail", ofType: "json"),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                return try? JSON(data: data)
            }
            return nil
        }

        enum DataType {
            case lessData // 只有一页数据
            case moreData(Int) // 总共有几页数据
            
            case internalError
            case permissionError
            case adminTurnOffError
            case settingTurnOffError
            case notOwner
            
            var code: Int {
                switch self {
                case .lessData, .moreData:
                    return 0
                case .internalError:
                    return 1
                case .permissionError:
                    return 3
                case .notOwner:
                    return 7
                case .adminTurnOffError:
                    return 8
                case .settingTurnOffError:
                    return 9
                }
            }
        }
        
        var type: DataType
        
        init(type: DataType) {
            self.type = type
        }
        
        var currentPage = 0
        var preToken: String?
        
        var requestAssert: ((String) -> Void)?
        
        func request(path: String, params: [String: Any]?, callback: @escaping(JSON?, Error?) -> Void) -> String {
            let url = URL(string: path)
            if url == nil {
                requestAssert?("url is invalid")
            }
            guard let components = URLComponents(url: url!, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else {
                requestAssert?("queryItems is nil")
                return ""
            }
            let query = queryItems.reduce(into: [String: String]()) { (result, item) in
                        result[item.name] = item.value
            }
            switch type {
            case .lessData:
                callback(testJson, nil)
            case .moreData(let max):
                var response = testJson!
                let getViewCount = query["get_view_count"] ?? "false"
                
                if currentPage == 0 {
                    if getViewCount != "true" {
                        requestAssert?("get_view_count should be true")
                    }
                } else {
                    if getViewCount != "false" {
                        requestAssert?("get_view_count should be false")
                    }
                }
                
                if currentPage > 0 && currentPage <= max - 1 {
                    XCTAssertNotNil(query["next_page_token"])
                    let next_page_token = query["next_page_token"] ?? "-"
                    XCTAssertEqual(next_page_token, preToken)
                    if next_page_token != preToken {
                        requestAssert?("next_page_token should be equal to preToken")
                    }
                }
                if currentPage < max - 1 { // 非最后一页
                    let token = UUID().uuidString
                    var dict = response.dictionaryObject!
                    if var data = dict["data"] as? [String: Any] {
                        data["next_page_token"] = token
                        dict["data"] = data
                    }
                    response = JSON(dict)
                    preToken = token
                }
                currentPage += 1
                callback(response, nil)
            default:
                callback(nil, NSError(domain: "com.spacedemo.test", code: self.type.code, userInfo: nil))
            }
            
            return UUID().uuidString
        }
        
        func cancel(id: String) {}
    }

    func testLessDataRequest() {
        let viewModel = ReadRecordViewModel(token: "abc", type: 1, listRequest: MockRequest(type: .lessData))
        let disposeBag = DisposeBag()
        var errorStatus: ReadRecordViewModel.ReadRecordError = .none
        viewModel.state.error.subscribe(onNext: { (error) in
            errorStatus = error
        }).disposed(by: disposeBag)
        viewModel.request()
        XCTAssertEqual(errorStatus, ReadRecordViewModel.ReadRecordError.none)
        XCTAssertTrue(viewModel.readRecordInfo.nextPageToken.isEmpty)
    }

    func testMoreDataRequest() {
        let request = MockRequest(type: .moreData(3))
        request.requestAssert = { str in
            XCTAssertTrue(str.isEmpty)
        }
        let viewModel = ReadRecordViewModel(token: "abc", type: 1, listRequest: request)
        let disposeBag = DisposeBag()
        var count = 0
        viewModel.state.data
            .subscribe(onNext: { info in
                count = info.0.readUsers.count
        }).disposed(by: disposeBag)
        
        var errorStatus: ReadRecordViewModel.ReadRecordError = .none
        viewModel.state.error.subscribe(onNext: { (error) in
            errorStatus = error
        }).disposed(by: disposeBag)
        viewModel.request()
        
        XCTAssertEqual(errorStatus, ReadRecordViewModel.ReadRecordError.none)
        
        XCTAssertTrue(!viewModel.readRecordInfo.nextPageToken.isEmpty)
        XCTAssertEqual(count, 2)
        viewModel.loadMore()
        XCTAssertTrue(!viewModel.readRecordInfo.nextPageToken.isEmpty)
        XCTAssertEqual(count, 4)
        viewModel.loadMore()
        XCTAssertTrue(viewModel.readRecordInfo.nextPageToken.isEmpty)
        XCTAssertEqual(count, 6)
    }
    
    func testErrorRequest() {
        let types: [MockRequest.DataType] = [.adminTurnOffError,
                                             .permissionError,
                                             .settingTurnOffError,
                                             .internalError,
                                             .notOwner]
        let experts: [ReadRecordViewModel.ReadRecordError] = [.adminTunOff,
                                                              .permission,
                                                              .permission,
                                                              .loadError(hasDataNow: false),
                                                              .notOwner]
        for (idx, type) in types.enumerated() {
            let request = MockRequest(type: type)
            request.requestAssert = { str in
                XCTAssertTrue(str.isEmpty)
            }
            let viewModel = ReadRecordViewModel(token: "abc", type: 1, listRequest: request)
            let disposeBag = DisposeBag()
            var errorStatus: ReadRecordViewModel.ReadRecordError = .none
            viewModel.state.error.subscribe(onNext: { (error) in
                errorStatus = error
            }).disposed(by: disposeBag)
            viewModel.request()
            XCTAssertEqual(errorStatus, experts[idx])
            XCTAssertTrue(viewModel.readRecordInfo.nextPageToken.isEmpty)
        }
    }
    
    func testAcceptInput() {
        let eventSubject = PublishRelay<ReadRecordListViewController.Event>()
        let request = MockRequest(type: .permissionError)
        let viewModel = ReadRecordViewModel(token: "abc", type: 1, listRequest: request)
        let disposeBag = DisposeBag()
        var errorStatus: ReadRecordViewModel.ReadRecordError = .none
        viewModel.state.error.subscribe(onNext: { (error) in
            errorStatus = error
        }).disposed(by: disposeBag)
        var count = 0
        viewModel.state.data
            .subscribe(onNext: { info in
                count = info.0.readUsers.count
        }).disposed(by: disposeBag)
        
        viewModel.acceptInput(event: eventSubject)
        eventSubject.accept(.viewDidAppear)
        viewModel.request() // 产生permissionError错误
        XCTAssertEqual(errorStatus, ReadRecordViewModel.ReadRecordError.permission)
        
        // viewDidAppear更新到最新有权限的阅读数据
        request.type = .lessData
        eventSubject.accept(.viewDidAppear)
        XCTAssertTrue(count > 0)
        count = 0

        request.type = .notOwner
        viewModel.request() // 产生notOwner错误
        eventSubject.accept(.viewDidAppear) // 进来之后不会请求到数据
        XCTAssertTrue(count == 0)
    }
}
