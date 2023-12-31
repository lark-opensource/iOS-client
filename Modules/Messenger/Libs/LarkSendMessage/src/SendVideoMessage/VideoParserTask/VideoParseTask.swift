//
//  VideoParseTask.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2021/4/21.
//

import Foundation
import Photos // PHAsset
import LarkSDKInterface // VideoSendSetting
import RxSwift // Observable
import LKCommonsTracker // Tracker
import LarkContainer

public final class VideoParseTask: UserResolverWrapper {
    public let userResolver: UserResolver

    public typealias VideoInfo = VideoParseInfo
    public typealias ParseError = VideoParseError

    let data: SendVideoContent
    let parser: VideoParser
    let taskID: String
    let contentID: String

    public init(userResolver: UserResolver,
                data: SendVideoContent,
                isOriginal: Bool,
                type: VideoParseType,
                transcodeService: VideoTranscodeService,
                videoSendSetting: VideoSendSetting,
                taskID: String,
                contentID: String? = nil
    ) throws {
        self.userResolver = userResolver
        self.data = data
        self.parser = try VideoParser(userResolver: userResolver,
                                      transcodeService: transcodeService,
                                      isOriginal: isOriginal,
                                      type: type,
                                      videoSendSetting: videoSendSetting)
        self.taskID = taskID
        if let contentID {
            self.contentID = contentID
        } else {
            self.contentID = SendVideoLogger.IDGenerator.contentID(for: data, origin: isOriginal)
        }
    }

    public func cancel() {
        self.parser.cancel()
    }

    /// 资源 ID
    public func resourceID() -> String {
        let id: String
        switch data {
        case .asset(let asset):
            id = VideoParser.phassetResourceID(asset: asset)
        case .fileURL(let url):
            id = url.absoluteString
        }
        if self.parser.isOriginal {
            return "origin_" + id
        } else {
            return id
        }
    }
}

extension VideoParseTask: Hashable {
    public static func == (lhs: VideoParseTask, rhs: VideoParseTask) -> Bool {
        lhs.taskID == rhs.taskID
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(taskID)
    }
}
