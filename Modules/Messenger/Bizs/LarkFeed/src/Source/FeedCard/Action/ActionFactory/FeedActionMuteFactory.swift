//
//  FeedActionMuteFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/6/28.
//

import LarkModel
import LarkFeedBase
import LarkOpenFeed
import LarkSDKInterface
import RustPB
import RxSwift

final class FeedActionMuteFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .mute
    }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? {
        return FeedActionMuteViewModel(model: model)
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return FeedActionMuteHandler(type: type, model: model, context: context, vm: FeedActionMuteViewModel(model: model))
    }
}

final class FeedActionMuteHandler: FeedActionHandler {
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
        let feedAPI = try? context.userResolver.resolve(assert: FeedAPI.self)
        feedAPI?.updateFeedCard(feedId: model.feedPreview.id, mute: model.feedPreview.basicMeta.isRemind)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] _ in
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
