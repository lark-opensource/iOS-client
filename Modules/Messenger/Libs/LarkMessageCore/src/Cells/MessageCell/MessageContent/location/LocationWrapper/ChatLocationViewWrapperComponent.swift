//
//  ChatLocationViewWrapperComponent.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/23.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkSDKInterface

public struct ChatLocationConsts {

    public static var contentMaxWidth: CGFloat {
        return 400
    }

    private static var locationImageSize: CGSize {
        let height = CGFloat(90.0)
        return CGSize(width: contentMaxWidth, height: height)
    }

    private static let locationCardInnerMargin: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

    public static var setting: ChatLocationViewStyleSetting {
        return ChatLocationViewStyleSetting(
            margin: locationCardInnerMargin,
            imageSize: locationImageSize
        )
    }
}

public final class ChatLocationViewWrapperComponent<C: Context>: ASComponent<ChatLocationViewWrapperComponent.Props, EmptyState, ChatLocationViewWrapper, C> {
    final public class Props: ASComponentProps {
        /// 配置
        public var setting: ChatLocationViewStyleSetting?
        /// 地理位置名称
        public var name: String = ""
        /// 地理位置描述
        public var description: String = ""
        /// 预览图片的原始大小
        public var originSize: CGSize = .zero
        /// 设置图片回调
        public var setImageAction: ChatImageViewWrapper.SetImageType = { _, _ in }
        /// 点击卡片回调
        public var locationTappedCallback: LocationViewTappedCallback = {}
        /// 上传进度
        public var uploadProgress: Float = -1

        public var settingGifLoadConfig: GIFLoadConfig?
    }

    private var setting: ChatLocationViewStyleSetting {
        if let setting = props.setting {
            return setting
        }
        return ChatLocationConsts.setting
    }

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return ChatLocationViewWrapper.calculateSize(
            with: setting,
            containerSize: size,
            name: props.name,
            description: props.description
        )
    }

    public override func update(view: ChatLocationViewWrapper) {
        super.update(view: view)
        view.backgroundColor = UIColor.ud.bgFloat
        view.set(
            name: props.name,
            description: props.description,
            originSize: props.originSize,
            setting: props.setting ?? ChatLocationConsts.setting,
            locationTappedCallback: props.locationTappedCallback,
            setLocationViewAction: props.setImageAction,
            settingGifLoadConfig: props.settingGifLoadConfig
        )
        view.updateUploadProgress(props.uploadProgress)
    }

    public override func create(_ rect: CGRect) -> ChatLocationViewWrapper {
        return ChatLocationViewWrapper(setting: setting)
    }
}
