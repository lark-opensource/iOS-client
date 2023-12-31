//
//  WebSearchViewModelTestCase.swift
//  WebBrowser-Unit-Tests
//
//  Created by baojianjun on 2023/10/31.
//

import XCTest

import RxSwift
import RxCocoa
import RxBlocking
import RxTest

@testable import WebBrowser

@available(iOS 13.0, *)
final class WebSearchVMStateTestCase: XCTestCase {
    
    let viewModel = WebSearchBarViewModel()
    let listener = MockWebSearchBarStateListener()
    let jsDelegate = MockWebSearchJSDelegate()
    var enterCount = 0
    var exitCount = 0
    var mockSearchbar: MockSearchBar?
    
    override func setUpWithError() throws {
        viewModel.stateListener = listener
        viewModel.jsDelegate = jsDelegate
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testState() throws {
        listener.stateDidChangeBlock = { [weak self] (newValue, oldValue) in
            if newValue == .none {
                self?.exitCount += 1
            } else if oldValue == .none {
                self?.enterCount += 1
            }
        }
        
        XCTAssert(viewModel.state == .none)
        
        viewModel.enterSearchMode(.shortcut)
        XCTAssert(viewModel.state != .none)
        XCTAssert(enterCount == 1)
        
        // 重复进入
        viewModel.enterSearchMode(.shortcut)
        XCTAssert(enterCount == 1)
        
        // 重复进入
        viewModel.enterSearchMode(.shortcut)
        XCTAssert(enterCount == 1)
    }
}

// @available(iOS 13.0, *)
// final class WebSearchVMJSTestCase: XCTestCase {
    
//     let viewModel = WebSearchBarViewModel()
//     let listener = MockWebSearchBarStateListener()
//     let jsDelegate = MockWebSearchJSDelegate()
//     var enterCount = 0
//     var exitCount = 0
//     var mockSearchbar: MockSearchBar?
    
//     override func setUpWithError() throws {
//         viewModel.stateListener = listener
//         viewModel.jsDelegate = jsDelegate
//         listener.stateDidChangeBlock = { [weak self] (newValue, oldValue) in
//             if newValue == .none {
//                 self?.exitCount += 1
//                 self?.mockSearchbar = nil
//             } else if oldValue == .none {
//                 self?.enterCount += 1
//                 let searchbar = MockSearchBar()
//                 self?.viewModel.bind(
//                     upArrowSignal: searchbar.upArrowSignal,
//                     pressShiftEnterSignal: searchbar.pressShiftEnterSignal,
//                     downArrowSignal: searchbar.downArrowSignal,
//                     pressEnterSignal: searchbar.pressEnterSignal,
//                     finishSignal: searchbar.finishSignal,
//                     pressEscapeSignal: searchbar.pressEscapeSignal,
//                     searchObservable: searchbar.searchObservable,
//                     indexSubject: searchbar.indexSubject,
//                     disposeBag: searchbar.disposeBag)
//                 self?.mockSearchbar = searchbar
//             }
//         }
//     }
    
//     func handleOnNext(observer: AnyObserver<Void>) -> () -> Void {
//         return {
//             observer.onNext(())
//         }
//     }
    
//     override func tearDownWithError() throws {
//         // Put teardown code here. This method is called after the invocation of each test method in the class.
//     }

//     func testJSSuccess() async throws {
        
//         viewModel.enterSearchMode(.mouse)
//         XCTAssert(viewModel.state != .none)
//         guard let mockSearchbar = self.mockSearchbar else {
//             XCTFail("mockSearchbar is nil!")
//             return
//         }
        
//         // 1. mock content
//         var mockIndex = (1,2)
//         jsDelegate.mockIndex = mockIndex
        
//         // 2. unit test helper
//         var indexSubjectCalledCount = 0
//         var indexRealCount = 0
//         var jsPreCalledCount = 0
//         var jsNextCalledCount = 0
//         var jsConfirmCalledCount = 0
//         let verifyJSCalledCount: (Int) -> Void = { indexCount in
//             XCTAssert(indexSubjectCalledCount == indexCount, "indexSubjectCalledCount:\(indexSubjectCalledCount) is not equal to indexCount:\(indexCount)")
//             XCTAssert(self.jsDelegate.jsPreCalledCount == jsPreCalledCount, "jsDelegate.jsPreCalledCount: \(self.jsDelegate.jsPreCalledCount) is not equal to real jsPreCalledCount: \(jsPreCalledCount)")
//             XCTAssert(self.jsDelegate.jsNextCalledCount == jsNextCalledCount, "jsDelegate.jsNextCalledCount: \(self.jsDelegate.jsNextCalledCount) is not equal to real jsNextCalledCount: \(jsNextCalledCount)")
//             XCTAssert(self.jsDelegate.jsConfirmCalledCount == jsConfirmCalledCount, "jsDelegate.jsConfirmCalledCount: \(self.jsDelegate.jsConfirmCalledCount) is not equal to real jsConfirmCalledCount: \(jsConfirmCalledCount)")
//         }
//         let verifyCacheIndex = {
//             if let cacheIndex = self.viewModel.cacheIndex {
//                 XCTAssert(cacheIndex == mockIndex, "cacheIndex:\(String(describing: self.viewModel.cacheIndex)) is not equal to mockIndex:\(mockIndex)")
//             } else {
//                 XCTFail("this is no cacheIndex")
//             }
//         }
        
//         func verifyCacheKeyword(keyword: String?) {
//             if let cacheKeyword = self.viewModel.cacheKeyword {
//                 XCTAssert(cacheKeyword == keyword, "cacheKeyword:\(String(describing: self.viewModel.cacheKeyword)) is not equal to mockKeyword: \(keyword)")
//             } else if let keyword {
//                 XCTFail("this is no cacheKeyword!")
//             } else {
//                 // right
//             }
//         }
        
//         // MARK: - TEST 1
        
//         // 3. run unit test
//         let asyncFunc: (@escaping ((Int, Int)) -> Void, @escaping () -> Void) -> Task = { c1, c2 in
//             return Task {
//                 let exp = XCTestExpectation(description: "downArrowSubject")
//                 let dispose = mockSearchbar.indexSubject
//                     .asObservable()
//                     .subscribe { index in
//                         c1(index)
//                         exp.fulfill()
//                     }
//                 c2()
//                 await self.fulfillment(of: [exp], timeout: 1)
//                 dispose.dispose()
//             }
//         }
        
//         do {
//             let task = asyncFunc({ index in
//                 indexSubjectCalledCount += 1
//                 XCTAssert(index == mockIndex)
//             }, {
//                 mockSearchbar.upArrowSubject.onNext(())
//             })
//             let _ = await task.result
//         }
        
//         jsPreCalledCount += 1
//         indexRealCount += 1
        
//         // 4. verify result
//         verifyJSCalledCount(indexRealCount)
//         verifyCacheIndex()
        
//         // MARK: - TEST 1 - ∞
//         var loop = 10
//         while loop != 0 {
//             // 3. run unit test
//             do {
//                 let task = asyncFunc({ index in
//                     indexSubjectCalledCount += 1
//                     XCTAssert(index == mockIndex)
//                 }, {
//                     mockSearchbar.upArrowSubject.onNext(())
//                 })
//                 let _ = await task.result
//             }
//             jsPreCalledCount += 1
//             indexRealCount += 1
            
//             // 4. verify result
//             verifyJSCalledCount(indexRealCount)
//             verifyCacheIndex()
            
//             loop -= 1
//         }
        
//         // MARK: - TEST 2
        
//         // 1. mock content
//         mockIndex = (2,3)
//         jsDelegate.mockIndex = mockIndex
        
//         // 3. run unit test
//         do {
//             let task = asyncFunc({ index in
//                 indexSubjectCalledCount += 1
//                 XCTAssert(index == mockIndex)
//             }, {
//                 mockSearchbar.downArrowSubject.onNext(())
//             })
//             let _ = await task.result
//         }
        
//         jsNextCalledCount += 1
//         indexRealCount += 1
        
//         // 4. verify result
//         verifyJSCalledCount(indexRealCount)
//         verifyCacheIndex()
        
//         // MARK: - TEST 3
        
//         // 1. mock content
//         mockIndex = (3,4)
//         jsDelegate.mockIndex = mockIndex
        
//         // 3. run unit test
//         do {
//             let task = asyncFunc({ index in
//                 indexSubjectCalledCount += 1
//                 XCTAssert(index == mockIndex)
//             }, {
//                 mockSearchbar.pressShiftEnterSubject.onNext(())
//             })
//             let _ = await task.result
//         }
//         jsPreCalledCount += 1
//         indexRealCount += 1
        
//         // MARK: - TEST 3 - ∞
//         loop = 10
//         while loop != 0 {
//             // 3. run unit test
//             do {
//                 let task = asyncFunc({ index in
//                     indexSubjectCalledCount += 1
//                     XCTAssert(index == mockIndex)
//                 }, {
//                     mockSearchbar.upArrowSubject.onNext(())
//                 })
//                 let _ = await task.result
//             }
//             jsPreCalledCount += 1
//             indexRealCount += 1
            
//             // 4. verify result
//             verifyJSCalledCount(indexRealCount)
//             verifyCacheIndex()
            
//             loop -= 1
//         }
        
//         // 4. verify result
//         verifyJSCalledCount(indexRealCount)
//         verifyCacheIndex()
        
//         // MARK: - TEST 4
        
//         // 1. mock content
//         mockIndex = (10, 10)
//         jsDelegate.mockIndex = mockIndex
        
//         // 3. run unit test
//         do {
//             let task = asyncFunc({ index in
//                 indexSubjectCalledCount += 1
//                 XCTAssert(index == mockIndex)
//             }, {
//                 mockSearchbar.pressEnterSubject.onNext(())
//             })
//             let _ = await task.result
//         }
//         jsNextCalledCount += 1
//         indexRealCount += 1
        
//         // 4. verify result
//         verifyJSCalledCount(indexRealCount)
//         verifyCacheIndex()
        
//         // MARK: - TEST 5
        
//         // 1. mock content
//         mockIndex = (20, 30)
//         jsDelegate.mockIndex = mockIndex
        
//         // 3. run unit test
//         do {
//             let task = asyncFunc({ index in
//                 indexSubjectCalledCount += 1
//                 XCTAssert(index == mockIndex)
//             }, {
//                 mockSearchbar.searchSubject.onNext("this is search keyword")
//             })
//             let _ = await task.result
//         }
//         jsConfirmCalledCount += 1
//         indexRealCount += 1
        
//         // 4. verify result
//         verifyJSCalledCount(indexRealCount)
//         verifyCacheIndex()
//         verifyCacheKeyword(keyword: "this is search keyword")
        
//         // MARK: - TEST 6
        
//         // 1. mock content
//         // 不改写mockIndex，因为它在此次不会变
//         jsDelegate.mockIndex = (30, 100)
        
//         // 3. run unit test
        
//         do {
//             let asyncFunc2: (@escaping () -> Void, @escaping () -> Void) -> Task = { c1, c2 in
//                 return Task {
//                     let exp = XCTestExpectation(description: "downArrowSubject")
//                     let dispose = mockSearchbar.finishSignal
//                         .asObservable()
//                         .subscribe { _ in
//                             c1()
//                             exp.fulfill()
//                         }
//                     c2()
//                     await self.fulfillment(of: [exp], timeout: 1)
//                     dispose.dispose()
//                 }
//             }
            
//             let task = asyncFunc2({}, {
//                 mockSearchbar.finishSubject.onNext(())
//             })
//             let _ = await task.result
//         }
        
//         // indexRealCount不会变
        
//         // 4. verify result
//         verifyJSCalledCount(indexRealCount)
//         verifyCacheIndex()
//         verifyCacheKeyword(keyword: "this is search keyword")
//         XCTAssert(viewModel.state == .none)
//         XCTAssert(exitCount == 1)
//         XCTAssertNil(self.mockSearchbar)
        
//         // MARK: - TEST 7
//         // 重回搜索态
//         // 1. mock content
//         // 不改写mockIndex，因为它在此次不会变
//         jsDelegate.mockIndex = (40, 100)
        
//         // 3. run unit test
//         viewModel.enterSearchMode(.mouse)
        
//         // 4. verify result
//         XCTAssert(viewModel.state != .none)
//         XCTAssert(enterCount == 2)
//         XCTAssertNotNil(self.mockSearchbar)
//         verifyJSCalledCount(indexRealCount)
//         verifyCacheIndex()
//         verifyCacheKeyword(keyword: "this is search keyword")
        
//         // MARK: - TEST 8
        
//         // 1. mock content
//         mockIndex = (40, 100)
//         // 3. run unit test
//         do {
//             let task = asyncFunc({ index in
//                 indexSubjectCalledCount += 1
//             }, {
//                 mockSearchbar.searchSubject.onNext("this is second search text")
//             })
//             let _ = await task.result
//         }
//         jsConfirmCalledCount += 1
//         indexRealCount += 1
        
//         // 4. verify result
//         verifyJSCalledCount(indexRealCount)
//         verifyCacheIndex()
//         verifyCacheKeyword(keyword: "this is second search text")
//     }
    
//     func testJSFailed() async throws {
        
//         viewModel.enterSearchMode(.mouse)
//         XCTAssert(viewModel.state != .none)
//         guard let mockSearchbar = self.mockSearchbar else {
//             XCTFail("mockSearchbar is nil!")
//             return
//         }
        
//         // unit test helper
//         var mockIndex = (1,2)
//         var indexSubjectCalledCount = 0
//         var indexRealCount = 0
//         var jsPreCalledCount = 0
//         var jsNextCalledCount = 0
//         var jsConfirmCalledCount = 0
//         let verifyJSCalledCount: (Int) -> Void = { indexCount in
//             XCTAssert(indexSubjectCalledCount == indexCount, "indexSubjectCalledCount:\(indexSubjectCalledCount) is not equal to indexCount:\(indexCount)")
//             XCTAssert(self.jsDelegate.jsPreCalledCount == jsPreCalledCount, "jsDelegate.jsPreCalledCount: \(self.jsDelegate.jsPreCalledCount) is not equal to real jsPreCalledCount: \(jsPreCalledCount)")
//             XCTAssert(self.jsDelegate.jsNextCalledCount == jsNextCalledCount, "jsDelegate.jsNextCalledCount: \(self.jsDelegate.jsNextCalledCount) is not equal to real jsNextCalledCount: \(jsNextCalledCount)")
//             XCTAssert(self.jsDelegate.jsConfirmCalledCount == jsConfirmCalledCount, "jsDelegate.jsConfirmCalledCount: \(self.jsDelegate.jsConfirmCalledCount) is not equal to real jsConfirmCalledCount: \(jsConfirmCalledCount)")
//         }
//         let verifyCacheIndex = {
//             if let cacheIndex = self.viewModel.cacheIndex {
//                 XCTAssert(cacheIndex == mockIndex, "cacheIndex:\(String(describing: self.viewModel.cacheIndex)) is not equal to mockIndex:\(mockIndex)")
//             } else {
//                 XCTFail("this is no cacheIndex")
//             }
//         }
        
//         func makeAsyncFunc<T>(timeout: TimeInterval, observable: Observable<T>, subscribeFunc: @escaping (T) -> Void, excuteFunc: @escaping () -> Void) async {
//             let task = Task {
//                 let exp = XCTestExpectation(description: "asyncFunc")
//                 let dispose = observable
//                     .subscribe { param in
//                         subscribeFunc(param)
//                         exp.fulfill()
//                     }
//                 excuteFunc()
//                 await self.fulfillment(of: [exp], timeout: timeout)
//                 dispose.dispose()
//             }
//             _ = await task.result
//         }
        
//         func verifyCacheKeyword(keyword: String?) {
//             if let cacheKeyword = self.viewModel.cacheKeyword {
//                 XCTAssert(cacheKeyword == keyword, "cacheKeyword:\(String(describing: self.viewModel.cacheKeyword)) is not equal to mockKeyword: \(String(describing: keyword))")
//             } else if keyword != nil {
//                 XCTFail("this is no cacheKeyword!")
//             } else {
//                 // right
//             }
//         }
        
//         // MARK: Test 1.1
//         // 触发一次错误，indexSubject不会触发
//         jsDelegate.error = .jsError(nil)
//         jsDelegate.mockIndex = nil
//         do {
//             let observable = Observable.create { observer -> Disposable in
//                 DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                     observer.onNext(())
//                     observer.onCompleted()
//                 }
//                 return Disposables.create()
//             }
//             await makeAsyncFunc(timeout: 2, observable: observable) { _ in
//             } excuteFunc: {
//                 mockSearchbar.upArrowSubject.onNext(())
//             }
//         }
//         jsPreCalledCount += 1
        
//         // verify
//         verifyJSCalledCount(indexRealCount)
        
//         // MARK: Test 1.2
//         // 触发一次正确更新，indexSubject应当触发
//         jsDelegate.mockIndex = mockIndex
//         do {
//             let observable = mockSearchbar.indexSubject.asObservable()
//             await makeAsyncFunc(timeout: 1, observable: observable) { index in
//                 indexSubjectCalledCount += 1
//                 XCTAssert(index == mockIndex)
//             } excuteFunc: {
//                 mockSearchbar.upArrowSubject.onNext(())
//             }
//         }
//         indexRealCount += 1
//         jsPreCalledCount += 1
        
//         // verify
//         verifyJSCalledCount(indexRealCount)
//         verifyCacheIndex()
//         verifyCacheKeyword(keyword: nil)
        
//         // MARK: Test 2.1
//         // 首先触发一次JS无回调, 然后触发一次正确回调
//         jsDelegate.mockIndex = nil
//         jsDelegate.error = nil
//         do {
//             let observable = Observable.create { observer -> Disposable in
//                 DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                     observer.onNext(())
//                     observer.onCompleted()
//                 }
//                 return Disposables.create()
//             }
//             await makeAsyncFunc(timeout: 2, observable: observable) { _ in
//             } excuteFunc: {
//                 mockSearchbar.upArrowSubject.onNext(())
//             }
//         }
//         jsPreCalledCount += 1
        
//         // MARK: Test 2.2
//         jsDelegate.mockIndex = (3, 3)
//         do {
//             let observable = mockSearchbar.indexSubject.asObservable()
//             await makeAsyncFunc(timeout: 1, observable: observable) { index in
//                 indexSubjectCalledCount += 1
//                 XCTAssert(index == (3, 3))
//             } excuteFunc: {
//                 mockSearchbar.upArrowSubject.onNext(())
//             }
//         }
//         mockIndex = (3, 3)
//         indexRealCount += 1
//         jsPreCalledCount += 1
        
//         // verify
//         verifyJSCalledCount(indexRealCount)
//         verifyCacheIndex()
//         verifyCacheKeyword(keyword: nil)
        
//         // MARK: Test 3.1
//         // 触发一次错误，indexSubject不会触发
//         jsDelegate.error = .jsError(nil)
//         jsDelegate.mockIndex = nil
//         do {
//             let observable = Observable.create { observer -> Disposable in
//                 DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                     observer.onNext(())
//                     observer.onCompleted()
//                 }
//                 return Disposables.create()
//             }
//             await makeAsyncFunc(timeout: 2, observable: observable) { _ in
//             } excuteFunc: {
//                 mockSearchbar.downArrowSubject.onNext(())
//             }
//         }
//         jsNextCalledCount += 1
        
//         // verify
//         verifyJSCalledCount(indexRealCount)
        
//         // MARK: Test 3.2
//         // 触发一次正确更新，indexSubject应当触发
//         jsDelegate.mockIndex = mockIndex
//         do {
//             let observable = mockSearchbar.indexSubject.asObservable()
//             await makeAsyncFunc(timeout: 1, observable: observable) { index in
//                 indexSubjectCalledCount += 1
//                 XCTAssert(index == mockIndex)
//             } excuteFunc: {
//                 mockSearchbar.downArrowSubject.onNext(())
//             }
//         }
//         indexRealCount += 1
//         jsNextCalledCount += 1
        
//         // verify
//         verifyJSCalledCount(indexRealCount)
//         verifyCacheIndex()
//         verifyCacheKeyword(keyword: nil)
        
//         // MARK: Test 4.1
//         // 触发一次错误，indexSubject不会触发
//         jsDelegate.error = .jsError(nil)
//         jsDelegate.mockIndex = nil
//         do {
//             let observable = Observable.create { observer -> Disposable in
//                 DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                     observer.onNext(())
//                     observer.onCompleted()
//                 }
//                 return Disposables.create()
//             }
//             await makeAsyncFunc(timeout: 2, observable: observable) { _ in
//             } excuteFunc: {
//                 mockSearchbar.searchSubject.onNext(("can not get me"))
//             }
//         }
//         jsConfirmCalledCount += 1
        
//         // verify
//         verifyJSCalledCount(indexRealCount)
        
//         // MARK: Test 4.2
//         // 触发一次正确更新，indexSubject应当触发
//         jsDelegate.error = nil
//         jsDelegate.mockIndex = mockIndex
//         do {
//             let observable = mockSearchbar.indexSubject.asObservable()
//             await makeAsyncFunc(timeout: 1, observable: observable) { index in
//                 indexSubjectCalledCount += 1
//                 XCTAssert(index == mockIndex)
//             } excuteFunc: {
//                 mockSearchbar.searchSubject.onNext("you got me!")
//             }
//         }
//         indexRealCount += 1
//         jsConfirmCalledCount += 1
        
//         // verify
//         verifyJSCalledCount(indexRealCount)
//         verifyCacheIndex()
//         verifyCacheKeyword(keyword: "you got me!")
        
//     }
// }

final class MockWebSearchBarStateListener: WebSearchBarStateListener {
    
