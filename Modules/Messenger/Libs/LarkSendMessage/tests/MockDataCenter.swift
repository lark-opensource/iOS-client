//
//  MockDataCenter.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2022/11/23.
//

import Foundation
import UIKit
import ByteWebImage // ImageFileFormat
import LarkModel // Message
import RustPB // Basic_V1_QuasiContent
@testable import LarkSendMessage

// MARK: - 数据Mock方法
class MockDataCenter {
    static func genSendTextMessageProcessInputData(withAtElement: Bool) -> SendMessageProcessInput<SendTextModel> {
        // 得到只包一个AT的RichText
        let richTextBuilder = RichTextBuilder()
        if withAtElement {
            richTextBuilder.updateRichTextWithAtElement(userID: RandomString.randomNumber(length: 19), content: RandomString.random(length: 5))
        }
        // 组装SendMessageProcessInput
        let sendTextModelBuilder = SendTextModelBuilder(content: richTextBuilder.richText)
        let sendMessageProcessInputBuilder = SendMessageProcessInputBuilder(model: sendTextModelBuilder.sendTextModel)
        sendMessageProcessInputBuilder.updateUseNativeCreate(useNativeCreate: true)
        return sendMessageProcessInputBuilder.sendMessageProcessInput
    }

    static func genQuasiContentData(withAtElement: Bool,
                                    userId: String = "6948991852074795036",
                                    content: String = "_") -> RustPB.Basic_V1_QuasiContent {
        let richTextBuilder = RichTextBuilder()
        if withAtElement {
            richTextBuilder.updateRichTextWithAtElement(userID: userId, content: content)
        }
        let quasiContentBuilder = QuasiContentBuilder()
        quasiContentBuilder.updateRichText(richText: richTextBuilder.richText)
        return quasiContentBuilder.quasiContent
    }

    static func genRichText(withAtElement: Bool,
                            userId: String = "6948991852074795036",
                            content: String = "_") -> RustPB.Basic_V1_RichText {
        let richTextBuilder = RichTextBuilder()
        if withAtElement {
            richTextBuilder.updateRichTextWithAtElement(userID: userId, content: content)
        }
        return richTextBuilder.richText
    }

    static func genSendImageModel(imageName: String? = nil,
                                  chatId: String = "7170989253818646532",
                                  isIgnoreQuickUpload: Bool = false,
                                  imageType: ImageFileFormat = .png) -> SendImageModel? {
        var image: UIImage?
        var imageData: Data?
        switch imageType {
        case .jpeg:
            let name = imageName ?? "1200x1400-JPEG"
            image = Resources.image(named: name)
            imageData = Resources.imageData(named: name)
        case .heic:
            let name = imageName ?? "1200x1400-HEIC"
            image = Resources.image(named: name)
            imageData = Resources.imageData(named: name)
        case .png:
            let name = imageName ?? "1200x1400-PNG"
            image = Resources.image(named: name)
            imageData = Resources.imageData(named: name)
        default:
            assertionFailure("unsupport type")
        }
        guard let image = image, var imageData = imageData else { return nil }

        // 添加随机内容，避免触发秒传
        if isIgnoreQuickUpload {
            let random = RandomString.random(length: 20)
            let appendData = random.data(using: .utf8) ?? Data()
            imageData.append(appendData)
        }
        let imageSourceFunc: ImageSourceFunc = { ImageSourceResult(sourceType: imageType, data: imageData, image: image) }
        let imageMessageInfo = ImageMessageInfo(originalImageSize: image.size, sendImageSource: SendImageSource(cover: imageSourceFunc, origin: imageSourceFunc))
        let model = SendImageModel(useOriginal: false, imageMessageInfo: imageMessageInfo, chatId: chatId)
        return model
    }

    static func genMessage() -> LarkModel.Message {
        let msg = Message.transform(pb: Message.PBModel())
        msg.id = RandomString.random(length: 10)
        return msg
    }
}

// MARK: - 各种模型Builder，文件内使用
class SendMessageProcessInputBuilder<M: SendMessageModelProtocol> {
    var sendMessageProcessInput: SendMessageProcessInput<M>

    init(model: M) {
        self.sendMessageProcessInput = SendMessageProcessInput<M>(model: model)
    }

    func updateUseNativeCreate(useNativeCreate: Bool) {
        self.sendMessageProcessInput.useNativeCreate = useNativeCreate
    }
}

class SendTextModelBuilder {
    var sendTextModel: SendTextModel

    init(content: RustPB.Basic_V1_RichText) {
        self.sendTextModel = SendTextModel(
            content: content,
            lingoInfo: RustPB.Basic_V1_LingoOption(),
            cid: RandomString.random(length: 10),
            chatId: RandomString.randomNumber(length: 19)
        )
    }
}

class QuasiContentBuilder {
    var quasiContent = RustPB.Basic_V1_QuasiContent()

    func updateRichText(richText: RustPB.Basic_V1_RichText) {
        self.quasiContent.richText = richText
    }
}

