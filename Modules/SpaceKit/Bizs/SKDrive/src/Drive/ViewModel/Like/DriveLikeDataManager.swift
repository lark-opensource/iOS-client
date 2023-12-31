//
//  DriveLikeDataManager.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/9/8.
//

import UIKit
import SwiftyJSON
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import SpaceInterface
import SKInfra

public protocol DriveLikeDataManagerDelegate: AnyObject {
    func updateLikeCount()
    func updateLikeList()
    func handleLikeFailed(code: Int)
}

enum DriveLikeStatus: Int8 {
    case unknown = -1
    case hasLiked = 0
    case notLiked = 1
}

// 点赞技术文档：https://bytedance.feishu.cn/docs/doccnSr0AjVUAGSkjzRqOwv0Uah#
class DriveLikeDataManager {

    private(set) var count: UInt = 0
    private(set) var likeStatus: DriveLikeStatus = .unknown
    private(set) var firstUserInfo: LikeUserInfo?
    private(set) var secondUserInfo: LikeUserInfo?
    private(set) var canShowCollaboratorInfo: Bool = false

    private var likesUserInfos: [LikeUserInfo] = [LikeUserInfo]()
    private let serialQueue = DispatchQueue(label: "drive.like.queue")

    private let docInfo: DocsInfo
    private let likeType: DocLikesType

    /// 获取点赞数请求
    private var likeNumberRequest: DocsRequest<JSON>?
    private var likeRequest: DocsRequest<JSON>?
    private var likeListRequest: DocsRequest<JSON>?

    weak var delegate: DriveLikeDataManagerDelegate?
    /// RN长链接口类
    private let tagPrefix = StablePushPrefix.like.rawValue
    private let messageTag: String
    private var messageBoxVersion: Int?
    private var messageBoxManager: StablePushManager?

    init(docInfo: DocsInfo, canShowCollaboratorInfo: Bool) {
        self.docInfo = docInfo
        self.likeType = .drive
        self.messageTag = tagPrefix + docInfo.objToken
        self.canShowCollaboratorInfo = canShowCollaboratorInfo
    }

    deinit {
        self.messageBoxManager?.unRegister()
        self.messageBoxManager = nil
    }

