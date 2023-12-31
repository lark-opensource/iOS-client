//
//  AtDataSource.swift
//  SpaceKit
//
//  Created by weidong fu on 16/3/2018.
//

import Foundation
import SwiftyJSON
import SKFoundation
import LarkReleaseConfig
import SpaceInterface

public typealias AtDataList = (_ list: [RecommendData], _ error: Error?) -> Void

final public class AtDataSource {
    func clone() -> AtDataSource {
        let newConfig = Config(chatID: chatID, sourceFileType: sourceFileType, location: location, token: token)
        let newInstance = AtDataSource(config: newConfig)
        newInstance.minaSession = minaSession
        newInstance.useOpenID = useOpenID
        return newInstance
    }

    private var request: DocsRequest<[RecommendData]>?
    private var list: [RecommendData] = []
    public private(set) var token: String
    private let chatID: String?
    /// 正文，还是评论中
    public let location: AtViewType
    /// 被评论的文档类型，sheet/doc/bitable
    private var sourceFileType: DocsType
    public private(set) var currentKeyword: String?
    
    private var minaSession: Any?
    
    private var useOpenID = false // user是否使用openID,小程序场景为true,文档场景为false
    
    /// 是否可以at协同关系用户（譬如非好友，但是通过手机号添加的协作者）
    private var canAtCollaborationUser: Bool {
        return false
    }

    public init(config: Config) {
        self.token = config.token
        self.location = config.location
        self.sourceFileType = config.sourceFileType
        self.chatID = config.chatID
    }

    func update(token: String, sourceFileType: DocsType) {
        self.token = token
        self.sourceFileType = sourceFileType
    }
    
    
    func update(minaSession: Any) {
        self.minaSession = minaSession
    }

    func update(useOpenID: Bool) {
        self.useOpenID = useOpenID
    }
    
    // [MultiBase] 后面多 Base 改造需要改造这里并进行测试，确认这里的 token 和 type 传宿主还是block的
    public func getData(with keyword: String?, filter: String, completion: @escaping AtDataList) {
        guard let keyword = keyword else {
            completion([], nil)
            return
        }
        currentKeyword = keyword
        self.request?.cancel()
        var params: [String: Any] = ["token": self.token,
                                     "content": keyword,
                                     "type": filter]
        params["chat_id"] = chatID
        params["source"] = requestSource.rawValue
        params["config_source"] = DocsConfigManager.isfetchFullDataOfSpaceList ? 0 : 1
        params["user_type"] = canAtCollaborationUser ? 1 : 0
        if requestSource == .none {
            DocsLogger.error("fileType:\(sourceFileType) source is none", component: LogComponents.mention)
        }
        let source = requestSource
        self.request = DocsRequest<[RecommendData]>(path: "/api/mention/recommend.v2/",
                                                    params: params)
            .set(transform: { (response) -> ([RecommendData], error: Error?) in
                guard let response = response else { return ([], nil) }
                guard let results = response["data"]["result_list"].array else { return ([], DocsNetworkError.parse) }
                guard let entities = response["data"]["entities"].dictionary else { return ([], DocsNetworkError.parse) }
                let data = results.compactMap { (json) -> RecommendData? in
                    if let token = json["token"].string,
                        let type = json["type"].int,
                        let recommendType = RecommendType(rawValue: type),
                        let infos = entities[recommendType.typeStr]?[token] {
                        let data = RecommendData(withToken: token, keyword: keyword, type: recommendType, infos: infos)
                        data.requestSource = source
                        return data
                    } else {
                        return nil
                    }
                }
                return (data, nil)
            })
        if let minaSession = minaSession as? String {
            self.request?.requestConfig.headers["AppComm-Session"] = minaSession
            DocsLogger.info("requestConfig session: \(minaSession)", component: LogComponents.gadgetComment)
        }
        if self.useOpenID {
            self.request?.requestConfig.headers["Component-Session-Source"] = "comment_sdk"
            DocsLogger.info("requestConfig add source header", component: LogComponents.gadgetComment)
        }
        self.request?.start(result: { [weak self] (list, error) in
            guard let `self` = self else { return }
            self.list = list ?? []
            DocsLogger.info("got recommendData", extraInfo: ["listCount": list?.count ?? 0], component: LogComponents.mention)
            completion(self.list, error)
            if let err = error {
                DocsLogger.info("got recommendData", extraInfo: ["error": err.localizedDescription], component: LogComponents.mention)
            }
        })
    }
    
    /// 上报`提及`完成, 以便后端优化展示策略
    public func reportMentionFinish(userID: String) {
        let params: [String: Any] = ["mention_user_list": [userID],
                                     "source": requestSource.rawValue]
        let request = DocsRequest<Any>(path: "/api/mention/report/", params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        request.start(result: { (_, err) in
            DocsLogger.info("reportMention success:\(err == nil), error:\(String(describing: err))")
        })
    }
}

extension Set where Element == AtDataSource.RequestType {
    public var joinedType: String {
        return self.map({ String($0.rawValue) }).joined(separator: ",")
    }
}

// MARK: - dataTypeDefine
extension AtDataSource {

