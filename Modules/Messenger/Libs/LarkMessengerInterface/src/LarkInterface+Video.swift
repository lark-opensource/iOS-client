//
//  LarkInterface+Video.swift
//  LarkInterface
//
//  Created by kongkaikai on 2018/10/31.
//

import UIKit
import Foundation
import LarkModel
import Photos
import RxCocoa
import EENavigator
import RxSwift
import LarkSDKInterface
import RustPB
import LarkUIKit

public enum VideoSavePush {
    case downloadStart
    case downloading(Float)
    case downloadFailed
    case downloadSuccess
    case downloadSaveError
    case cryptoError
    case saveToNutInProgress
    case saveToNutFailed
    case saveToNutFailedWithMoreThanLimit
    case saveToNutSuccess
}

public struct VideoInfo {
    public let key: String
    public let authToken: String?
    public let absolutePath: String
    public let type: RustPB.Basic_V1_File.EntityType
    public let channelId: String
    public let sourceType: Message.SourceType
    public let sourceID: String
    public init(key: String,
                authToken: String?,
                absolutePath: String,
                type: RustPB.Basic_V1_File.EntityType,
                channelId: String,
                sourceType: Message.SourceType,
                sourceID: String) {
        self.key = key
        self.authToken = authToken
        self.absolutePath = absolutePath
        self.type = type
        self.channelId = channelId
        self.sourceType = sourceType
        self.sourceID = sourceID
    }
}

public protocol VideoSaveService {
    var videoSavePush: Driver<(String, VideoSavePush)> { get }
    func saveVideoToAlbum(with messageId: String,
                          asset: LKDisplayAsset,
                          info: VideoInfo,
                          riskDetectBlock: @escaping () -> Observable<Bool>,
                          from vc: UIViewController?,
                          downloadFileScene: RustPB.Media_V1_DownloadFileScene?)

    // swiftlint:disable function_parameter_count
    func saveVideoToAlbumOb(with messageId: String,
                            key: String,
                            authToken: String?,
                            absolutePath: String,
                            type: RustPB.Basic_V1_File.EntityType,
                            channelId: String,
                            sourceType: Message.SourceType,
                            sourceID: String,
                            from vc: UIViewController?,
                            downloadFileScene: RustPB.Media_V1_DownloadFileScene?)
    -> Observable<Result<Void, Error>>
    // swiftlint:enable function_parameter_count

    func saveFileToSpaceStore(messageId: String, chatId: String, key: String?, sourceType: LarkModel.Message.SourceType, sourceID: String)
    func isVideoDownloadingAndProgress(for key: String) -> (Bool, Float)
}

public struct PlayWebVideoBody: PlainBody {
    public static let pattern = "//client/playTTWebVideo"
    public let asset: Asset
    public let site: VideoSite
    public init(asset: Asset, site: VideoSite) {
        self.asset = asset
        self.site = site
    }
}
