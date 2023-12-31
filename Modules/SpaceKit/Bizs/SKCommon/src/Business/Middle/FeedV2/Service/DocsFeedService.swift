//
//  DocsFeedService.swift
//  SKCommon
//
//  Created by huayufan on 2021/5/21.
//  

import RxSwift
import RxCocoa
import HandyJSON
import SKFoundation
import SwiftyJSON
import RustPB
import LarkRustClient
import SpaceInterface
import SKInfra

public final class DocsFeedService: NSObject {
    
    enum FeedError: Error {
        /// 无权限
        case forbidden
        
        case dataFormatError
        
        /// 数据解析失败
        case deserializeError
    }
    
    var docsInfo: DocsInfo
    
    var feedRequest: DocsRequest<JSON>?
    
    static var disposeBag = DisposeBag()
    
    static let queue = DispatchQueue(label: "doc.feed.service")
    
    let from: FeedFromInfo
    
    public init(_ docsInfo: DocsInfo, _ from: FeedFromInfo) {
        self.docsInfo = docsInfo
        self.from = from
    }
    
    enum Status {
        case pending([Handler])
        case fulfilled(JSON)
        case rejected
    }
    
    class Handler {
        typealias HandlerType = (JSON) -> Void
        let callback: HandlerType
        init(_ callback: @escaping HandlerType) {
            self.callback = callback
        }
    }
    
    /// key: staskId
    static private(set) var tasks: [String: Status] = [:]
    
    class func getTaskId(_ token: String, _ type: Int, _ timestamp: Double) -> String {
        return "\(token)_\(type)_\(timestamp)"
    }
    
    static let supportedTypes: [DocsType] = [.doc, .docX, .bitable, .sheet, .mindnote, .slides]
    
    /// 请求Feed数据，在Lark Feed路由处调用
    class func loadFeedData(url: URL, timestamp: Double) {
        DocsFeedService.queue.async {
            if let type = DocsType(url: url),
               supportedTypes.contains(type),
               let token = DocsUrlUtil.getFileToken(from: url, with: type),
               !token.isEmpty {
                DocsLogger.feedInfo("loadFeedData preload:\(DocsType(url: url)?.name)")
                let taskId = getTaskId(token, type.rawValue, timestamp)
                loadFeedData(taskId: taskId, token: token, type: type.rawValue, timestamp: timestamp) { _ in }
            } else {
                DocsLogger.feedError("loadFeedData fail type:\(DocsType(url: url)?.name)")
            }
        }
    }
    
    
   class func inspectPending(taskId: String, callback: @escaping (JSON) -> Void) {
        if case let .pending(handlers) = self.tasks[taskId] {
            var current = handlers
            current.append(Handler(callback))
            self.tasks[taskId] = .pending(current)
        }
    }
    
    private class func loadFeedData(taskId: String, token: String, type: Int, timestamp: Double, result: @escaping (JSON) -> Void) {
        let status = self.tasks[taskId]
        if case .pending = status {
            DocsLogger.feedInfo("loadFeedData in pending status")
            return
        } else if case let .fulfilled(response) = status {
            DocsLogger.feedInfo("loadFeedData cache is ready")
            result(response)
        }
        
