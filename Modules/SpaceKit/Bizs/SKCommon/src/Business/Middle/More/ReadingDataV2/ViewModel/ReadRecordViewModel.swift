//
//  ReadRecordViewModel.swift
//  SKCommon
//
//  Created by CJ on 2021/9/25.
// swiftlint:disable closure_end_indentation

import SKFoundation
import SwiftyJSON
import RxSwift
import RxCocoa
import SKResource
import SKInfra

protocol ReadRecordListRequestType {
    func request(path: String, params: [String: Any]?, callback: @escaping(JSON?, Error?) -> Void) -> String
    func cancel(id: String)
}

class ReadRecordListRequestImp: ReadRecordListRequestType {
    
    private var requests: [String: DocsRequest<JSON>] = [:]
    
    init() {}

    func request(path: String, params: [String: Any]?, callback: @escaping(JSON?, Error?) -> Void) -> String {
        let request = DocsRequest<JSON>(path: path, params: params)
            .set(method: .GET)
            .set(timeout: 20)
            .set(encodeType: .urlEncodeDefault)
        request.start(result: { (response, error) in
            callback(response, error)
        })
        let id = UUID().uuidString
        requests[id] = request
        return id
    }
    
    func cancel(id: String) {
        requests[id]?.cancel()
        requests[id] = nil
    }
}

class ReadRecordViewModel {
    static let pageSize = 20 // QA测试值 5
    static let visitsMaxCount = 200 // QA测试值 15
    private let callbackQueue = DispatchQueue(label: "lark.space.read_record")
    var readRecordInfo: ReadRecordInfo = ReadRecordInfo()
    private(set) var token: String
    private(set) var type: Int
    private var listRequest: ReadRecordListRequestType
    
    init(token: String, type: Int, listRequest: ReadRecordListRequestType = ReadRecordListRequestImp()) {
        self.token = token
        self.type = type
        self.listRequest = listRequest
    }
    
    /// 开放给外部的错误
    enum ReadRecordError: Error, Equatable {
        case none
        /// 网络错误， 接口字段错误
        case loadError(hasDataNow: Bool)
        /// 权限错误
        case permission
        /// admin后台关闭
        case adminTunOff
        /// 非owner
        case notOwner
    }
    
    /// 内部处理的错误
    enum InternalError: Error {
        case requestError
        case invalidData
        case serverError(ErrorCode)
    }
    
    /// 服务器下发错误码
    enum ErrorCode: Int {
        /// 内部错误
        case internalError = 1
        /// 参数错误
        case paramsError = 2
        /// 无文档阅读或编辑权限
        case permission = 3
        /// 非文档所有者
        case notOwner = 7
        /// Admin 阅读记录功能关闭
        case adminTurnOff = 8
        /// 用户隐私设置关闭
        case settingTurnOff = 9
    }
    
    enum ToastStatus {
        case success(String)
        case error(String)
    }
    
    struct State {
        // 数组表示每次请求的单页数据
        public var data = BehaviorRelay<(ReadRecordInfo, [ReadRecordUserInfoModel])>(value: (ReadRecordInfo(), .init()))
        public var loading = BehaviorRelay<Bool>(value: false)
        public var error = BehaviorRelay<ReadRecordError>(value: .none)
        public var empty = BehaviorRelay<Bool>(value: false)
        public var toast = BehaviorRelay<ToastStatus?>(value: nil)
        public init() {}
    }
    
    var state: State = State()
    
    private var viewHasDidAppear = false
    
    private var disposeBag = DisposeBag()
}


// MARK: - UI invoke

extension ReadRecordViewModel {
    
