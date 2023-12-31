//
//  DocFeedActionMuteFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/7/17.
//
#if MessengerMod

import LarkFeedBase
import LarkModel
import LarkOpenFeed
import LarkSDKInterface
import RustPB
import RxSwift

class DocFeedActionMuteFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .mute
    }

    var bizType: FeedPreviewType? {
        return .docFeed
    }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? {
        return FeedActionMuteViewModel(model: model)
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return DocFeedActionMuteHandler(type: type, model: model, context: context, vm: FeedActionMuteViewModel(model: model))
    }
}

final class DocFeedActionMuteHandler: FeedActionHandler {
    let disposeBag = DisposeBag()
    let context: FeedCardContext
    let vm: FeedActionMuteViewModel
    public init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext, vm: FeedActionMuteViewModel) {
        self.context = context
        self.vm = vm
        super.init(type: type, model: model)
    }

    override func executeTask() {
        self.willHandle()

        let docAPI = try? context.userResolver.resolve(assert: DocAPI.self)
        docAPI?.updateDocFeed(feedId: model.feedPreview.id, isRemind: !model.feedPreview.basicMeta.isRemind).asSingle()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] in
                guard let self = self else { return }
                self.didHandle()
            } onError: { [weak self] error in
                guard let self = self else { return }
                self.didHandle(error: error)
            }.disposed(by: self.disposeBag)
    }

    override func handleResultByDefault(error: Error?) {
        vm.handleResultByDefault(error: error)
    }
}
#endif
