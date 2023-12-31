//
//  PictureKeyboard.swift
//  Pods
//
//  Created by lichen on 2018/7/27.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LKCommonsTracker
import LarkAssetsBrowser
import LarkKeyboardView

extension LarkKeyboard {

    public final class PictureKeyboardConfig {
        public let selectedBlock: () -> Bool
        public weak var delegate: AssetPickerSuiteViewDelegate?
        public let photoViewCallback: (AssetPickerSuiteView) -> Void
        public let type: PhotoPickerAssetType
        /// 选择视频时，是否支持点击"原图"按钮
        public let originVideo: Bool
        public let sendButtonTitle: String
        public let isOriginalButtonHidden: Bool

        public init(
            type: PhotoPickerAssetType = PhotoPickerAssetType.default,
            delegate: AssetPickerSuiteViewDelegate?,
            selectedBlock: @escaping () -> Bool,
            photoViewCallback: @escaping (AssetPickerSuiteView) -> Void,
            originVideo: Bool = false,
            sendButtonTitle: String,
            isOriginalButtonHidden: Bool = false
            ) {
            self.type = type
            self.delegate = delegate
            self.selectedBlock = selectedBlock
            self.photoViewCallback = photoViewCallback
            self.originVideo = originVideo
            self.sendButtonTitle = sendButtonTitle
            self.isOriginalButtonHidden = isOriginalButtonHidden
        }
    }

    public static func buildPicture(_ iconColor: UIColor?, _ config: PictureKeyboardConfig) -> InputKeyboardItem {
        let keyboardInfo = PhotoPickView.keyboard(iconColor: iconColor)
        let keyboardIcons: (UIImage?, UIImage?, UIImage?) = keyboardInfo.icons
        let keyboardViewBlock = { () -> UIView in
            let pickView = AssetPickerSuiteView(assetType: config.type,
                                                originVideo: config.originVideo,
                                                cameraType: .custom(true),
                                                sendButtonTitle: config.sendButtonTitle,
                                                isOriginalButtonHidden: config.isOriginalButtonHidden)
            pickView.fromMoment = true
            pickView.updateBottomOffset(0)
            pickView.delegate = config.delegate
            pickView.imageEditAction = { Tracker.post(TeaEvent($0.event, params: $0.params ?? [:])) }
            config.photoViewCallback(pickView)
            pickView.supportVideoEditor = true
            return pickView
        }
        let selectedAction = config.selectedBlock

        return InputKeyboardItem(
            key: KeyboardItemKey.picture.rawValue,
            keyboardViewBlock: keyboardViewBlock,
            keyboardHeightBlock: { PhotoPickView.keyboard(iconColor: iconColor).height },
            keyboardIcon: keyboardIcons,
            selectedAction: selectedAction
        )
    }
}