    var stateDidChangeBlock: ((SearchState, SearchState) -> Void)?
    
    func stateDidChange(_ newValue: SearchState, oldValue: SearchState) {
        stateDidChangeBlock?(newValue, oldValue)
    }
    
    func monitorSearchClick(_ click: WebSearch.ClickType, resultCnt: Int?) {
        
    }
}

final class MockWebSearchJSDelegate: WebSearchJSDelegate {
    
    // mock
    
    var mockIndex: (Int, Int)?
    var error: WebSearch.CustomError?
    
    var jsConfirmCalledCount = 0
    var jsPreCalledCount = 0
    var jsNextCalledCount = 0
    
    func jsEnterSearch(keyword: String?, index: Int?) {
        
    }
    
    func jsExitSearch() {
        
    }
    
    func mock(_ callback: @escaping WebSearch.JSCallBack) {
        if let mockIndex {
            callback(.success(mockIndex))
        } else if let error {
            callback(.failure(error))
        } else {
            // 测试不callback的逻辑
        }
    }
    
    func jsConfirmSearch(keyword: String?, callback: @escaping WebSearch.JSCallBack) {
        jsConfirmCalledCount += 1
        mock(callback)
    }
    
    func jsPre(callback: @escaping WebSearch.JSCallBack) {
        jsPreCalledCount += 1
        mock(callback)
    }
    
