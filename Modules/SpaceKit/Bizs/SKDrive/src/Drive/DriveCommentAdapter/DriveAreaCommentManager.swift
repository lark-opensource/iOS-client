//
//  DriveAreaCommentManager.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/6/20.
//

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import SpaceInterface
import SKInfra

protocol DriveAreaCommentManagerDelegate: AnyObject {
    func commentsDataUpdated(_ rnCommentData: RNCommentData, areas: [DriveAreaComment])
    func areasCommentsDataFirstUpdated()
}

extension DriveAreaCommentManagerDelegate {
    func commentsDataUpdated(_ rnCommentData: RNCommentData) {
        // do nothing
    }
    func areaCommentsUpdated(_ areas: [DriveAreaComment]) {
        // do nothing
    }
}
class DriveAreaCommentManager {
    weak var delegate: DriveAreaCommentManagerDelegate?
    private(set) var filteredAreaComments = [DriveAreaComment]()
    private(set) var filteredRNCommentData = RNCommentData()
    private var originComments: RNCommentData?
    private(set) var areaComments = [String: DriveAreaComment]()
    private var areaCommentsRequest: DocsRequest<JSON>?
    /// 长链推送时请求坐标信息的request
    private var commentAreaRequest = WikiMultiRequest<String, JSON>(onConflict: .resend)
    private var addAreaRequest: DocsRequest<JSON>?
    private var pushManager: CommonPushDataManager
    private var fileToken: String
    private var version: String?
    private var isFirstAreasUpdate = true
    /// 是否需要加载文件所有历史版本的评论
    private var shouldLoadAllComments = false
    
    init(fileToken: String, version: String?, docsType: DocsType) {
        self.fileToken = fileToken
        self.version = version
        self.pushManager = CommonPushDataManager(fileToken: fileToken,
                                                 type: docsType,
                                                 operation: .driveCommonPushChannel)
        self.pushManager.register()
        self.pushManager.delegate = self
    }
    deinit {
        DocsLogger.debug("DriveAreaCommentManager-deinit")
        pushManager.unRegister()
    }
    
    func updateComments(_ commentsData: RNCommentData) -> (rnData: RNCommentData, areaData: [DriveAreaComment]) {
        DocsLogger.driveInfo("updateComments", extraInfo: ["version": version ?? ""])
        originComments = commentsData
        (filteredRNCommentData, filteredAreaComments) = filterComments()
        DocsLogger.debug("updateComments", extraInfo: ["filterAreaCommentCount": filteredAreaComments.count])
        return (filteredRNCommentData, filteredAreaComments)
    }

    func rnCommentsIndex(of commentID: String) -> Int? {
        var index: Int?
        for (i, item) in filteredRNCommentData.comments.enumerated() where item.commentID == commentID {
            index = i
        }
        return index
    }
    
    func update(fileToken: String, version: String?, docsType: DocsType) {
        if self.fileToken != fileToken {
            reset(fileChanged: true)
            self.pushManager = CommonPushDataManager(fileToken: fileToken, type: docsType, operation: .driveCommonPushChannel)
            self.pushManager.register()
            self.pushManager.delegate = self
        } else if self.version != version {
            reset(fileChanged: false)
        }
        self.fileToken = fileToken
        self.version = version
    }
    
    /// 加载文件所有版本的评论（目前仅 WPS 文件的预览情况使用）
    func loadAllVersionComments() {
        shouldLoadAllComments = true
        requestAreaComments()
    }
    
    private func reset(fileChanged: Bool = true) {
        if fileChanged { // 不是同一个文件才需要重置中台评论数据
            DocsLogger.debug("reset fileChanged")
            filteredRNCommentData = RNCommentData()
            originComments = nil
        }
        DocsLogger.debug("reset file not Changed")
        filteredAreaComments.removeAll()
        areaComments.removeAll()
    }
    
