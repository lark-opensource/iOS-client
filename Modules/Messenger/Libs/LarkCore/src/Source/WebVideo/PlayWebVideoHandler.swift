//
//  PlayWebVideoHandler.swift
//  LarkCore
//
//  Created by zc09v on 2019/6/5.
//

import Foundation
import LarkMessengerInterface
import EENavigator
import Swinject
import LarkUIKit
import ByteWebImage
import LarkAssetsBrowser
import LarkImageEditor
import LarkNavigator

final class PlayWebVideoHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }

    public func handle(_ body: PlayWebVideoBody, req: Request, res: Response) throws {
        switch body.site {
        case .unknown, .qq, .youku, .iqiyi:
            break
        case .xigua, .douyin, .huoshan:
            let asset = body.asset.transform()
            let controller = LKAssetBrowserViewController(
                assets: [asset],
                pageIndex: 0)
            controller.longPressEnable = false
            controller.videoShowMoreButton = false
            controller.isLoadMoreEnabled = false
            controller.isSavePhotoButtonHidden = true

            controller.videoPlayProxyFactory = { [userResolver] in
                try userResolver.resolve(assert: LKVideoDisplayViewProxy.self, arguments: String?.none, true)
            }
            controller.prepareAssetInfo = { displayAsset in
                let sourceType = (displayAsset.extraInfo[ImageAssetExtraInfo] as? LKImageAssetSourceType) ?? .other
                switch sourceType {
                case .image(let imageSet):
                    let key = ImageItemSet.transform(imageSet: imageSet).generateImageMessageKey(forceOrigin: true)
                    let resource = LarkImageResource.default(key: key)
                    return (resource, nil, TrackInfo(scene: .Chat, isOrigin: true, fromType: .media))
                default:
                    let resource = LarkImageResource.default(key: displayAsset.originalUrl)
                    return (resource, nil, TrackInfo(scene: .Chat, isOrigin: true, fromType: .media))
                }
            }
            res.end(resource: controller)
        case .youtube:
            if let visibleThumbnail = body.asset.visibleThumbnail {
                let browser = LKYoutubeVideoBrowser(videoId: body.asset.videoId, fromThumbnail: visibleThumbnail)
                res.end(resource: browser)
            } else {
                res.end(error: nil)
            }
        @unknown default:
            assert(false, "new value")
            break
        }
    }
}
