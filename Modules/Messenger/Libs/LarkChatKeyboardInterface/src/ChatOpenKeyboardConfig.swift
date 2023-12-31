//
//  ChatOpenKeyboardConfig.swift
//  LarkChatOpenKeyboard
//
//  Created by liluobin on 2023/5/18.
//

import UIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkKeyboardView
import LarkOpenChat
import LarkSendMessage
import RustPB
import LarkMessengerInterface
import EENavigator
import LarkSDKInterface

open class KeyboardUIConfig {
    public let tappedBlock: (() -> Void)?
    public init(tappedBlock: (() -> Void)?) {
        self.tappedBlock = tappedBlock
    }
}

open class KeyboardSendConfig {}

public protocol ChatKeyboardItemTypeProtocol: AnyObject {
    var key: KeyboardItemKey { get }
}

open class ChatKeyboardItemConfig<U: KeyboardUIConfig, S: KeyboardSendConfig>: ChatKeyboardItemTypeProtocol {

    open var key: KeyboardItemKey {
        return .unknown
    }

    public let uiConfig: U?

    public let sendConfig: S?

    public init(uiConfig: U?,
                sendConfig: S?) {
        self.uiConfig = uiConfig
        self.sendConfig = sendConfig
    }
}

/// -------------- 语音面板控制参数 ---------------------
public class KeyboardVoiceUIConfig: KeyboardUIConfig {
    /// 是否支持语音转文字 & 语音+文字
    public let supprtVoiceToText: Bool
    public init(supprtVoiceToText: Bool,
                tappedBlock: (() -> Void)? = nil) {
        self.supprtVoiceToText = supprtVoiceToText
        super.init(tappedBlock: tappedBlock)
    }
}

public protocol KeyboardAudioItemSendService: AnyObject {
    func sendAudio(audio: AudioDataInfo, parentMessage: Message?, chatId: String, lastMessagePosition: Int32?, quasiMsgCreateByNative: Bool)

    func sendAudio(audioInfo: StreamAudioInfo, parentMessage: Message?, chatId: String)

    func sendText(content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  parentMessage: Message?,
                  chatId: String,
                  position: Int32,
                  quasiMsgCreateByNative: Bool,
                  callback: ((SendMessageState) -> Void)?)

}

public class KeyboardVoiceSendConfig: KeyboardSendConfig {

    public let sendService: KeyboardAudioItemSendService?

    public init(sendService: KeyboardAudioItemSendService?) {
        self.sendService = sendService
    }
}

public class ChatKeyboardVoiceItemConfig: ChatKeyboardItemConfig<KeyboardVoiceUIConfig, KeyboardVoiceSendConfig> {

    public override var key: KeyboardItemKey {
        return .voice
    }

    public var sendService: KeyboardAudioItemSendService? {
        return self.sendConfig?.sendService
    }
}

/// ------------------- emoji面板控制参数 ------------------
public class KeyboardEmojiUIConfig: KeyboardUIConfig {

    public let supportSticker: Bool

    public init(supportSticker: Bool,
                tappedBlock: (() -> Void)? = nil) {
        self.supportSticker = supportSticker
        super.init(tappedBlock: tappedBlock)
    }
}

public protocol KeyboardEmojiItemSendService: AnyObject {
    func sendSticker(sticker: RustPB.Im_V1_Sticker, parentMessage: Message?, chat: Chat, stickersCount: Int)
}

public class KeyboardEmojiSendConfig: KeyboardSendConfig {

    public let sendService: KeyboardEmojiItemSendService

    public init(sendService: KeyboardEmojiItemSendService) {
        self.sendService = sendService
    }
}

public class ChatKeyboardEmojiItemConfig: ChatKeyboardItemConfig<KeyboardEmojiUIConfig, KeyboardEmojiSendConfig> {

    public override var key: KeyboardItemKey {
        return .emotion
    }
}

/// ------------------- at 面板控制参数 -------------------
public class KeyboardAtUIConfig: KeyboardUIConfig {}

public class ChatKeyboardAtItemConfig: ChatKeyboardItemConfig<KeyboardAtUIConfig, KeyboardSendConfig> {
    public override var key: KeyboardItemKey {
        return .at
    }
    public init(uiConfig: KeyboardAtUIConfig?) {
        super.init(uiConfig: uiConfig, sendConfig: nil)
    }
}

