//
//  EmojiKeyboard.swift
//  Pods
//
//  Created by lichen on 2018/7/27.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkEmotion
import LarkContainer
import LarkEmotionKeyboard
import LarkKeyboardView

public protocol EmotionKeyboardProtocol: UIView {
    func updateActionBarEnable()
    func updateSendBtnIfNeed(hidden: Bool)
}

extension EmotionKeyboardView: EmotionKeyboardProtocol {
}

extension EmotionKeyboardView {
    public static func keyboard(iconColor: UIColor? = nil) -> KeyboardInfo {
        return KeyboardInfo(
            icon: Resources.emoji_bottombar,
            selectedIcon: Resources.emoji_bottombar_selected,
            unenableIcon: nil,
            tintColor: iconColor ?? UIColor.ud.iconN3
        )
    }
}

extension LarkKeyboard {

    public typealias DelegateBuilder<T> = () -> T?

    public enum EmotionKeyboardType {
        case emoji(DelegateBuilder<EmojiEmotionItemDelegate>)
        case sticker(DelegateBuilder<StickerEmotionSourceDelegate>)
        case stickerSet(DelegateBuilder<StickerSetEmotionSourceDelegate>)

        public static func emojiWith(_ delegate: EmojiEmotionItemDelegate) -> EmotionKeyboardType {
            return EmotionKeyboardType.emoji({ [weak delegate] () -> (EmojiEmotionItemDelegate)? in
                return delegate
            })
        }

        public static func stickerWith(_ delegate: StickerEmotionSourceDelegate) -> EmotionKeyboardType {
            return EmotionKeyboardType.sticker({ [weak delegate] () -> StickerEmotionSourceDelegate? in
                return delegate
            })
        }

        public static func stickerSetWith(_ delegate: StickerSetEmotionSourceDelegate) -> EmotionKeyboardType {
            return EmotionKeyboardType.stickerSet({ [weak delegate] () -> StickerSetEmotionSourceDelegate? in
                return delegate
            })
        }
    }

    public struct EmotionLeftViewInfo {
        public let width: CGFloat
        public let image: UIImage
        public let clickCallBack: (UIView) -> Void
        public init(width: CGFloat, image: UIImage, clickCallBack: @escaping (UIView) -> Void) {
            self.width = width
            self.image = image
            self.clickCallBack = clickCallBack
        }
    }

    public final class EmotionKeyboardConfig {
        public let selectedBlock: () -> Bool
        public let support: [EmotionKeyboardType]
        public let emotionViewCallBack: (EmotionKeyboardProtocol) -> Void
        public let actionBtnHidden: Bool
        public let iconColor: UIColor?
        public let scene: EmotionKeyboardScene
        public let chatId: String?
        public var leftViewInfo: EmotionLeftViewInfo?
        public init(
            support: [EmotionKeyboardType],
            actionBtnHidden: Bool,
            leftViewInfo: EmotionLeftViewInfo? = nil,
            iconColor: UIColor? = nil,
            chatId: String? = nil,
            scene: EmotionKeyboardScene,
            selectedBlock: @escaping () -> Bool,
            emotionViewCallBack: @escaping (EmotionKeyboardProtocol) -> Void
        ) {
            self.support = support
            self.scene = scene
            self.chatId = chatId
            self.actionBtnHidden = actionBtnHidden
            self.iconColor = iconColor
            self.selectedBlock = selectedBlock
            self.emotionViewCallBack = emotionViewCallBack
            self.leftViewInfo = leftViewInfo
        }
    }

    static public func buildEmotion(_ config: EmotionKeyboardConfig) -> InputKeyboardItem {
        return buildEmotionV2(config)
    }

    private static func buildEmotionV2(_ config: EmotionKeyboardConfig) -> InputKeyboardItem {
        let keyboardIcons: (UIImage?, UIImage?, UIImage?) = EmotionKeyboardView.keyboard(iconColor: config.iconColor).icons
        let keyboardHeight: Float = EmotionKeyboardView.keyboard().height
        let keyboardStatusChange: (UIView, Bool) ->Void = { view, isFold in
            if let emotionKeyboardView = view as? EmotionKeyboardView {
                emotionKeyboardView.keyboardStatusChange(isFold: isFold)
            }
        }
        let keyboardViewBlock = { () -> UIView in
            var emotionSources: [EmotionItemDataSourceItem] = []
            for type in config.support {
                switch type {
                case .emoji(let delegate):
                    let emojiDataSource = EmojiEmotionDataSource(
                        scene: config.scene,
                        chatId: config.chatId,
                        displayInPad: Display.pad,
                        displayHeight: Display.height)
                    emojiDataSource.delegate = delegate()
                    emotionSources.append(emojiDataSource)
                case .sticker(let delegate):
                    let stickerDataSource = StickerEmotionV2Source()
                    stickerDataSource.delegate = delegate()
                    emotionSources.append(stickerDataSource)
                case .stickerSet(let delegate):
                    let stickerSetDataSource = StickerSetEmotionSource()
                    stickerSetDataSource.delegate = delegate()
                    emotionSources.append(stickerSetDataSource)
                }
            }
            let sourceLayout = EmotionKeyboardViewConfig.getDefaultSourceLayout()
            if config.leftViewInfo == nil {
                sourceLayout.headerReferenceSize = CGSize(width: 10, height: 0)
            }
            let emotionKeyboard = EmotionKeyboardView(config: .init(backgroundColor: UIColor.ud.N100,
                                                                    cellDidSelectedColor: UIColor.ud.N300,
                                                                    sourceLayout: sourceLayout,
                                                                    actionBtnHidden: config.actionBtnHidden),
                                                      dataSources: emotionSources)
            config.emotionViewCallBack(emotionKeyboard)
            if let info = config.leftViewInfo {
                let addButton = UIButton()
                addButton.backgroundColor = .clear
                addButton.setImage(info.image, for: .normal)
                emotionKeyboard.setLeftView(view: addButton, width: info.width)
                _ = addButton.rx.tap.subscribe(onNext: { () in
                    info.clickCallBack(addButton)
                })
            }
            return emotionKeyboard
        }
        let selectedAction = config.selectedBlock
        return InputKeyboardItem(
            key: KeyboardItemKey.emotion.rawValue,
            keyboardViewBlock: keyboardViewBlock,
            keyboardHeightBlock: { keyboardHeight },
            coverSafeArea: true,
            keyboardIcon: keyboardIcons,
            keyboardStatusChange: keyboardStatusChange,
            selectedAction: selectedAction
        )
    }
}