    private func updateAreaComments(areaComments: [DriveAreaComment]) -> (rnData: RNCommentData, areaData: [DriveAreaComment]) {
        DocsLogger.driveInfo("updateAreaComments", extraInfo: ["version": version ?? ""])
        if shouldLoadAllComments {
            areaComments.forEach { self.areaComments[$0.commentID] = $0 }
        } else {
            for item in areaComments {
                if let curVersion = version,
                   let commentVersion = item.version,
                   curVersion == commentVersion {
                    self.areaComments[item.commentID] = item
                }
            }
        }
        (filteredRNCommentData, filteredAreaComments) = filterComments()
        DocsLogger.debug("updateAreaComments", extraInfo: ["filterAreaCommentCount": filteredAreaComments.count])
        return (filteredRNCommentData, filteredAreaComments)
    }

}

// MARK: - Request
extension DriveAreaCommentManager {
    func requestAreaComments() {
        guard let v = version else {
            DocsLogger.driveInfo("NO version will not request Area Comments")
            return
        }
        var params: [String: Any] = [String: Any]()
        params["file_token"] = fileToken
        if !shouldLoadAllComments {
            // 不需要加载所有版本评论，则配置上 version 信息
            params["version"] = v
        }
        areaCommentsRequest?.cancel()
        areaCommentsRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.areaComments, params: params)
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .set(needVerifyData: false)
            .start(result: {[weak self] (result, error) in
                guard let self = self else { return }
                guard let json = result, let code = json["code"].int, error == nil else {
                    DocsLogger.error("requestAreaComments error: \(String(describing: error?.localizedDescription))")
                    return
                }
                if code == 0 {
                    if let dataArray = json["data"].arrayObject {
                        var areas = [DriveAreaComment]()
                        for item in dataArray {
                            if let itemData = try? JSONSerialization.data(withJSONObject: item, options: []),
                                let area = try? JSONDecoder().decode(DriveAreaComment.self, from: itemData) {
                                areas.append(area)
                            } else {
                                if let dic = item as? [String: Any], let commentID = dic["comment_id"] as? String {
                                    DocsLogger.error("area comment decode failed", extraInfo: ["comment_id": commentID])
                                } else {
                                    DocsLogger.error("area comment decode failed: invalid data")
                                }
                            }
                        }
                        DocsLogger.driveInfo("requestAreaComments areas count: \(areas.count)")
                        let commentData = self.updateAreaComments(areaComments: areas)
                        self.delegate?.commentsDataUpdated(commentData.rnData, areas: commentData.areaData)
                        if self.isFirstAreasUpdate {
                            self.isFirstAreasUpdate = false
                            self.delegate?.areasCommentsDataFirstUpdated()
                        }
                    } else {
                        DocsLogger.error("invalid data")
                    }
                } else {
                    DocsLogger.error("requestAreaComments code: \(code)")
                }
            })
    }

    func addAreaComment(area: DriveAreaComment, complete: @escaping (RNCommentData?, Error?) -> Void) {
        guard let data = try? JSONEncoder().encode(area),
            let areaDic = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
                let error = NSError(domain: "drive", code: 0, userInfo: [NSLocalizedDescriptionKey: "Encode Parameters Failed"])
                complete(nil, error)
                return
        }
        var params = [String: Any]()
        var extra = [String: Any]()
        extra["drive_area_coordinate"] = areaDic["drive_area_coordinate"]
        params["version"] = areaDic["version"]
        params["comment_id"] = areaDic["comment_id"]
        params["extra"] = extra
        params["file_token"] = fileToken

        addAreaRequest?.cancel()
        addAreaRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.addAreaComment, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .start(result: {[weak self] (result, error) in
                guard let self = self else { return }
                guard let json = result,
                    let code = json["code"].int,
                    error == nil else {
                        DocsLogger.error("addAreaComment error: \(String(describing: error?.localizedDescription))")
                        complete(nil, error)
                        return
                }
                if code == 0 {
                    let data = self.updateAreaComments(areaComments: [area])
                    self.delegate?.commentsDataUpdated(data.rnData, areas: data.areaData)
                    complete(data.rnData, nil)
                } else {
                    DocsLogger.error("addAreaComment error code: \(code)")
                    let err = error ?? NSError(domain: "drive", code: code, userInfo: [NSLocalizedDescriptionKey: "Unknow Error"])
                    complete(nil, err)
                }
            })
    }
}

