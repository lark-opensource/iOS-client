//
//  FeedActionRemoveFeedFactory.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/8/17.
//

import LarkContainer
import LarkModel
import LarkOpenFeed
import LarkSDKInterface
import RustPB
import RxSwift

// MARK: - 默认工厂实现Item
final class FeedActionRemoveFeedFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .removeFeed
    }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? {
        return nil
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return FeedActionRemoveFeedHandler(type: type, model: model, context: context)
    }
}

final class FeedActionRemoveFeedHandler: FeedActionHandler {
    private let disposeBag = DisposeBag()
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        self.willHandle()
        let feedAPI = try? self.context.userResolver.resolve(type: FeedAPI.self)
        feedAPI?.removeFeedCard(channel: model.channel, feedType: model.feedPreview.basicMeta.feedPreviewPBType)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.didHandle()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.didHandle(error: error)
            }).disposed(by: self.disposeBag)
    }
}
