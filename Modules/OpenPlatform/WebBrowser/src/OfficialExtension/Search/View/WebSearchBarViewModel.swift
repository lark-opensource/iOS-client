//
//  WebSearchBarViewModel.swift
//  WebBrowser
//
//  Created by baojianjun on 2023/10/25.
//

import Foundation
import LKCommonsLogging
import RxSwift
import RxCocoa
import ECOProbe

enum SearchState: Equatable {
    case none
    case searching(WebSearch.OpenActionType)
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return switch lhs {
        case .none:
            switch rhs {
            case .none:
                true
            default:
                false
            }
        case .searching:
            switch rhs {
            case .searching:
                true
            default:
                false
            }
        }
    }
}

protocol WebSearchBarStateListener: AnyObject {
    func stateDidChange(_ newValue: SearchState, oldValue: SearchState)
    func monitorSearchClick(_ click: WebSearch.ClickType, resultCnt: Int?)
}

final class WebSearchBarViewModel: NSObject {
    
    private static let logger = Logger.webBrowserLog(WebSearchBarViewModel.self, category: "WebSearchBarViewModel")
    
    weak var jsDelegate: WebSearchJSDelegate?
    weak var stateListener: WebSearchBarStateListener?
    
    private(set) var cacheIndex: WebSearch.IndexType?
    private(set) var cacheKeyword: String?
    
    func enterSearchMode(_ openAction: WebSearch.OpenActionType) {
        state = .searching(openAction)
    }
    
    private func exitSearchMode() {
        state = .none
    }
    
    private(set) var state: SearchState = .none {
        didSet {
            guard oldValue != state else {
                return
            }
            stateListener?.stateDidChange(state, oldValue: oldValue)
        }
    }
}

// MARK: -

protocol WebSearchJSDelegate: AnyObject {
    
    func jsEnterSearch(keyword: String?, index: Int?)
    
    func jsExitSearch()
    
    func jsConfirmSearch(keyword: String?, callback: @escaping WebSearch.JSCallBack)
    
    func jsPre(callback: @escaping WebSearch.JSCallBack)
    
    func jsNext(callback: @escaping WebSearch.JSCallBack)
}

// MARK: - JS API

extension WebSearchBarViewModel {
    
    private func JSWrapper(handle: @escaping (WebSearchJSDelegate, @escaping WebSearch.JSCallBack) -> Void) -> WebSearch.ObservableIndexResult {
        Observable.create { [weak self] observer -> Disposable in
            guard let jsDelegate = self?.jsDelegate else {
                observer.onNext(.failure(.noJSDelegate))
                observer.onCompleted()
                return Disposables.create()
            }
            handle(jsDelegate) { response in
                observer.onNext(response)
                observer.onCompleted()
            }
            return Disposables.create()
        }.subscribeOn(MainScheduler.instance)
    }
    
    func requestJSPre() -> WebSearch.ObservableIndexResult {
        JSWrapper {
            $0.jsPre(callback: $1)
        }
    }
    
    func requestJSNext() -> WebSearch.ObservableIndexResult {
        JSWrapper {
            $0.jsNext(callback: $1)
        }
    }
    
    func requestJSConfirmSearch(keyword: String?) -> WebSearch.ObservableIndexResult {
        JSWrapper {
            $0.jsConfirmSearch(keyword: keyword, callback: $1)
        }
    }
}

// MARK: - Data Bind

extension WebSearchBarViewModel {
    
    func bind(
        upArrowSignal: Signal<Void>,
        pressShiftEnterSignal: Signal<Void>,
        downArrowSignal: Signal<Void>,
        pressEnterSignal: Signal<Void>,
        finishSignal: Signal<Void>,
        pressEscapeSignal: Signal<Void>,
        searchObservable: Observable<String?>,
        indexSubject: PublishSubject<WebSearch.IndexType>,
        disposeBag: DisposeBag
    ) {
        let preFlatMap: (()) -> WebSearch.ObservableIndexResult = { [weak self] _ in
            guard let self else {
                return Observable.just(.failure(WebSearch.CustomError.noSelf))
            }
            return self.requestJSPre()
        }
        
        let nextFlatMap: (()) -> WebSearch.ObservableIndexResult = { [weak self] _ in
            guard let self else {
                return Observable.just(.failure(WebSearch.CustomError.noSelf))
            }
            return self.requestJSNext()
        }
        
        let searchFlatMap: (String?) -> WebSearch.ObservableIndexResult = { [weak self] keyword in
            guard let self else {
                return Observable.just(.failure(WebSearch.CustomError.noSelf))
            }
            self.cacheKeyword = keyword
            self.stateListener?.monitorSearchClick(.search, resultCnt: nil)
            return self.requestJSConfirmSearch(keyword: keyword)
        }
        
        let indexSubscribeFunc: (WebSearch.IndexResult, @escaping(Int) -> Void) -> Void = {
            [weak self] indexResult, callback in
            switch indexResult {
            case .success(let index):
                self?.cacheIndex = index
                callback(index.1)
                indexSubject.onNext(index)
            case .failure(let error):
                Self.logger.error("index subscribe error: \(error.errString)")
            }
        }
        
        let preIndexSubscribeFunc: (WebSearch.IndexResult) -> Void = {
            indexSubscribeFunc($0) {
                [weak self] _ in
                self?.stateListener?.monitorSearchClick(.previous_item, resultCnt: nil)
            }
        }
        
        let nextIndexSubscribeFunc: (WebSearch.IndexResult) -> Void = {
            indexSubscribeFunc($0) {
                [weak self] _ in
                self?.stateListener?.monitorSearchClick(.next_item, resultCnt: nil)
            }
        }
        
        let searchIndexSubscribeFunc: (WebSearch.IndexResult) -> Void = {
            indexSubscribeFunc($0) {
                [weak self] totalCount in
                self?.stateListener?.monitorSearchClick(.search_result, resultCnt: totalCount)
            }
        }
        
        upArrowSignal
            .asObservable()
            .flatMapLatest(preFlatMap)
            .subscribe(onNext: preIndexSubscribeFunc)
            .disposed(by: disposeBag)
        
        pressShiftEnterSignal
            .asObservable()
            .flatMapLatest(preFlatMap)
            .subscribe(onNext: preIndexSubscribeFunc)
            .disposed(by: disposeBag)
        
        downArrowSignal
            .asObservable()
            .flatMapLatest(nextFlatMap)
            .subscribe(onNext: nextIndexSubscribeFunc)
            .disposed(by: disposeBag)
        
        pressEnterSignal
            .asObservable()
            .flatMapLatest(nextFlatMap)
            .subscribe(onNext: nextIndexSubscribeFunc)
            .disposed(by: disposeBag)
        
        searchObservable
            .flatMapLatest(searchFlatMap)
            .subscribe(onNext: searchIndexSubscribeFunc)
            .disposed(by: disposeBag)
        
        Signal.of(
            finishSignal,
            pressEscapeSignal)
        .merge() // 合并监听
        .emit(onNext: { [weak self] in
            self?.exitSearchMode()
        }).disposed(by: disposeBag)
    }
}