// MARK: - Helper
extension DriveAreaCommentManager {
    private func filterComments() -> (RNCommentData, [DriveAreaComment]) {
        guard let originData = originComments else {
            return (RNCommentData(), [])
        }
        var areas = [DriveAreaComment]()
        let commentsData = RNCommentData()
        commentsData.code = originData.code
        commentsData.msg = originData.msg
        commentsData.currentCommentID = originData.currentCommentID
        for item in originData.comments {
            if var area = areaComments[item.commentID] {
                area.createTimeStamp = item.commentList.first?.createTimeStamp ?? 0
                area.comment = item
                /// 历史数据洗数据，没有选区的数据都洗成blankArea
                if area.region == nil {
                    area.region = DriveAreaComment.Area.blankArea
                }
                areas.append(area)
            }
        }
        let sortedAreas = sortAreas(areas)
        var sortedComments = [Comment]()
        for area in sortedAreas {
            if let comment = area.comment {
                sortedComments.append(comment)
            }
        }
        commentsData.comments = sortedComments
        return (commentsData, sortedAreas)
    }

    private func sortAreas(_ areas: [DriveAreaComment]) -> [DriveAreaComment] {
        guard areas.count > 0 else {
            return [DriveAreaComment]()
        }
        return sortAreasCore(areas)
    }

    // 排序规则，需要修改 cc @liweiye @zhuangyizhong
    // PDF排序逻辑: 页码 > 评论类型(文字/选区 > 单页/历史数据) > top > left > 创建时间
    // 图片排序逻辑: 评论类型(选区 > noArea/历史数据) > top > left > 创建时间
    private func sortAreasCore(_ areas: [DriveAreaComment]) -> [DriveAreaComment] {
        let areaComments = areas.sorted { (commentA, commentB) -> Bool in
            guard let regionA = commentA.region, let regionB = commentB.region else {
                return commentA.createTimeStamp < commentB.createTimeStamp
            }
            if regionA.page == regionB.page {
                if commentA.type.noArea {
                    if commentB.type.noArea {
                        return commentA.createTimeStamp < commentB.createTimeStamp
                    } else {
                        return false
                    }
                } else {
                    if commentB.type.noArea {
                        return true
                    } else {
                        if regionA.originY == regionB.originY &&
                            regionA.originX == regionB.originX {
                            return commentA.createTimeStamp < commentB.createTimeStamp
                        } else if regionA.originY == regionB.originY {
                            return regionA.originX < regionB.originX
                        } else {
                            return regionA.originY < regionB.originY
                        }
                    }
                }
            } else {
                return regionA.page < regionB.page
            }
        }
        return areaComments
    }
}

extension DriveAreaCommentManager: CommonPushDataDelegate {
    func didReceiveData(response: [String: Any]) {
        guard let data = response["data"] as? [String: Any],
            let type = data["type"] as? String,
            type == "areaCommentAdd",
            let commentAreaDic = data["data"] as? [String: Any] else {
                DocsLogger.debug("No areaCommentAdd data")
                return
        }
        DocsLogger.driveInfo("DriveAreaComment did Recevie area comment push")
        if let commentAreaData = try? JSONSerialization.data(withJSONObject: commentAreaDic, options: []),
            let commentArea = try? JSONDecoder().decode(DriveAreaComment.self, from: commentAreaData) {
            updateCommentArea(commentArea)
        }
    }

    private func updateCommentArea(_ commentArea: DriveAreaComment) {
        self.commentsDataUpdated([commentArea])
    }

    private func commentsDataUpdated(_ areaComments: [DriveAreaComment]) {
        let updatedData = updateAreaComments(areaComments: areaComments)
        delegate?.commentsDataUpdated(updatedData.rnData, areas: updatedData.areaData)
    }
}