    func loadLikeData(checkReachable: Bool = true, completion: (() -> Void)? = nil) {
        if checkReachable {
            guard DocsNetStateMonitor.shared.isReachable else {
                DocsLogger.driveInfo("no need to fetch like count when no network")
                return
            }
        }
        _fetchLikesCount { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.delegate?.updateLikeCount()
            }

            self._fetchLikesList(completion: { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.delegate?.updateLikeList()
                    completion?()
                }
            })
        }
    }

    // 注册信箱长链
    // version: 信箱版本号
    private func registerMessageBox(with version: Int) {
        guard self.messageBoxManager == nil else {
            DocsLogger.driveInfo("message box already registered!")
            return
        }
        var params: [String: Any] = ["version": version]
        let extra = ["obj_type": DocsType.file.rawValue]
        params["extra"] = extra        
        let pushInfo = SKPushInfo(tag: messageTag,
                                  resourceType: StablePushPrefix.like.resourceType(),
                                  routeKey: docInfo.objToken,
                                  routeType: SKPushRouteType.token)
        self.messageBoxManager = StablePushManager(pushInfo: pushInfo, additionParams: params)
        self.messageBoxManager?.register(with: self)
        DocsLogger.driveInfo("register StablePushManager succeed!")
    }

    private func _fetchLikesCount(completion: @escaping (Bool) -> Void) {
        var params: [String: Any] = [String: Any]()
        params["token"] = docInfo.objToken
        params["refer_type"] = likeType.rawValue

        likeNumberRequest?.cancel()
        likeNumberRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.likesCount, params: params)
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .start(callbackQueue: serialQueue, result: { [weak self] (likesInfo, _) in
                guard let likesInfo = likesInfo, let self = self else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                let json = JSON(likesInfo)
                let code = json["code"].intValue
                guard code == 0 else {
                    DocsLogger.error("error code is \(code)!")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                let likeCount = json["data"]["count"].uIntValue
                self.count = likeCount
                let likeId = json["data"]["like_id"].stringValue
                if likeId.isEmpty {
                    self.likeStatus = .notLiked
                } else {
                    self.likeStatus = .hasLiked
                }
                let messageBoxVersion = json["data"]["message_box_version"].intValue
                self.messageBoxVersion = messageBoxVersion
                self.registerMessageBox(with: messageBoxVersion)
                DispatchQueue.main.async {
                    completion(true)
                }
            })
    }

    private func _fetchLikesList(completion: @escaping (Bool) -> Void) {
        var params: [String: Any] = [String: Any]()
        params["token"] = docInfo.objToken
        params["refer_type"] = likeType.rawValue
        params["last_like_id"] = "0"
        params["page_size"] = 10
        likeListRequest?.cancel()
        likeListRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.likesList, params: params)
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .start(callbackQueue: serialQueue, result: { [weak self] (likesInfo, _) in
                guard let self = self else { return }
                let code = likesInfo?["code"].int ?? DocsNetworkError.Code.invalidData.rawValue
                if code == DocsNetworkError.Code.success.rawValue {
                    if let likeData = likesInfo?["data"].dictionary {
                        self._handleLikeData(data: likeData)
                        DispatchQueue.main.async {
                            completion(true)
                        }
                    } else {
                        DocsLogger.driveInfo("invalid likeList")
                        DispatchQueue.main.async {
                            completion(false)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            })
    }

    private func _handleLikeData(data: [String: JSON]) {
        DocsLogger.debug("handleLikeData: \(data)")
        DocsLogger.driveInfo("handleLikeData", extraInfo: ["count": data["ids"]?.array?.count ?? 0])
        var likesUserDetails: [LikeUserDetails] = [LikeUserDetails]()
        if let users = data["users"]?.dictionary {
            for (_, json) in users {
                let user = LikeUserDetails.objByJson(json: json)
                likesUserDetails.append(user)
            }
        }
        // ids里面的点赞id是根据时间逆序排序的,likes里面的数据是乱序的
        if let ids = data["ids"]?.array, let likes = data["likes"]?.dictionary {
            self.likesUserInfos.removeAll()
            for idString in ids {
                if let likeId = idString.rawString(), let info = likes[likeId] {
                    self._jointLikeInfo(likesUserDetails: likesUserDetails, json: info)
                }
            }
        }
        firstUserInfo = getUserInfo(with: 0)
        secondUserInfo = getUserInfo(with: 1)
    }

    /// 拼接likes和users的数据生成完整的LikeUserInfo
    private func _jointLikeInfo(likesUserDetails: [LikeUserDetails], json: JSON) {
        let info = LikeUserInfo.objByJson(json: json)
        let matchUser = likesUserDetails.first(where: { $0.userId.elementsEqual(info.likeThisUserId) })
        if let user = matchUser {
            info.avatarURL = user.avatarUrl
            info.name = user.name
            info.allowEnterProfile = user.allowEnterProfile
            info.displayTag = user.displayTag
        }
        likesUserInfos.append(info)
    }

    func like(completion: @escaping (Bool) -> Void ) {
        var params: [String: Any] = [String: Any]()
        params["token"] = docInfo.objToken
        params["refer_type"] = likeType.rawValue

        likeStatus = .hasLiked
        likeRequest?.cancel()
        likeRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.like, params: params)
            .set(method: .POST)
            .set(encodeType: .urlEncodeDefault)
            .start(result: {[weak self] (likesInfo, err) in
                if let error = err {
                    DocsLogger.error("🐑点赞失败: \(error.localizedDescription)")
                    self?._handleLike(code: (error as NSError).code, completion: completion)
                    return
                }
                let code = likesInfo?["code"].int ?? DocsNetworkError.Code.invalidData.rawValue
                self?._handleLike(code: code, completion: completion)
            })
    }

    func dislike(completion: @escaping (Bool) -> Void) {
        var params: [String: Any] = [String: Any]()
        params["token"] = docInfo.objToken
        params["refer_type"] = likeType.rawValue

        likeStatus = .notLiked
        likeRequest?.cancel()
        likeRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.dislike, params: params)
            .set(method: .POST)
            .set(encodeType: .urlEncodeDefault)
            .start(result: {[weak self] (likesInfo, err) in
                if let error = err {
                    DocsLogger.error("🐑取赞失败: \(error.localizedDescription)")
                    self?._handleLike(code: (error as NSError).code, completion: completion)
                    return
                }
                let code = likesInfo?["code"].int ?? DocsNetworkError.Code.invalidData.rawValue
                self?._handleLike(code: code, completion: completion)
            })
    }
    
    func update(canShowCollaboratorInfo: Bool) {
        self.canShowCollaboratorInfo = canShowCollaboratorInfo
    }

    private func _handleLike(code: Int, completion: (Bool) -> Void) {
        guard code == 0 else {
            DocsLogger.driveInfo("🐑handle like failed: \(code)")
            completion(false)
            delegate?.handleLikeFailed(code: code)
            return
        }
        DocsLogger.driveInfo("🐑handle like succeed")
        completion(true)
        loadLikeData()
    }

    func getUserInfo(with index: Int) -> LikeUserInfo? {
        guard index >= 0, index < self.likesUserInfos.count else {
            DocsLogger.error("index: \(index) is out of bounds!")
            return nil
        }
        return self.likesUserInfos[index]
    }
}