class RichTextBuilder {
    lazy var richText: RustPB.Basic_V1_RichText = {
        var richText = RustPB.Basic_V1_RichText()
        // innerText是必传字段，Rust侧定义：message RichText { required string inner_text ... }
        richText.innerText = ""
        return richText
    }()

    func updateRichTextWithAtElement(key: String = "69321636",
                                     userID: String,
                                     content: String) {
        self.richText.elements[key] = self.genRichTextAtElement(userID: userID, content: content)
        self.richText.atIds.append(userID)
        self.richText.elementIds.append(key)
    }

    func updateRichTextWithEmotionElement(key: String, emotionKey: String) {
        // key 8位数字
        self.richText.elements[key] = self.genRichTextEmotionElement(key: emotionKey)
        self.richText.elementIds.append(key)
    }

    func updateRichTextWithFormatElement(key: String,
                                         content: String,
                                         Bold: Bool = false,
                                         Italic: Bool = false,
                                         Underline: Bool = false,
                                         Linethrough: Bool = false) {
        // key 8位数字
        self.richText.elements[key] = self.genRichTextElement(content: content,
                                                              Bold: Bold,
                                                              Italic: Italic,
                                                              Underline: Underline,
                                                              Linethrough: Linethrough)

        self.richText.elementIds.append(key)
    }

    func updateRichTextWithMediaElement(key: String, originPath: String, imageData: Data) {
        self.richText.elements[key] = self.genRichTextMediaElement(originPath: originPath, imageData: imageData)
        self.richText.elementIds.append(key)
        self.richText.mediaIds.append(key)
    }

    private func genRichTextAtElement(userID: String, content: String) -> RustPB.Basic_V1_RichTextElement {
        var atProperty = RustPB.Basic_V1_RichTextElement.AtProperty()
        atProperty.userID = userID
        atProperty.content = content
        atProperty.isOuter = false
        atProperty.isAnonymous = false
        var propertySet = RustPB.Basic_V1_RichTextElement.PropertySet()
        propertySet.at = atProperty
        var element = RustPB.Basic_V1_RichTextElement()
        element.tag = .at
        element.property = propertySet
        return element
    }

    private func genRichTextPElement() -> RustPB.Basic_V1_RichTextElement {
        let pProperty = RustPB.Basic_V1_RichTextElement.ParagraphProperty()
        var propertySet = RustPB.Basic_V1_RichTextElement.PropertySet()
        propertySet.paragraph = pProperty
        var element = RustPB.Basic_V1_RichTextElement()
        element.tag = .p
        element.property = propertySet
        return element
    }

    private func genRichTextElement(content: String = "default_content",
                                    Bold: Bool = false,
                                    Italic: Bool = false,
                                    Underline: Bool = false,
                                    Linethrough: Bool = false) -> RustPB.Basic_V1_RichTextElement {
        // 默认不包含格式文本
        var element = RustPB.Basic_V1_RichTextElement()
        var textProperty = RustPB.Basic_V1_RichTextElement.TextProperty()
        var propertySet = RustPB.Basic_V1_RichTextElement.PropertySet()
        textProperty.content = content
        propertySet.text = textProperty
        element.tag = .text
        element.property = propertySet
        if Bold {
            element.style["fontWeight"] = "bold"
        }
        if Italic {
            element.style["fontStyle"] = "italic"
        }
        element.style["-lark-textDecoration"] = (Underline ? "underline" : "") + (Linethrough ? " lineThrough" : "")
        return element
    }

    private func genRichTextEmotionElement(key: String = "GeneralTravellingCar") -> RustPB.Basic_V1_RichTextElement {
        var emotionProperty = RustPB.Basic_V1_RichTextElement.EmotionProperty()
        emotionProperty.key = key
        var propertySet = RustPB.Basic_V1_RichTextElement.PropertySet()
        propertySet.emotion = emotionProperty
        var element = RustPB.Basic_V1_RichTextElement()
        element.tag = .emotion
        element.property = propertySet
        return element
    }

    private func genRichTextMediaElement(originPath: String, imageData: Data) -> RustPB.Basic_V1_RichTextElement {
        var mediaProperty = RustPB.Basic_V1_RichTextElement.MediaProperty()
        mediaProperty.originPath = originPath
        mediaProperty.compressPath = originPath
        mediaProperty.imageData = imageData
        var propertySet = RustPB.Basic_V1_RichTextElement.PropertySet()
        propertySet.media = mediaProperty
        var element = RustPB.Basic_V1_RichTextElement()
        element.tag = .media
        element.property = propertySet
        return element
    }
}

// MARK: - 得到随机字符串
class RandomString {
    static func random(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement() ?? "a" })
    }

    static func randomNumber(length: Int) -> String {
        let letters = "0123456789"
        return String((0..<length).map { _ in letters.randomElement() ?? "0" })
    }

    static func randomLetter(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<length).map { _ in letters.randomElement() ?? "a" })
    }
}
