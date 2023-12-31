//
//  ChatImageViewWrapper.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/5/28.
//

import Foundation
import LarkUIKit
import ByteWebImage
import UIKit
import UniverseDesignColor
import LarkSetting
import LarkAssetsBrowser
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface

public final class ChatImageViewWrapper: BaseImageViewWrapper {

    private var dynamicAuthorityEnum: DynamicAuthorityEnum = .loading

    // 无预览权限时候的遮罩
    private lazy var noPermissionPreviewLayerView = NoPermissonPreviewLayerView()
    // 无预览权限时候的方形小遮罩
    private lazy var noPermissionPreviewSmallLayerView: NoPermissonPreviewSmallLayerView = {
        let view = NoPermissonPreviewSmallLayerView()
        view.tapAction = { [weak self] gesture in
            self?.imageViewDidTapped(gesture)
        }
        return view
    }()

    private var settingGifLoadConfig: LarkSDKInterface.GIFLoadConfig?

    /// 设置图片原始大小和图片设置回调
    ///
    /// - Parameters:
    ///   - originSize: 图片原始大小
    ///   - imageTappedCallback: 图片点击回调
    ///   - setImageAction: 设置图片回调
    public func set(
        isSmallPreview: Bool = false,
        originSize: CGSize,
        maxSize: CGSize? = nil,
        minSize: CGSize? = nil,
        dynamicAuthorityEnum: DynamicAuthorityEnum = .allow,
        permissionPreview: (Bool, ValidateResult?) = (true, nil),
        needLoading: Bool,
        needMask: Bool = true,
        needBackdrop: Bool = true,
        animatedDelegate: AnimatedViewDelegate?,
        forceStartIndex: Int,
        forceStartFrame: UIImage?,
        imageTappedCallback: @escaping ImageViewTappedCallback,
        setImageAction: @escaping SetImageType,
        downloadFailedLayerProvider: DownloadFailedLayerProvider? = nil,
        settingGifLoadConfig: LarkSDKInterface.GIFLoadConfig?
    ) {
        self.dynamicAuthorityEnum = dynamicAuthorityEnum
        self.settingGifLoadConfig = settingGifLoadConfig
        if permissionPreview.0 && dynamicAuthorityEnum.authorityAllowed {
            self.hideNoPreviewPermissionSmallLayer()
            self.hideNoPermissionPreviewLayer()
        } else {
            // 无权限需要借助这个事件回调
            self.imageTappedCallback = imageTappedCallback
            if isSmallPreview { self.showNoPermissionPreviewSmallLayer() } else { self.showNoPermissionPreviewLayer() }
            return
        }
        set(
            originSize: originSize,
            maxSize: maxSize,
            minSize: minSize,
            needLoading: needLoading,
            needMask: needMask,
            needBackdrop: needBackdrop,
            animatedDelegate: animatedDelegate,
            forceStartIndex: forceStartIndex,
            forceStartFrame: forceStartFrame,
            imageTappedCallback: imageTappedCallback,
            setImageAction: setImageAction,
            downloadFailedLayerProvider: downloadFailedLayerProvider
        )
    }

    override public func getGIFLoadConfig() -> GIFLoadConfig {
        guard let settingGifLoadConfig = self.settingGifLoadConfig else {
            return GIFLoadConfig()
        }
        var config = GIFLoadConfig()
        config.size = settingGifLoadConfig.size
        config.width = settingGifLoadConfig.width
        config.height = settingGifLoadConfig.height
        return config
    }
}

extension ChatImageViewWrapper {

    /// 更新图片上传进度
    ///
    /// - Parameter progress: 进度
    public func updateUploadProgress(_ progress: Float) {
        let minValue: Float = 1e-6
        if progress >= 0.0, progress < 1.0 {
            self.showProgress(
                progress: progress,
                progressType: .default,
                showType: .incomplete,
                centerYOffset: centerYOffset
            )
            if abs(progress - 1.0) <= minValue {
                self.hideProgress()
            }
        } else {
            self.hideProgress()
        }
    }

    /// 更新图片发送进度
    ///
    /// - Parameters
    ///     isShow: 是否展示
    ///     value: 进度数值
    public func updateSendProgress(_ progress: Float) {
        if progress >= SendImageProgressState.zero.rawValue,
           progress < SendImageProgressState.uploadSuccess.rawValue {
            self.showProgress(
                progress: progress,
                progressType: .default,
                showType: .incomplete,
                centerYOffset: centerYOffset
            )
        } else if (progress == SendImageProgressState.sendSuccess.rawValue) ||
                    (progress == SendImageProgressState.sendFail.rawValue) ||
                    (progress == SendImageProgressState.wait.rawValue) {
            self.hideProgress()
        }
    }

    /// show NoPermission layer
    private func showNoPermissionPreviewLayer() {
        if noPermissionPreviewLayerView.superview == nil {
            self.addSubview(noPermissionPreviewLayerView)
            noPermissionPreviewLayerView.snp.makeConstraints({ (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.height.equalToSuperview()
            })
        }
        noPermissionPreviewLayerView.isHidden = false
        noPermissionPreviewLayerView.setLayerType(dynamicAuthorityEnum: self.dynamicAuthorityEnum, previewType: .image)
    }

    /// hide NoPermission layer
    private func hideNoPermissionPreviewLayer() {
        noPermissionPreviewLayerView.isHidden = true
    }

    /// show 小showNoPermission layer
    public func showNoPermissionPreviewSmallLayer() {
        if noPermissionPreviewSmallLayerView.superview == nil {
            self.addSubview(noPermissionPreviewSmallLayerView)
            noPermissionPreviewSmallLayerView.snp.makeConstraints({ (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.height.equalToSuperview()
            })
        }
        noPermissionPreviewSmallLayerView.isHidden = false
    }

    /// hide NoPermission layer
    public func hideNoPreviewPermissionSmallLayer() {
        noPermissionPreviewSmallLayerView.isHidden = true
    }
}
