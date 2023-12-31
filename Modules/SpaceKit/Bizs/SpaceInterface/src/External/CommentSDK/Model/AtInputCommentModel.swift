//
//  AtInputCommentModel.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/28.
//  


import Foundation

public struct CommentContent {
    public let content: String // 文字
    public let imageInfos: [CommentImageInfo]? // 图片
    public let pcmData: Data? // 语音
    public let pcmDataTime: TimeInterval? // 时间
    public var attrContent: NSAttributedString?
    public let isAudio: Bool
    
    public init(content: String, imageInfos: [CommentImageInfo]?, pcmData: Data?, pcmDataTime: TimeInterval?, attrContent: NSAttributedString?, isAudio: Bool) {
        self.content = content
        self.imageInfos = imageInfos
        self.pcmData = pcmData
        self.pcmDataTime = pcmDataTime
        self.attrContent = attrContent
        self.isAudio = isAudio
    }
    
    
    /// 转换成前/后端需要图片字段
    /// - Parameter update: 是新增还是编辑
    public func imagesParams(update: Bool) -> [[String: Any]] {
        guard let infos = imageInfos, !infos.isEmpty else {
            return []
        }
        
        var imageList: [[String: Any]] = []
        infos.forEach { (info) in
            var imageDic: [String: Any] = ["uuid": info.uuid ?? "",
                                           "src": info.src]
            if update {
                imageDic["originalSrc"] = info.originalSrc ?? ""
                imageDic["token"] = info.token ?? ""
            }
            imageList.append(imageDic)
        }
        return imageList
    }
    
    public func imagesRNParams() -> [[String: Any]] {
        guard let infos = imageInfos, !infos.isEmpty else {
            return []
        }
        
        var imageList: [[String: Any]] = []
        infos.forEach { (info) in
            let imageDic: [String: Any] = ["uuid": info.uuid ?? "",
                                           "src": info.src,
                                           "token": info.token ?? ""]
            imageList.append(imageDic)
        }
        return imageList
    }
}
