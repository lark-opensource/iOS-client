//
//  VideoCoverComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/9/1.
//

import Foundation
import RustPB
import LarkCore
import ByteWebImage
import CookieManager
import LarkAppConfig
import LKCommonsLogging
import TangramComponent
import TangramUIComponent
import LarkMessengerInterface

public final class VideoCoverComponentViewModel: RenderComponentBaseViewModel {
    static let logger = Logger.log(VideoCoverComponentViewModel.self, category: "DynamicURLComponent.VideoCoverComponentViewModel")

    private lazy var _component: VideoCoverComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let video = property?.video ?? .init()
        let props = buildComponentProps(componentID: componentID, property: video)
        _component = VideoCoverComponent<EmptyContext>(props: props, style: renderStyle)
    }

    private func buildComponentProps(componentID: String, property: Basic_V1_URLPreviewComponent.VideoProperty) -> VideoCoverComponentProps {
        let props = VideoCoverComponentProps()
        // https://bytedance.feishu.cn/docx/doxcnPD3B6VxLa0KW78nuE6dPBb
        var key = ImageItemSet.transform(imageSet: property.coverImage).getThumbKey()
        // 优先级：coverImage > coverImageURL
        key = (property.hasCoverImage && !key.isEmpty) ? key : property.coverImageURL
        props.setImageTask.update { [weak self] view, completion in
            view.bt.setLarkImage(
                with: .default(key: key),
                trackStart: {
                    return TrackInfo(scene: .Chat, fromType: .urlPreview)
                },
                completion: { [weak self] res in
                    guard let self = self else { return }
                    switch res {
                    case .success(let imageRes): completion?(imageRes.image, nil)
                    case .failure(let error):
                        completion?(nil, error)
                        Self.logger.error("setImage error: \(self.entity.previewID) -> \(key)")
                    @unknown default:
                        assertionFailure("unknown case")
                        completion?(nil, nil)
                    }
                }
            )
        }
        props.duration = property.duration
        props.onTap.update { [weak self] view in
            guard let self = self, let targetVC = self.dependency.targetVC else { return }
            switch property.site {
            case .douyin, .huoshan, .xigua, .youtube:
                var asset = Asset(sourceType: .image(property.coverImage))
                asset.visibleThumbnail = view
                asset.isVideo = true
                asset.videoUrl = !property.srcURL.isEmpty ? property.srcURL : (self.originURL() ?? "")
                asset.videoId = property.vid
                asset.duration = Int32(property.duration)
                let body = PlayWebVideoBody(asset: asset, site: property.site.videoSite)
                self.userResolver.navigator.present(body: body, from: targetVC)
            case .unknown:
                if !property.srcURL.isEmpty {
                    let mediaInfoItem = MediaInfoItem(key: "",
                                                      videoKey: "",
                                                      coverImage: property.coverImage,
                                                      url: "",
                                                      videoCoverUrl: "",
                                                      localPath: "",
                                                      size: 0,
                                                      messageId: "",
                                                      messageRiskObjectKeys: [],
                                                      channelId: "",
                                                      sourceId: "",
                                                      sourceType: .typeFromUnkonwn,
                                                      needAuthentication: false,
                                                      downloadFileScene: nil,
                                                      duration: Int32(property.duration),
                                                      isPCOriginVideo: false)
                    var asset = Asset(sourceType: .video(mediaInfoItem))
                    asset.videoUrl = property.srcURL
                    asset.duration = Int32(property.duration)
                    asset.visibleThumbnail = view
                    asset.isVideo = true
                    let session = self.sessionFor(url: property.srcURL)
                    let body = PreviewImagesBody(assets: [asset],
                                                 pageIndex: 0,
                                                 scene: .normal(assetPositionMap: [:], chatId: nil),
                                                 trackInfo: PreviewImageTrackInfo(scene: .Chat),
                                                 shouldDetectFile: false,
                                                 canSaveImage: false,
                                                 canShareImage: false,
                                                 canEditImage: false,
                                                 hideSavePhotoBut: true,
                                                 showSaveToCloud: false,
                                                 canTranslate: false,
                                                 translateEntityContext: (nil, .other),
                                                 session: session,
                                                 videoShowMoreButton: false)
                    self.userResolver.navigator.present(body: body, from: targetVC)
                } else if let iosURL = self.originURL(), let url = URL(string: iosURL) {
                    self.userResolver.navigator.push(url, from: targetVC)
                }
            @unknown default: assertionFailure("unknown case")
            }
            URLTracker.trackRenderClick(entity: self.entity, extraParams: self.dependency.extraTrackParams, clickType: .playVideo, componentID: componentID)
        }
        return props
    }

    private func originURL() -> String? {
        let entityURL = self.entity.url
        return entityURL.hasIos ? entityURL.ios : entityURL.url
    }

    private func sessionFor(url: String) -> String? {
        guard !url.isEmpty, let url = URL(string: url) else { return nil }
        // 视频源地址播放时需要注入session，URL中台会开放给外部使用，为了避免session泄漏，因此只对飞书域下url种session。
        // 参考图片拉取时注入cookie的逻辑：
        // 首先排除https情况（因为https安全），所以我们对于我们飞书的domin，如果是非https方式的url，则不设置cookie
        let isLarkDomain = ConfigurationManager.shared.mainDomains.contains(where: { (url.host ?? "").contains($0) })
        if isLarkDomain, (url.scheme ?? "") != "https" { return nil }
        let cookies = LarkCookieManager.shared.getCookies(url: url)
        return cookies.first(where: { $0.name == LarkCookieManager.sessionName })?.value
    }
}

extension Basic_V1_URLPreviewComponent.VideoProperty.Site {
    var videoSite: Basic_V1_PreviewVideo.Site {
        switch self {
        case .douyin: return .douyin
        case .huoshan: return .huoshan
        case .xigua: return .xigua
        case .youtube: return .youtube
        case .unknown: return .unknown
        @unknown default:
            assertionFailure("unknown case")
            return .unknown
        }
    }
}
