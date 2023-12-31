//
//  SendMessageTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/9.
//

import Foundation
import RxSwift // ImmediateSchedulerType
import FlowChart // FlowChartContext
import LarkModel // Message
import LarkContainer // PushNotificationCenter
import LarkSDKInterface // SDKRustService

public protocol SendMessageTaskContext: FlowChartContext {
    var client: SDKRustService { get }
    var queue: DispatchQueue { get }
    var scheduler: ImmediateSchedulerType { get }
    var pushCenter: PushNotificationCenter { get }
    func preSendMessage(cid: String)
    func sendError(value: (LarkModel.Message, Error?))
    func adjustLocalStatus(message: LarkModel.Message, stateHandler: ((SendMessageState) -> Void)?)
}

extension RustSendMessageAPI: SendMessageTaskContext {}

public final class SendMessageTask<M: SendMessageModelProtocol, C: SendMessageTaskContext>: FlowChartTask<SendMessageProcessInput<M>, SendMessageProcessInput<M>, C> {
    override public var identify: String { "SendMessageTask" }

    private var disposeBag = DisposeBag()

    public override func run(input: SendMessageProcessInput<M>) {
        guard let client = flowContext?.client else {
            self.accept(.error(.dataError("client is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        flowContext?.queue.async { [weak self] in
            guard let self = self else { return }
            let cid = input.message?.cid ?? ""
            guard let message = input.message else { return }
            self.flowContext?.preSendMessage(cid: cid)
            self.flowContext?.adjustLocalStatus(message: message, stateHandler: input.stateHandler)

            input.stateHandler?(.beforeSendMessage(message, processCost: input.processCost))
            input.sendMessageTracker?.beforeSendMessage(context: input.context, msg: message, processCost: input.processCost)

            RustSendMessageModule
                .sendMessage(cid: cid, client: client, context: input.context, multiSendSerialToken: input.multiSendSerialToken, multiSendSerialDelay: input.multiSendSerialDelay)
                .subscribeOn(self.flowContext?.scheduler)
                .subscribe(onNext: { [weak self] result in
                    guard let self = self else { return }
                    input.stateHandler?(.finishSendMessage(message, contextId: input.context?.contextID ?? "", messageId: result.messageId, netCost: result.netCost, trace: result.trace))
                    // 发消息API调用成功
                    input.sendMessageTracker?.finishSendMessageAPI(context: input.context,
                                                                   msg: message,
                                                                   contextId: input.context?.contextID ?? "",
                                                                   messageId: result.messageId,
                                                                   netCost: result.netCost,
                                                                   trace: result.trace)
                    // 处理退出聊天埋点上报的情况, 如果退出聊天这里将直接上报流程完成
                    input.sendMessageTracker?.sendMessageFinish(cid: message.cid,
                                                                messageId: message.id,
                                                                success: true,
                                                                page: "ChatMessagesViewController",
                                                                isCheckExitChat: true,
                                                                renderCost: 0)
                    self.accept(.success(input))
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    input.message?.localStatus = .fail
                    input.stateHandler?(.errorSendMessage(cid: cid, error: error))
                    input.sendMessageTracker?.errorSendMessage(context: input.context, cid: cid, error: error)
                    self.flowContext?.sendError(value: (message, error))
                    RustSendMessageAPI.logger.error("sendMessage fail", additionalData: ["MsgCid": cid], error: error)
                    self.accept(.error(.dataError("sendMessage fail", extraInfo: ["cid": input.message?.cid ?? ""])))
                })
                .disposed(by: self.disposeBag)
        }
    }
}

extension ObservableType {
    func subscribeOn(_ scheduler: ImmediateSchedulerType? = nil) -> Observable<Self.Element> {
        if let scheduler = scheduler {
            return self.subscribeOn(scheduler)
        }
        return self.asObservable()
    }
}