        var params: [String: Any] = ["obj_token": token,
                                     "obj_type": type]
        if Self.contentReactionFeatureEnabled() {
            params["need_content_reaction"] = true
        }
        self.tasks[taskId] = .pending([])
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getFeedV2, params: params)
            .set(timeout: 20)
            .set(encodeType: .urlEncodeDefault)
            .start(result: { (data, error) in
                guard let response = data else {
                    DocsLogger.feedError("preload fail error:\(error)")
                    self.tasks[taskId] = .rejected
                    return
                }
                DocsLogger.feedInfo("preload success")
                if case let .pending(handlers) = self.tasks[taskId] {
                    DocsLogger.feedInfo("pending handlers count:\(handlers.count)")
                    for handler in handlers {
                        handler.callback(response)
                    }
                } else {
                    DocsLogger.feedError("no handlers status:\(self.tasks[taskId])")
                }
                result(response)
                self.tasks[taskId] = .fulfilled(response)
        })
        request.makeSelfReferenced()
    }
    
    func requestFeedData() -> Observable<FeedMessagesWithMetaInfo> {
        var params: [String: Any] = ["obj_token": docsInfo.token,
                                     "obj_type": docsInfo.inherentType.rawValue]
        if Self.contentReactionFeatureEnabled() {
            params["need_content_reaction"] = true
        }
        feedRequest?.cancel()
        return Observable.create({ [weak self] (ob) -> Disposable in
            guard let self = self else { return Disposables.create() }
            
            // 先看下提前请求的数据是否已经返回
            let taskId = DocsFeedService.getTaskId(self.docsInfo.token,
                                                   self.docsInfo.inherentType.rawValue,
                                                   self.from.getTimestamp(with: .larkFeed) ?? 0)
            if case let .fulfilled(data) = DocsFeedService.tasks[taskId] {
                DocsLogger.feedInfo("[requestFeedData] fetch fulfilled data success")
                self.handleResponse(data: data, error: nil, ob: ob)
                DocsFeedService.tasks[taskId] = nil
            } else if case .pending = DocsFeedService.tasks[taskId] { // 请求中
                DocsLogger.feedInfo("[requestFeedData] fetch waiting pending data")
                DocsFeedService.inspectPending(taskId: taskId) { [weak self] data in
                    DocsLogger.feedInfo("[requestFeedData] fetch pending data success")
                    self?.handleResponse(data: data, error: nil, ob: ob)
                    DocsFeedService.tasks[taskId] = nil
                }
            } else { // 预加载请求失败，重新拉取
                DocsLogger.feedInfo("[requestFeedData] fetching")
                self.feedRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.getFeedV2,
                                                      params: params)
                    .set(encodeType: .urlEncodeDefault)
                    .start(result: { [weak self] (data, error) in
                        guard let self = self else { return }
                        DocsLogger.feedInfo("[requestFeedData] fetching success")
                        self.handleResponse(data: data, error: error, ob: ob)
                })
            }
            
            return Disposables.create()
        })
    }
    
    private func handleResponse(data: JSON?, error: Error?, ob: AnyObserver<FeedMessagesWithMetaInfo> ) {
        DocsFeedService.queue.async {
            if data?["code"].intValue == DocsNetworkError.Code.forbidden.rawValue {
                ob.onError(FeedError.forbidden)
                return
            }
            if let err = error as? DocsNetworkError, err.code == .forbidden {
                ob.onError(FeedError.forbidden)
                return
            }
            guard let response = data?["data"].dictionaryObject else {
                ob.onError(FeedError.dataFormatError)
                return
            }
            
            let entity = MentionedEntity.parseDictionary(response)
            let isRemind = response["is_remind"] as? Bool
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let messages = self.getFilteredMessages(response)
            let badgeCount = data?["data"]["badge"]["count"].int ?? 0
            if messages.count > 20, self.canSplit(badgeCount: badgeCount) {
                let seperator = messages.index(0, offsetBy: 20)
                let less = Array(messages[messages.startIndex..<seperator])
                let more = Array(messages[seperator..<messages.endIndex])
                let mapResult1: Swift.Result<[FeedMessageModel], Error> = self.mapModels(decoder: decoder, params: less)
                switch mapResult1 {
                case .success(let models1):
                    ob.onNext(FeedMessagesWithMetaInfo(messages: models1, entity: entity, isRemind: isRemind))
                case .failure(let error):
                    DocsLogger.feedError("[requestFeedData] deserialize error:\(error)")
                    ob.onError(FeedError.deserializeError)
                }
                let mapResult2: Swift.Result<[FeedMessageModel], Error> = self.mapModels(decoder: decoder, params: more)
                switch mapResult2 {
                case .success(let models2):
                    let models1 = (try? mapResult1.get()) ?? []
                    ob.onNext(FeedMessagesWithMetaInfo(messages: models1 + models2, entity: entity, isRemind: isRemind))
                case .failure(let error):
                    DocsLogger.feedError("[requestFeedData] deserialize error:\(error)")
                    ob.onError(FeedError.deserializeError)
                }
            } else {
                let mapResult: Swift.Result<[FeedMessageModel], Error> = self.mapModels(decoder: decoder, params: messages)
                switch mapResult {
                case .success(let models):
                    ob.onNext(FeedMessagesWithMetaInfo(messages: models, entity: entity, isRemind: isRemind))
                case .failure(let error):
                    DocsLogger.feedError("[requestFeedData] deserialize error:\(error)")
                    ob.onError(FeedError.deserializeError)
                }
            }
        }
    }
    
    func canSplit(badgeCount: Int) -> Bool {
        if !UserScopeNoChangeFG.HYF.scrollFeedToFirstUnread { // FG关闭此判断失效
            return true
        } else {
            return badgeCount == 0
        }
    }
    
    private func mapModels<T: Decodable>(decoder: JSONDecoder, params: [[String: Any]]) -> Swift.Result<T, Error> {
        guard let data = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            DocsLogger.feedError("requestFeedData serialization error")
            return .failure(FeedError.deserializeError)
        }
        do {
            let models = try decoder.decode(T.self, from: data)
            return .success(models)
        } catch {
            DocsLogger.feedError("requestFeedData serialization error:\(error)")
            return .failure(error)
        }
    }
    
    func clearAllBadge(docsInfo: DocsInfo) {
        DocsRequest<JSON>(path: OpenAPI.APIPath.readAll,
                          params: ["token": docsInfo.token,
                                   "obj_type": docsInfo.inherentType.rawValue])
            .set(encodeType: .urlEncodeDefault)
            .makeSelfReferenced()
            .start(result: { (_, _) in })
    }
    
    func clearBadge(messageIds: [String], callback: @escaping (Error?) -> Void) {
        DocsLogger.feedInfo("prepare clear Feed badge count: \(messageIds.count) \(messageIds) ")
        let type = docsInfo.inherentType
        let params: [String: Any] = [DocsSDK.Keys.readFeedMessageIDs: messageIds,
                            "doc_type": type,
                            "isFromFeed": true,
                            "obj_token": docsInfo.token]
        guard let awesomeManager = HostAppBridge.shared.call(GetDocsManagerDelegateService()) as? DocsManagerDelegate else {
            DocsLogger.feedError("clear Feed badge fail")
            return
        }
        awesomeManager.sendReadMessageIDs(params, in: nil, callback: callback)
        if type == .wiki {
            DocsLogger.feedError("clear Feed badge wiki type is unsupported")
        }
    }

    /// 切换"免打扰"状态
    func toggleMuteState(_ isMute: Bool, completion: @escaping (Swift.Result<Void, Error>) -> Void) {
        let params: [String: Any] = ["source_token": docsInfo.token,
                                     "source_type": docsInfo.inherentType.rawValue,
                                     "is_remind": "\(!isMute)"]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.feedMute, params: params)
            .set(timeout: 10)
            .set(encodeType: .jsonEncodeDefault)
            .start(result: { (_, error) in
                if let error = error {
                    DocsLogger.feedError("mute toggle error:\(error)")
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
        })
        request.makeSelfReferenced()
    }
    
    /// 一键清除已读
    func toggleCleanButton(_ createTime: Double, completion: @escaping (Swift.Result<Void, Error>) -> Void) {
        let params: [String: Any] = ["source_token": docsInfo.token,
                                     "source_type": docsInfo.inherentType.rawValue,
                                     "notice_time": createTime]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.cleanMessage, params: params)
            .set(method: .POST)
            .set(timeout: 10)
            .set(encodeType: .urlEncodeAsQuery)
            .start(result: { (_, error) in
                if let error = error {
                    DocsLogger.feedError("clean button error:\(error)")
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
        })
        request.makeSelfReferenced()
    }
}


