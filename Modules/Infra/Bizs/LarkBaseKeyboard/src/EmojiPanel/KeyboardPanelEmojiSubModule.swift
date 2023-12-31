//
//  KeyboardPanelEmojiSubModule.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/3/17.
//

import UIKit
import LarkOpenKeyboard
import LarkKeyboardView
import LarkEmotionKeyboard
import LarkContainer
import RustPB
import RxSwift
import RxCocoa
import EditTextView
import ByteWebImage
import AppReciableSDK

/// IM中会注入默认实现
public protocol KeyboardPanelEmojiPanelItemService {
    func allStickerSetItems() -> [RustPB.Im_V1_StickerSet]
    func stickerSetReloadDriver() -> Driver<Void>
    func allStickerItems() -> [RustPB.Im_V1_Sticker]
    func stickerReloadDriver() -> Driver<Void>
    func clickNewStickersButton(from: UIViewController)
    func clickStickerSetting(from: UIViewController)
    func pushEmotionShopListVC(from: UIViewController)
    func updateRecentlyUsedReaction(emojiKey: String)
    /// 业务放可以根据需求设置TrackId, sence
    func setTrackInfo(id: String, sence: Scene)
}
/**
 EmojiSubModule 需要自己称创建paneItem
 即重写 didCreatePanelItem() 即可
 */
open class KeyboardPanelEmojiSubModule<C:KeyboardContext, M:KeyboardMetaModel>: BaseKeyboardPanelDefaultSubModule<C, M>,
                                        EmojiEmotionItemDelegate,
                                        StickerEmotionSourceDelegate,
                                        StickerSetEmotionSourceDelegate {

    open override var panelItemKey: KeyboardItemKey {
        return .emotion
    }

    open override class var name: String {
        return "KeyboardPanelEmojiSubModule"
    }

    /// 内部打印日志使用
    open var trackInfo: (logId: String, sence: Scene) {
        assertionFailure("need to be override")
        return ("", .Unknown)
    }

    open lazy var itemServiceImp: KeyboardPanelEmojiPanelItemService? = {
        let imp = self.context.resolver.resolve(KeyboardPanelEmojiPanelItemService.self)
        imp?.setTrackInfo(id: trackInfo.logId, sence: trackInfo.sence)
        return imp
    }()

    var inputTextView: LarkEditTextView {
        return self.context.inputTextView
    }

    /// EmojiEmotionItemDelegate
    open func emojiEmotionInputViewDidTapBackspace() {
        var range = self.inputTextView.selectedRange
        if range.length == 0 {
            range.length = 1
            range.location -= 1
        }
        /// 只要不是false 都需要删除 即使nil
        if self.context.inputProtocolSet?.textView(self.inputTextView, shouldChangeTextIn: range, replacementText: "") != false {
            self.inputTextView.deleteBackward()
        }
    }

    /// 是否可以点击发送键
    open func emojiEmotionActionEnable() -> Bool {
        !self.context.inputTextView.attributedText.string.isEmpty
    }

    open func isKeyboardNewStyleEnable() -> Bool {
        return KeyboardDisplayStyleManager.isNewKeyboadStyle()
    }

    open func switchEmojiSuccess() {
    }

    /// 默认值
    open func supportSkinTones() -> Bool {
        true
    }

    open func supportMultiSkin() -> Bool {
        true
    }

    open func supportRecentUsed() -> Bool {
        true
    }

    open func supportMRU() -> Bool {
        true
    }

    open func emojiEmotionInputViewDidTapCell(emojiKey: String) {
        KeyboardViewInputTool.insertEmojiForTextView(inputTextView,
                                                    inputProtocolSet: context.inputProtocolSet,
                                                    emojiKey: emojiKey)
        self.itemServiceImp?.updateRecentlyUsedReaction(emojiKey: emojiKey)
    }

    /// StickerEmotionSourceDelegate & StickerSetEmotionSourceDelegate
    open func clickNewStickersButton() {
        itemServiceImp?.clickNewStickersButton(from: context.displayVC)
    }

    open func allStickerItems() -> [RustPB.Im_V1_Sticker] {
         return itemServiceImp?.allStickerItems() ?? []
    }

    open func stickerReloadDriver() -> RxCocoa.Driver<Void> {
        return itemServiceImp?.stickerReloadDriver() ?? .just(())
    }

    open func switchStickerSuccess() {
    }

    open func allStickerSetItems() -> [RustPB.Im_V1_StickerSet] {
        return itemServiceImp?.allStickerSetItems() ?? []
    }

    open func stickerSetReloadDriver() -> RxCocoa.Driver<Void> {
        return itemServiceImp?.stickerSetReloadDriver() ?? .just(())
    }
    
    open func clickStickerSetting() {
        itemServiceImp?.clickStickerSetting(from: context.displayVC)
    }

    open func sendSticker(_ sticker: RustPB.Im_V1_Sticker, stickersCount: Int) {
        var sticker = sticker
        if sticker.image.origin.width == 0 ||
            sticker.image.origin.height == 0 {
            let resource = LarkImageResource.sticker(key: sticker.image.origin.key, stickerSetID: sticker.stickerSetID)
            guard let image = LarkImageService.shared.image(with: resource) else {
                return
            }
            // 获取 sticker image size，并且转化为 scale 为 1 时候的宽高
            sticker.image.origin.width = Int32(image.size.width * image.scale)
            sticker.image.origin.height = Int32(image.size.height * image.scale)
        }
        didSendUpdatedSticker(sticker, stickersCount: stickersCount)
    }

    open func didSendUpdatedSticker(_ sticker: Im_V1_Sticker, stickersCount: Int) {
    }

    open func emojiEmotionInputViewDidTapSend() {
    }
}
