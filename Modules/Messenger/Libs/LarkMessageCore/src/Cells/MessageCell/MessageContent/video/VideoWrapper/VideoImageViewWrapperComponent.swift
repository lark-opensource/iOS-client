//
//  VideoImageViewWrapperComponent.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/5/30.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkModel
import ByteWebImage
import LarkMessengerInterface
import LarkSetting

public final class VideoImageViewWrapperComponent<C: Context>: ASComponent<VideoImageViewWrapperComponent.Props, EmptyState, VideoImageViewWrapper, C> {
    final public class Props: ASComponentProps {
        // 预览图原始大小
        public var originSize: CGSize = .zero
        // 预览图最大内容宽度，兜底为线上值
        public var contentPreferMaxWidth: CGFloat = videoMaxSize.width
        // 视频时长（单位s)
        public var duration: Int32 = 0
        // 预览图信息
        public var previewImageInfo: (ImageItemSet, forceOrigin: Bool)?
        // 当前状态
        public var status: VideoViewStatus = .normal
        // 上传进度
        public var uploadProgress: Double = 0.0
        // 点击回调
        public var tapAction: VideoImageViewWrapper.TapAction?
        // 是否有权限预览
        public var permissionPreview: (Bool, ValidateResult?) = (true, nil)
        // 动态权限
        public var dynamicAuthorityEnum: DynamicAuthorityEnum = .loading
        // video所属的message
        public var message: LarkModel.Message?
        public var fetchKeyWithCryptoFG: Bool = false
    }

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        let maxSize = CGSize(width: min(props.contentPreferMaxWidth, videoMaxSize.width), height: videoMaxSize.height)
        return VideoImageViewWrapper.calculateSize(originSize: props.originSize, maxSize: maxSize, minSize: videoMinSize)
    }

    public override func update(view: VideoImageViewWrapper) {
        super.update(view: view)
        view.tapAction = props.tapAction
        if !view.handleAuthority(dynamicAuthorityEnum: props.dynamicAuthorityEnum, hasPermissionPreview: props.permissionPreview.0) {
            return
        }
        view.setDuration(props.duration)
        view.uploadProgress = props.uploadProgress
        view.setVideoPreviewSize(originSize: props.originSize, authorityAllowed: props.permissionPreview.0
                                 && props.dynamicAuthorityEnum.authorityAllowed)
        view.status = props.status
        let metric: [String: Any] = ["message_id": props.message?.id ?? "", "is_message_delete": props.message?.isDeleted ?? false]
        if let info = props.previewImageInfo {
            view.previewView.backgroundColor = .clear
            let imageSet = info.0
            let resource: LarkImageResource
            if props.fetchKeyWithCryptoFG {
                resource = imageSet.getThumbResource()
            } else {
                resource = .default(key: imageSet.getThumbKey())
            }
            view.previewView.bt.setLarkImage(with: resource,
                                             trackStart: {
                                                TrackInfo(biz: .Messenger, scene: .Chat, fromType: .media, metric: metric)
                                             },
                                             completion: { [weak view] result in
                                                 switch result {
                                                 case .success:
                                                     break
                                                 case .failure:
                                                     view?.previewView.backgroundColor = UIColor.ud.N200
                                                 }
                                             })
        }
    }

    public override func create(_ rect: CGRect) -> VideoImageViewWrapper {
        return VideoImageViewWrapper()
    }
}
