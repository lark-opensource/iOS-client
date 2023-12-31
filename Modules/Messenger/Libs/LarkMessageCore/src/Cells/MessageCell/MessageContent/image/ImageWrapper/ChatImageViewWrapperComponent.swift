//
//  ChatImageViewWrapperComponent.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/5/29.
//

import Foundation
import AsyncComponent
import EEFlexiable
import ByteWebImage
import UIKit
import LarkMessengerInterface
import LarkUIKit
import LarkSDKInterface

public final class ChatImageViewWrapperComponent<C: Context>: ASComponent<ChatImageViewWrapperComponent.Props, EmptyState, ChatImageViewWrapper, C> {
    final public class Props: ASComponentProps {
        private var unfairLock = os_unfair_lock_s()
        // 是否有预览权限
        public var previewPermission: (Bool, ValidateResult?) = (true, nil)
        // 动态权限
        public var dynamicAuthorityEnum: DynamicAuthorityEnum = .loading
        public var isSmallPreview: Bool = false
        // 图片原始大小
        public var originSize: CGSize = .zero
        // 设置图片回调
        private var _setImageAction: ChatImageViewWrapper.SetImageType = { _, _ in }
        // 添加锁，对self的计数保护，防止多线程同时读写导致崩溃
        public var setImageAction: ChatImageViewWrapper.SetImageType {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _setImageAction
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _setImageAction = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        // 图片点击事件
        private var _imageTappedCallback: ChatImageViewWrapper.ImageViewTappedCallback = { _ in }
        public var imageTappedCallback: ChatImageViewWrapper.ImageViewTappedCallback {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _imageTappedCallback
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _imageTappedCallback = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        // 是否展示进度
        public var isShowProgress = true
        /// 发送进度(包含上传和发消息)
        public var sendProgress: Float = SendImageProgressState.zero.rawValue
        // 是否要开始动画（主要针对gif）
        public var shouldAnimating: Bool = true

        public var needShowLoading: Bool = true

        /// 暗黑模式下，对图片加mask
        public var needMask: Bool = true

        /// 是否对图片加默认的白色背景（为了在暗黑下看清透明底的图）
        public var needBackdrop: Bool = true

        public var imageMaxSize = BaseImageView.Cons.imageMaxDisplaySize

        public var imageMinSize = BaseImageView.Cons.imageMinDisplaySize

        public weak var animatedDelegate: AnimatedViewDelegate?

        private var _getGifCurrentIndex: (() -> Int)?
        public var getGifCurrentIndex: (() -> Int)? {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _getGifCurrentIndex
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _getGifCurrentIndex = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }

        private var _getGifCurrentFrame: (() -> UIImage?)?
        public var getGifCurrentFrame: (() -> UIImage?)? {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _getGifCurrentFrame
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _getGifCurrentFrame = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        public var settingGifLoadConfig: GIFLoadConfig?
    }

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return ChatImageViewWrapper.calculateSize(originSize: props.originSize,
                                                  maxSize: props.imageMaxSize,
                                                  minSize: props.imageMinSize)
    }

    public override func update(view: ChatImageViewWrapper) {
        super.update(view: view)
        view.set(
            isSmallPreview: props.isSmallPreview,
            originSize: props.originSize,
            maxSize: props.imageMaxSize,
            minSize: props.imageMinSize,
            dynamicAuthorityEnum: props.dynamicAuthorityEnum,
            permissionPreview: props.previewPermission,
            needLoading: props.needShowLoading,
            needMask: props.needMask,
            needBackdrop: props.needBackdrop,
            animatedDelegate: props.animatedDelegate,
            forceStartIndex: props.getGifCurrentIndex?() ?? 0,
            forceStartFrame: props.getGifCurrentFrame?(),
            imageTappedCallback: props.imageTappedCallback,
            setImageAction: props.setImageAction,
            settingGifLoadConfig: props.settingGifLoadConfig
        )
        if props.isShowProgress {
            view.updateSendProgress(props.sendProgress)
        }
        view.toggleAnimation(props.shouldAnimating)
    }

    public override func create(_ rect: CGRect) -> ChatImageViewWrapper {
        return ChatImageViewWrapper(maxSize: props.imageMaxSize, minSize: props.imageMinSize)
    }
}