    public enum RequestType: Int {
        case user = 0
        case doc = 1
        case sheet = 3
        case chat = 5
        case group = 6
        case bitable = 8
        case mindnote = 11
        case file = 12
        case slides = 30
        case wiki = 16
        case docx = 22

        static func bitableEnable() -> Bool {
            return DocsType.enableDocTypeDependOnFeatureGating(type: .bitable)
        }

        /// 向后台请求聊天信息时，发送的参数。正文 at，带过滤器时的参数
        static let chatTypeSet: Set<AtDataSource.RequestType> = [.chat]

        /// 向后台请求文档信息时，发送的参数。正文 at，带过滤器时的参数
        public static let fileTypeSet: Set<AtDataSource.RequestType> = {
            var set: Set<AtDataSource.RequestType>
            set = [.doc, .docx, .sheet, .mindnote, .file, .wiki, .slides]
            if bitableEnable() { set.insert(.bitable) }
            return set
        }()

        /// 向后台请求用户信息时，发送的参数。正文 at，带过滤器时的参数MG
        public static let userTypeSet: Set<AtDataSource.RequestType> = [.user]
        /// 向后台请求群组信息。发送的参数。
        public static let groupTypeSet: Set<AtDataSource.RequestType> = [.group]
        /// 向后台请求用户信息时，发送的参数。全文评论等的参数
        public static let atViewFilter: Set<AtDataSource.RequestType> = {
            var set: Set<AtDataSource.RequestType>
            set = [.user, .doc, .docx, .sheet, .mindnote, .file, .wiki, .slides]
            if bitableEnable() { set.insert(.bitable) }
            return set
        }()

        public static let currentAllTypeSet: Set<AtDataSource.RequestType> = {
            var set: Set<AtDataSource.RequestType>
            set = [.user, .doc, .docx, .sheet, .mindnote, .chat, .file, .wiki, .slides]
            if bitableEnable() { set.insert(.bitable) }
            return set
        }()

        public static func decode(from str: String) -> Set<AtDataSource.RequestType> {
            switch str {
            case "user": return AtDataSource.RequestType.userTypeSet
            case "file": return AtDataSource.RequestType.fileTypeSet
            case "chat": return AtDataSource.RequestType.chatTypeSet
            default: return AtDataSource.RequestType.userTypeSet
            }
        }
    }

    /// @时，发起@的地方
    ///
    /// - doc: doc中
    /// - commentInDoc: doc的评论中
    /// - sheet: sheet中
    /// - commentInSheet: sheet的评论中
    /// - bitable: bitable中
    /// - commentInBitable: bitable的评论中
    /// - announcement: 群公告中
    /// - commentInAnnouncement: 群公告的评论中
    /// - commentInSlide : slide的评论中
    public enum RequestSource: Int {
        case none             = -1
        case doc = 0
        case commentInDoc = 1
        case sheet = 2
        case commentInSheet = 3
        case bitable = 4
        case commentInBitable = 5
        case announcement = 6
        case commentInAnnouncement = 7
        case commentInFile = 8
        case mindnote = 10
        case commentInMindnote = 11
        case slides = 31
        case commentInSlide = 13
        case docx = 22
        case oaComment = 24
        case minutes = 29
    }

    /// 构造AtDataSource 时，传入的配置
    public struct Config {
        public init(chatID: String?, sourceFileType: DocsType, location: AtViewType, token: String) {
            self.chatID = chatID
            self.sourceFileType = sourceFileType
            self.location = location
            self.token = token
        }
        /// 群的id
        var chatID: String?

        /// 文件类型，可能是sheet/doc/bitable
        var sourceFileType: DocsType

        /// 是在文件中@，还是在评论里@
        var location: AtViewType

        /// 文件的token
        var token: String
    }
}

// MARK: - 获取请求里的 source 字段
extension AtDataSource {
    var requestSource: RequestSource {
        switch location {
        case .comment : return requestSourceForComment()
        case .docs, .mindnote, .syncedBlock : return requestSourceForFile()
        case .larkDocs: return requestSourceForFile()
        case .gadget: return .oaComment
        case .minutes: return .minutes
        default:
            spaceAssertionFailure("unsupported file type")
            return .none
        }
    }

    func requestSourceForComment() -> RequestSource {
        switch sourceFileType {
        case .bitable : return .commentInBitable
        case .sheet   : return .commentInSheet
        case .doc     : return chatID != nil ? .commentInAnnouncement : .commentInDoc
        case .file    : return .commentInFile
        case .mindnote: return .commentInMindnote
        case .slides   : return .slides
        case .docX    : return .docx
        default:
            spaceAssertionFailure("unsupported file type")
            return .none
        }
    }

    func requestSourceForFile() -> RequestSource {
        switch sourceFileType {
        case .bitable : return .bitable
        case .sheet   : return .sheet
        case .doc     : return chatID != nil ? .announcement : .doc
        case .mindnote: return .mindnote
        case .docX    : return .docx
        default       :
            spaceAssertionFailure("unsupported file type")
            return .none
        }
    }
}
