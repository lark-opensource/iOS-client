//
//  MicroAppFeedActionMuteFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/7/17.
//
#if MessengerMod
import LarkFeedBase
import LarkModel
import LarkOpenFeed
import RustPB
import RxSwift
import LarkContainer

class MicroAppFeedActionMuteFactory: FeedActionBaseFactory {

    var type: FeedActionType {
        return .mute
    }

    var bizType: FeedPreviewType? {
        return .microApp
    }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? {
        return FeedActionMuteViewModel(model: model)
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return MicroAppFeedActionMuteHandler(type: type, model: model, context: context, vm: FeedActionMuteViewModel(model: model))
    }
}

final class MicroAppFeedActionMuteHandler: FeedActionHandler, UserResolverWrapper {
    @ScopedInjectedLazy var dependency: MicroAppFeedCardDependency?
    let disposeBag = DisposeBag()
    let context: FeedCardContext
    var userResolver: UserResolver {
        return context.userResolver
    }

    let vm: FeedActionMuteViewModel
    public init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext, vm: FeedActionMuteViewModel) {
        self.context = context
        self.vm = vm
        super.init(type: type, model: model)
    }

    override func executeTask() {
        self.willHandle()
        // 开启/关闭小程序的消息提醒
        dependency?.changeMute(feedId: model.feedPreview.id, to: !model.feedPreview.basicMeta.isRemind).map { _ in
        }.observeOn(MainScheduler.instance)
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
