//
//  VoteContentFactory.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/21.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkRustClient
import RxSwift
import RustPB
import LKCommonsLogging
import UniverseDesignToast

private let logger = Logger.log(VoteContentContext.self, category: "VoteContentContext")

public protocol VoteContentContext: VoteContentViewModelContext & VoteContentComponentContext {
    var scene: ContextScene { get }
}

public class BaseVoteContentFactory<C: VoteContentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return (metaModel.message.content as? LarkModel.CardContent)?.type == .vote
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return VoteContentViewModel(metaModel: metaModel,
                                    metaModelDependency: metaModelDependency,
                                    context: context,
                                    binder: VoteContentComponentBinder<M, D, C>(context: context))
    }
}

public final class MessageDetailVoteContentFactory<C: VoteContentContext>: BaseVoteContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return MessageDetailVoteContentViewModel(metaModel: metaModel,
                                                 metaModelDependency: metaModelDependency,
                                                 context: context,
                                                 binder: MessageDetailVoteContentComponentBinder<M, D, C>(context: context))
    }
}

public final class PinVoteContentFactory<C: VoteContentContext>: BaseVoteContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return PinVoteContentViewModel(metaModel: metaModel,
                                    metaModelDependency: metaModelDependency,
                                    context: context,
                                    binder: PinVoteContentComponentBinder<M, D, C>(context: context))
    }
}

extension PageContext: VoteContentContext {
    public func sendAction(actionID: String, params: [String: String], messageID: String) {
        logger.info("will send action", additionalData: ["messageID": messageID, "actionID": actionID])
        guard let rustService = try? resolver.resolve(assert: RustService.self) else {
            return
        }
        var request = RustPB.Im_V1_PutActionRequest()
        request.actionID = actionID
        request.params = params
        request.messageID = messageID
        var bag = DisposeBag()
        let observer: Observable<RustPB.Im_V1_PutActionResponse> = rustService.sendAsyncRequest(request)
        observer.subscribe(onNext: { _ in
            logger.info("did send action", additionalData: ["messageID": messageID, "actionID": actionID])
            bag = DisposeBag()
        }, onError: { [weak self] error in
            if case .businessFailure(errorInfo: let info) = error as? RCError {
                DispatchQueue.main.async {
                if let window = self?.targetVC?.view, info.errorCode == 100 {
                        UDToast.showFailure(with: info.displayMessage, on: window)
                    }
                }
            }
        }).disposed(by: bag)
    }
}
