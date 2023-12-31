////
////  SendImageFormatInputTask.swift
////  LarkSDK
////
////  Created by JackZhao on 2022/1/9.
////
//

import Foundation
import FlowChart // FlowChartContext
import ByteWebImage // ImageSourceResult

public protocol SendImageCoreFormatInputTaskContext: FlowChartContext {
}

// 发图片核心流程预处理
public final class SendImageCoreFormatInputTask<C: SendImageFormatInputTaskContext>: FlowChartTask<SendMessageProcessInput<SendImageModel>, SendMessageProcessInput<SendImageModel>, C> {
    override public var identify: String { "SendImageCoreFormatInputTask" }

    public override func run(input: SendMessageProcessInput<SendImageModel>) {
        var output = input
        var imageSource: ImageSourceResult?
        var imageData: Data?
        // 创建假消息，优先取上屏图片
        if let coverForOnScreen = input.model.imageMessageInfo.sendImageSource.coverForOnScreen,
           let coverForOnScreenImageData = coverForOnScreen.data {
            imageSource = coverForOnScreen
            imageData = coverForOnScreenImageData
        } else {
            imageSource = input.model.imageMessageInfo.sendImageSource.originImage
            imageData = imageSource?.data
        }
        if let data = imageData, let source = imageSource {
            output.model.imageData = imageData
            output.model.imageSource = imageSource
            self.accept(.success(output))
        } else {
            self.accept(.error(.dataError("data or source is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
        }
    }
}