extension DocsFeedService {
    
    public class func clearBadge(_ version: Int32, _ count: Int32, _ token: String) {
        guard let rustClient = DocsContainer.shared.resolve(RustService.self) else {
            DocsLogger.feedInfo("获取rustClient失败")
            return
        }
        var request = Space_Doc_V1_UpdateDocMessageBadgeRequest()
        request.newMessageCount = count
        request.version = version
        request.token = token
        var disposeBag = DisposeBag()
        DocsLogger.feedInfo("update message badge count:\(count) version:\(version)")
        _ = rustClient.sendAsyncRequest(request).subscribe({ _ in
            DocsLogger.feedInfo("调用兜底消badge逻辑")
            disposeBag = DisposeBag()
            }).disposed(by: disposeBag)
    }
}

extension DocsFeedService {
    /// 支持`正文表情`功能
    private static func contentReactionFeatureEnabled() -> Bool {
        return true
//        LKFeatureGating.contentReactionEnabled
    }

    /// 如果需要过滤掉reaction消息则过滤掉
    private func getFilteredMessages(_ response: [String: Any]) -> [[String: Any]] {
        let reactionEnabled = (response["user_reaction_feed_enable"] as? Bool) ?? true // 默认不过滤
        let messages = (response["message"] as? [[String: Any]]) ?? []
        
        if reactionEnabled {
            return messages
        } else {
            let filtered = messages.filter { message in
                (message["type"] as? String) != FeedMessageModel.MessageType.docsReaction.rawValue
            }
            return filtered
        }
    }
}
