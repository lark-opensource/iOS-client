//
//  SendScheduleMsgTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/9/19.
//

import Foundation
import RxSwift // ImmediateSchedulerType
import FlowChart // FlowChartContext
import LarkSDKInterface // SDKRustService

public protocol SendScheduleMsgTaskContext: FlowChartContext {
    var client: SDKRustService { get }
    var queue: DispatchQueue { get }
    var scheduler: ImmediateSchedulerType? { get set }
}

/// 发送定时消息，不上屏、渲染；后续时间到了后，由服务端Push到端上上屏、渲染
public final class SendScheduleMsgTask<M: SendMessageModelProtocol, C: SendMessageTaskContext>: FlowChartTask<SendMessageProcessInput<M>, SendMessageProcessInput<M>, C> {
    override public var identify: String { "SendScheduleMsgTask" }
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

            input.stateHandler?(.beforeSendMessage(message, processCost: input.processCost))

            RustSendMessageModule
                .sendMessage(cid: cid, client: client, context: input.context, multiSendSerialToken: input.multiSendSerialToken, multiSendSerialDelay: input.multiSendSerialDelay)
                .subscribeOn(self.flowContext?.scheduler)
                .subscribe(onNext: { [weak self] result in
                    guard let self = self else { return }
                    input.stateHandler?(.finishSendMessage(message, contextId: input.context?.contextID ?? "", messageId: result.messageId, netCost: result.netCost, trace: result.trace))
                    self.accept(.success(input))
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    input.stateHandler?(.errorSendMessage(cid: cid, error: error))
                    RustSendMessageAPI.logger.error("sendMessage fail", additionalData: ["MsgCid": cid], error: error)
                    self.accept(.error(.dataError("sendMessage fail", extraInfo: ["cid": input.message?.cid ?? ""])))
                })
                .disposed(by: self.disposeBag)
        }
    }
}
