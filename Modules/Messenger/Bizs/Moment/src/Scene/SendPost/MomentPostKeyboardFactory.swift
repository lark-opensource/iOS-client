//
//  MomentPostKeyboardFactory.swift
//  Moment
//
//  Created by llb on 2021/1/4.
//

import UIKit
import Foundation
import LarkUIKit
import LarkFoundation
import RxSwift
import RxCocoa
import Photos
import EENavigator
import LarkAlertController
import LarkCore
import LarkKeyboardView
import LarkBaseKeyboard

final class MomentPostKeyboardFactory {
    static let maxImageCount: Int = 9
    static let maxVideoCount: Int = 1

    static let iconColor = UIColor.ud.iconN2
    static func buildPostAt(_ context: MomentSendPostViewController) -> InputKeyboardItem {
        return LarkKeyboard.buildAt(iconColor: Self.iconColor, selectedBlock: { [weak context] () -> Bool in
            guard let context = context else { return false }
            context.contentTextView.insertText("@")
            let selectedRange = context.contentTextView.selectedRange
            context.contentTextView.resignFirstResponder()
            context.chatInputViewInputAt(cancel: nil, complete: { [weak context] (selectItems) in
                guard let context = context else { return }
                context.contentTextView.selectedRange = selectedRange
                context.contentTextView.deleteBackward()
                selectItems.forEach({ item in
                    if !item.id.isEmpty {
                        context.insert(userName: item.name,
                                       actualName: item.actualName,
                                       userId: item.id,
                                       isOuter: item.isOuter)
                    } else {
                        context.contentTextView.insertText(item.name)
                    }
                })
                context.contentTextView.becomeFirstResponder()
            })
            return false
        })
    }

    static func buildPostPicture(_ context: MomentSendPostViewController) -> InputKeyboardItem {
        let config = LarkKeyboard.PictureKeyboardConfig(
            type: .default,
            delegate: context,
            selectedBlock: {
                return true
            },
            photoViewCallback: { [weak context] (pictureKeyboard) -> Void in
                updatePictureKeyboard(pictureKeyboard, context: context)
            },
            sendButtonTitle: BundleI18n.Moment.Lark_Legacy_Sure,
            isOriginalButtonHidden: true
        )
        return LarkKeyboard.buildPicture(Self.iconColor, config)
    }

    static func updatePictureKeyboard(_ pictureKeyboard: AssetPickerSuiteView, context: MomentSendPostViewController?) {
        pictureKeyboard.reset()
        let assetType: PhotoPickerAssetType = context?.viewModel.selectedImagesModel.photoPickerAssetType() ?? .default
        pictureKeyboard.updateAssetType(assetType)
        pictureKeyboard.reachMaxCountTipBlock = { (type) in
            return reachMaxCountTipForType(type: type)
        }
    }

    static func buildPostEmotion(_ context: MomentSendPostViewController) -> InputKeyboardItem {
        let support: [LarkKeyboard.EmotionKeyboardType] = [LarkKeyboard.EmotionKeyboardType.emojiWith(context)]
        let config = LarkKeyboard.EmotionKeyboardConfig(
            support: support,
            actionBtnHidden: true,
            iconColor: Self.iconColor,
            scene: .moments,
            selectedBlock: { () -> Bool in
                return true
            },
            emotionViewCallBack: { (_) -> Void in }
        )
        return LarkKeyboard.buildEmotion(config)
    }

    static func buildHashTag(_ context: MomentSendPostViewController) -> InputKeyboardItem {
        return LarkKeyboard.buildHashTag(iconColor: Self.iconColor) {
            [weak context] () -> Bool in
                guard let context = context else { return false }
                if context.isUrlItemBeforeSelectedRange() {
                    context.contentTextView.insertText(" #")
                } else {
                    context.contentTextView.insertText("#")
                }
                return false
        }
    }

    static func buildPostSend(_ context: MomentSendPostViewController) -> InputKeyboardItem {
        return LarkKeyboard.buildSend({ [weak context] () -> Bool in
            // 发送帖子
            context?.sendPost()
            return false
        })
    }

    static func postKeyboardLayout() -> KeyboardPanel.LayoutBlock {
        return { (_ panel: KeyboardPanel, _ keyboardIcon: UIView, _ key: String, _ index: Int) -> Void in
            let buttonSize = 32
            if key == KeyboardItemKey.send.rawValue {
                keyboardIcon.snp.makeConstraints({ make in
                    make.right.equalToSuperview().offset(-4.5)
                    make.centerY.equalToSuperview()
                    make.width.height.equalTo(buttonSize)
                })
                return
            }
            keyboardIcon.snp.makeConstraints({ make in
                make.left.equalToSuperview().offset(12 + Double(index) * 47)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(buttonSize)
            })
        }
    }

    static func postKeyboardItems(context: MomentSendPostViewController) -> [InputKeyboardItem] {
        var items: [InputKeyboardItem] = []
        items.append(self.buildPostAt(context))
        if !Utils.isiOSAppOnMacSystem {
            items.append(self.buildPostPicture(context))
        }
        items.append(self.buildPostEmotion(context))
        items.append(self.buildHashTag(context))
        items.append(self.buildPostSend(context))
        return items
    }

    static func reachMaxCountTipForType(type: PhotoPickerSelectDisableType) -> String? {
        var tip: String?
        switch type {
        case .maxImageCount:
            tip = String(format: BundleI18n.Moment.Lark_Legacy_MaxImageLimitReachedMessage, maxImageCount)
        case .maxVideoCount:
            tip = String(format: BundleI18n.Moment.Lark_Legacy_MaxVideoLimitReachedMessage, maxVideoCount)
        case .cannotMix:
            tip = String(format: BundleI18n.Moment.Lark_Legacy_SelectPhotosOrVideosError)
        case .maxAssetsCount: break
        @unknown default:
            break
        }
        return tip
    }
}