    func jsNext(callback: @escaping WebSearch.JSCallBack) {
        jsNextCalledCount += 1
        mock(callback)
    }
}

final class MockSearchBar {
    
    let upArrowSubject = PublishSubject<Void>()
    let downArrowSubject = PublishSubject<Void>()
    
    let finishSubject = PublishSubject<Void>()
    let pressEscapeSubject = PublishSubject<Void>()
    
    let pressEnterSubject = PublishSubject<Void>()
    let pressShiftEnterSubject = PublishSubject<Void>()
    
    let searchSubject = PublishSubject<String?>()
    
    
    let disposeBag = DisposeBag()
    lazy private(set) var upArrowSignal = {
        upArrowSubject.asSignal(onErrorJustReturn: ())
    }()
    
    lazy private(set) var downArrowSignal = {
        downArrowSubject.asSignal(onErrorJustReturn: ())
    }()
    
    lazy private(set) var finishSignal = {
        finishSubject.asSignal(onErrorJustReturn: ())
    }()
    
    lazy private(set) var pressEnterSignal = {
        pressEnterSubject.asSignal(onErrorJustReturn: ())
    }()
    
    lazy private(set) var pressShiftEnterSignal = {
        pressShiftEnterSubject.asSignal(onErrorJustReturn: ())
    }()
    
    lazy private(set) var pressEscapeSignal = {
        pressEscapeSubject.asSignal(onErrorJustReturn: ())
    }()
    
    lazy private(set) var searchObservable = searchSubject.asObservable()
    
    let indexSubject = PublishSubject<(Int, Int)>()
}