// 信箱长链推送
extension DriveLikeDataManager: StablePushManagerDelegate {
    func stablePushManager(_ manager: StablePushManagerProtocol,
                           didReceivedData data: [String: Any],
                           forServiceType type: String,
                           andTag tag: String) {
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            let rawJson = JSON(data)
            let operation = rawJson["operation"].stringValue
            guard operation == self.messageTag else {
                DocsLogger.driveInfo("Unable to process this operation!")
                return
            }
            let jsonString = rawJson["body"]["data"].stringValue
            let json = JSON(parseJSON: jsonString)["data"]
            self.handleResponseData(with: json)
        }
    }

    private func handleResponseData(with json: JSON) {
        // 更新点赞数目
        let count = json["count"].uIntValue
        self.count = count

        // 更新点赞状态
        /// 根据推送的 user_id、is_like 字段，判断当前用户是否点赞。
        /// 当 user_id 等于当前用户 ID 时，is_like 表示当前用户是否点赞；否则不改变当前用户的点赞状态
        let likeThisUserId = json["user_id"].stringValue
        if User.current.info?.userID == likeThisUserId {
            let isLiked = json["is_liked"].intValue
            if isLiked == 1 {
                self.likeStatus = .hasLiked
            } else if isLiked == 0 {
                self.likeStatus = .notLiked
            } else {
                DocsLogger.driveInfo("isLiked is non-compliant!")
                self.likeStatus = .unknown
            }
        }

        // 更新点赞用户详情
        /// 后端保证逆序
        let aheadUsers = json["ahead_users"].arrayValue
        self.likesUserInfos.removeAll()
        aheadUsers.forEach { (json) in
            let info = LikeUserInfo.objByMessageResponseJson(json)
            self.likesUserInfos.append(info)
        }
        firstUserInfo = getUserInfo(with: 0)
        secondUserInfo = getUserInfo(with: 1)

        DispatchQueue.main.async {
            self.delegate?.updateLikeCount()
            self.delegate?.updateLikeList()
        }
    }
}

// 单测使用
extension DriveLikeDataManager {
    
    func forceLoadLikeData(completion: (() -> Void)? = nil) {
        loadLikeData(checkReachable: false, completion: completion)
    }
}