/// ------------------- Picture 面板控制参数 -------------------
public class KeyboardPictureUIConfig: KeyboardUIConfig {}
/// LarkMessengerInterface
public protocol KeyboardPictureItemSendService: AnyObject {
    // swiftlint:disable function_parameter_count
    func sendVideo(with content: SendVideoContent,
                   isCrypto: Bool,
                   forceFile: Bool,
                   isOriginal: Bool,
                   chatId: String,
                   parentMessage: Message?,
                   lastMessagePosition: Int32?,
                   quasiMsgCreateByNative: Bool?,
                   preProcessManager: ResourcePreProcessManager?,
                   from: NavigatorFrom,
                   extraTrackerContext: [String: Any])
    // swiftlint:enable function_parameter_count

    func sendImages(parentMessage: Message?,
                    useOriginal: Bool,
                    imageMessageInfos: [ImageMessageInfo],
                    chatId: String,
                    lastMessagePosition: Int32,
                    quasiMsgCreateByNative: Bool,
                    extraTrackerContext: [String: Any],
                    stateHandler: ((Int, SendMessageState) -> Void)?)
}

public class KeyboardPictureSendConfig: KeyboardSendConfig {

    public let sendService: KeyboardPictureItemSendService

    public init(sendService: KeyboardPictureItemSendService) {
        self.sendService = sendService
    }
}

public class ChatKeyboardPictureItemConfig: ChatKeyboardItemConfig<KeyboardPictureUIConfig, KeyboardPictureSendConfig> {
    public override var key: KeyboardItemKey {
        return .picture
    }
}
/// ------------------- 字体 面板控制参数 -------------------
public class ChatKeyboardFontItemConfig: ChatKeyboardItemConfig<KeyboardUIConfig, KeyboardSendConfig> {
    public override var key: KeyboardItemKey {
        return .font
    }
}

/// ------------------- 更多 面板控制参数 -------------------
public class KeyboardMoreUIConfig: KeyboardUIConfig {
    public var blacklist: [ChatKeyboardMoreItemType]
    public init(blacklist: [ChatKeyboardMoreItemType] = [],
                tappedBlock: (() -> Void)? = nil) {
        self.blacklist = blacklist
        super.init(tappedBlock: tappedBlock)
    }
}

public protocol KeyboardMoreItemSendService: AnyObject {
    func sendUserCard(shareChatterId: String, chatId: String)

    func sendLocation(parentMessage: Message?, chatId: String, screenShot: UIImage, location: LocationContent)

    func sendFile(path: String,
                  name: String,
                  parentMessage: Message?,
                  removeOriginalFileAfterFinish: Bool,
                  chatId: String,
                  lastMessagePosition: Int32?,
                  quasiMsgCreateByNative: Bool?,
                  preprocessResourceKey: String?)
}

public class KeyboardMoreSendConfig: KeyboardSendConfig {

    public let sendService: KeyboardMoreItemSendService

    public init(sendService: KeyboardMoreItemSendService) {
        self.sendService = sendService
    }
}

public class ChatMoreKeyboardItemConfig: ChatKeyboardItemConfig<KeyboardMoreUIConfig, KeyboardMoreSendConfig> {
    public override var key: KeyboardItemKey {
        return .more
    }
}

/// ------------------- 画板面板控制参数 -------------------
public protocol KeyboardCanvasItemSendService: AnyObject {

    func sendImages(parentMessage: Message?,
                    useOriginal: Bool,
                    imageMessageInfos: [ImageMessageInfo],
                    chatId: String,
                    lastMessagePosition: Int32,
                    quasiMsgCreateByNative: Bool,
                    extraTrackerContext: [String: Any],
                    stateHandler: ((Int, SendMessageState) -> Void)?)

    func sendText(content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  parentMessage: Message?,
                  chatId: String,
                  position: Int32,
                  scheduleTime: Int64?,
                  quasiMsgCreateByNative: Bool,
                  callback: ((SendMessageState) -> Void)?)
}

public class KeyboardCanvasSendConfig: KeyboardSendConfig {

    public let sendService: KeyboardCanvasItemSendService

    public init(sendService: KeyboardCanvasItemSendService) {
        self.sendService = sendService
    }
}

/// 画板按钮
public class ChatKeyboardCanvasItemConfig: ChatKeyboardItemConfig<KeyboardUIConfig, KeyboardCanvasSendConfig> {
    public override var key: KeyboardItemKey {
        return .canvas
    }
}
