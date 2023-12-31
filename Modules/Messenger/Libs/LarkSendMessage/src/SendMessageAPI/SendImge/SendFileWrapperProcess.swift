//
//  SendFileWrapperProcess.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/24.
//

import Foundation
import FlowChart // FlowChartProcess

public protocol SendImageCoreProcessContext: SendImageCoreFormatInputTaskContext,
                                             SendImageMsgOnScreenTaskContext {
}

public typealias SendFileSerialProcess<C: SendFileProcessContext> = SerialProcess<SendMessageProcessInput<SendFileModel>, C>

// 作用: 发图片流程到发文件流程的切换, 因此wrapper一层
public final class SendFileWrapperProcess<C: SendFileProcessContext>: FlowChartProcess<SendMessageProcessInput<SendImageModel>, SendMessageProcessInput<SendImageModel>, C> {
    override public var identify: String { "SendFileWrapperProcess" }

    private let sendFileProcess: SendFileSerialProcess<C>

    init(sendFileProcess: SendFileSerialProcess<C>,
         context: C) {
        self.sendFileProcess = sendFileProcess
        super.init(context: context)
    }

    public override func run(input: SendMessageProcessInput<SendImageModel>, _ resConsumer: @escaping ResponseConsumer = { _ in }) {
        self.sendFileProcess.onEnd { [weak self] res in
            guard case .success(_) = res else { return }
            self?.accept(.success(input))
        }
        self.sendFileProcess.run(input: getFileModel(input))
    }

    private func getFileModel(_ input: SendMessageProcessInput<SendImageModel>) -> SendMessageProcessInput<SendFileModel> {
        let model = SendFileModel(path: input.model.fileUrl?.path ?? "",
                                  name: input.model.fileUrl?.lastPathComponent ?? "",
                                  chatId: input.model.chatId ?? "",
                                  threadId: input.model.threadId,
                                  size: input.model.imageMessageInfo.imageSize,
                                  removeOriginalFileAfterFinish: false,
                                  executeBeforeCreateQuasiCallback: false)
        return SendMessageProcessInput(context: input.context,
                                       model: model,
                                       stateHandler: input.stateHandler,
                                       parentMessage: input.parentMessage,
                                       sendMessageTracker: input.sendMessageTracker,
                                       replyInThread: input.replyInThread)
    }
}