    func acceptInput(event: PublishRelay<ReadRecordListViewController.Event>) {
        event.subscribe(onNext: { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .errorReload:
                if !DocsNetStateMonitor.shared.isReachable {
                    self.state.toast.accept(.error(BundleI18n.SKResource.Doc_List_OperateFailedNoNet))
                    return
                }
                self.request()
            case .viewDidAppear:
                switch self.state.error.value {
                case .permission:
                    if self.viewHasDidAppear {
                        self.request()
                    }
                case .none, .loadError, .adminTunOff, .notOwner:
                    break
                }
                self.viewHasDidAppear = true
            }
            
        }).disposed(by: disposeBag)
    }
    
    func request() {
        self.state.loading.accept(true)
        self.readRecordInfo.nextPageToken = ""
        self.readRecordInfo.readUsers = []
        requetsList(isFirstPage: true)
    }
    
    func loadMore() {
        requetsList(isFirstPage: false)
    }
    
    private func requetsList(isFirstPage: Bool) {
        requestReadRecordInfo(getViewCount: isFirstPage)
            .subscribe { [weak self] list in
            guard let self = self else { return }
            self.state.loading.accept(false)
            self.readRecordInfo.readUsers.append(contentsOf: list)
            if self.readRecordInfo.readUsers.isEmpty {
                // 显示空图
                self.state.empty.accept(true)
            } else {
                // 刷新UI
                self.state.data.accept((self.readRecordInfo, list))
            }
        } onError: { [weak self] error in
            guard let self = self else { return }
            self.state.loading.accept(false)
            if let err = error as? InternalError {
                self.handleError(err)
            }
        }.disposed(by: disposeBag)
    }
    
    private func handleError(_ error: InternalError) {
        let hasDataNow = state.data.value.0.readUsers.isEmpty == false
        switch error {
        case .invalidData, .requestError:
            self.state.error.accept(.loadError(hasDataNow: hasDataNow))
            if hasDataNow {
                self.state.toast.accept(.error(BundleI18n.SKResource.CreationMobile_Common_Placeholder_FailedToLoad))
            }
        case .serverError(let errorCode):
            switch errorCode {
            case .internalError, .paramsError:
                self.state.error.accept(.loadError(hasDataNow: hasDataNow))
            case .permission: // Owner才能进来，一般不会走这里
                self.state.error.accept(.permission)
            case .notOwner: // 非Owner应该是不能进入到这里的
                self.state.error.accept(.notOwner)
            case .adminTurnOff:
                self.state.error.accept(.adminTunOff)
            case .settingTurnOff:
                self.state.error.accept(.permission)
            }
        }
    }
}

    
// MARK: - network

extension ReadRecordViewModel {

    /// 获取阅读用户列表信息 https://bytedance.feishu.cn/docs/doccnAFWDuir89YoIL5KDO6GILe#
    /// `getViewCount` 第一页传true否则传false
    func requestReadRecordInfo(getViewCount: Bool,
                                      pageSize: Int = ReadRecordViewModel.pageSize) -> Observable<[ReadRecordUserInfoModel]> {
        var path = OpenAPI.APIPath.getReadRecordInfo + "?obj_type=\(type)&get_view_count=\(getViewCount)&token=\(token)&page_size=\(pageSize)"
        if !readRecordInfo.nextPageToken.isEmpty {
            path = "\(path)&next_page_token=\(readRecordInfo.nextPageToken)"
        } else {
            self.readRecordInfo.reset()
        }
        return Observable.create { [weak self] ob in
            guard let self = self else { return  Disposables.create() }
            let id = self.listRequest.request(path: path, params: nil) { [weak self] json, error in
                guard let self = self else { return }
                guard error == nil else {
                    if let err = error as? NSError, let errorCode = ErrorCode(rawValue: err.code) {
                        DocsLogger.error("ReadRecordViewModel requestReadRecordInfo NSErrorCode:\(err.code) err:\(err)")
                        ob.onError(InternalError.serverError(errorCode))
                        return
                    }
                    ob.onError(InternalError.requestError)
                    DocsLogger.error("ReadRecordViewModel requestReadRecordInfo error", error: error)
                    return
                }
                if let code = json?["code"].int,
                    let errorCode = ErrorCode(rawValue: code) {
                    let msg = json?["msg"].stringValue ?? ""
                    DocsLogger.error("ReadRecordViewModel requestReadRecordInfo errorCode:\(code) msg:\(msg)")
                    ob.onError(InternalError.serverError(errorCode))
                    return
                }
                guard let dict = json?.dictionaryObject,
                      let data = dict["data"] as? [String: Any]
                else {
                    DocsLogger.error("ReadRecordViewModel requestReadRecordInfo invalidData")
                    ob.onError(InternalError.invalidData)
                    return
                }
                let usersDict = data["users"] as? [[String: Any]] ?? []
                if let uv = data["uv"] as? Int {
                    self.readRecordInfo.uv = uv
                }
                if let hiddenUV = data["hidden_uv"] as? Int {
                    self.readRecordInfo.hiddenUv = hiddenUV
                }
                self.readRecordInfo.nextPageToken = (data["next_page_token"] as? String) ?? ""
                let userInfoModels = ReadRecordUserInfoModel.convertReadUsersInfo(usersDict)
                DocsLogger.error("ReadRecordViewModel requestReadRecordInfo success count:\(userInfoModels.count)")
                ob.onNext(userInfoModels)
            }
            return Disposables.create { [weak self] in
                self?.listRequest.cancel(id: id)
            }
        }
    }
}
