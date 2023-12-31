//
//  MomentsKeyboardFactory.swift
//  Moment
//
//  Created by liluobin on 2021/1/7.
//

import UIKit
import Foundation
import LarkCore
import LarkKeyboardView
import LarkBaseKeyboard

struct MomentsKeyboardFactory {
    static let iconColor = UIColor.ud.iconN2
    static let maxImageCount = 1

    static func buildAt(_ context: MomentsKeyboard) -> InputKeyboardItem {
        return LarkKeyboard.buildAt(iconColor: Self.iconColor, selectedBlock: { [weak context] () -> Bool in
            guard let context = context else { return false }
            context.keyboardView.inputTextView.insertText("@")
            let selectedRange = context.keyboardView.inputTextView.selectedRange
            context.inputTextViewInputAt(cancel: nil, complete: { [weak context] (selectItems) in
                guard let context = context else { return }
                context.keyboardView.inputTextView.selectedRange = selectedRange
                context.keyboardView.inputTextView.deleteBackward()
                selectItems.forEach({ item in
                    switch item {
                    case .chatter(let item):
                        context.keyboardView.insert(userName: item.name,
                                                    actualName: item.actualName,
                                                    userId: item.id,
                                                    isOuter: item.isOuter)
                    case .doc(let url), .wiki(let url):
                        _ = url
                        assertionFailure("error entrance, current not support")
                    }
                })
            })
            return false
        })
    }

    static func buildEmotion(_ context: MomentsKeyboard) -> InputKeyboardItem {
        let support: [LarkKeyboard.EmotionKeyboardType] = [LarkKeyboard.EmotionKeyboardType.emojiWith(context)]
        let config = LarkKeyboard.EmotionKeyboardConfig(
            support: support,
            actionBtnHidden: false,
            iconColor: Self.iconColor,
            scene: .moments,
            selectedBlock: { [weak context] () -> Bool in
                context?.delegate?.emojiClick()
                return true
            },
            emotionViewCallBack: { [weak context] (emotionKeyboard) -> Void in
                context?.emotionKeyboard = emotionKeyboard
            }
        )
        return LarkKeyboard.buildEmotion(config)
    }

    static func buildPicture(_ context: MomentsKeyboard) -> InputKeyboardItem {
        /// 评论的回复支持一张图片
        let config = LarkKeyboard.PictureKeyboardConfig(
            type: PhotoPickerAssetType.imageOnly(maxCount: maxImageCount),
            delegate: context,
            selectedBlock: { [weak context] () -> Bool in
                context?.delegate?.pictureClick()
                context?.delegate?.handleKeyboardAppear()
                context?.pictureKeyboard?.reset()
                let assetType = context?.viewModel.photoPickerAssetType() ?? .imageOnly(maxCount: maxImageCount)
                context?.pictureKeyboard?.updateAssetType(assetType)
                return true
            },
            photoViewCallback: { [weak context] (pictureKeyboard) -> Void in
                context?.pictureKeyboard = pictureKeyboard
                updatePictureKeyboardMaxTip(pictureKeyboard)
            },
            sendButtonTitle: BundleI18n.Moment.Lark_Legacy_Sure,
            isOriginalButtonHidden: true
        )
        return LarkKeyboard.buildPicture(Self.iconColor, config)
    }

    private static func updatePictureKeyboardMaxTip(_ pictureKeyboard: AssetPickerSuiteView) {
        pictureKeyboard.reachMaxCountTipBlock = { (type) in
            var tip: String?
            switch type {
            case .maxImageCount:
                tip = String(format: BundleI18n.Moment.Lark_Legacy_MaxImageLimitReachedMessage, maxImageCount)
            case .cannotMix, .maxVideoCount, .maxAssetsCount: break
            @unknown default:
                break
            }
            return tip
        }
    }
}
