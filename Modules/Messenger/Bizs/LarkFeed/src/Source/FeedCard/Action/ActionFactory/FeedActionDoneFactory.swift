//
//  FeedActionDoneFactory.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/6/28.
//

import LarkContainer
import LarkModel
import LarkOpenFeed
import LarkSDKInterface
import RustPB
import RxSwift
import UniverseDesignDialog

// MARK: - 默认工厂实现Item
final class FeedActionDoneFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .done
    }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? {
        return FeedActionDoneViewModel(model: model)
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return FeedActionDoneHandler(type: type, model: model, context: context)
    }
}

final class FeedActionDoneViewModel: FeedActionViewModelInterface {
    let title: String
    let contextMenuImage: UIImage
    let swipeEditImage: UIImage?
    let swipeBgColor: UIColor?
    init(model: FeedActionModel) {
        self.title = BundleI18n.LarkFeed.Lark_Legacy_DoneNow
        self.contextMenuImage = Resources.feed_done_contextmenu
        self.swipeEditImage = Resources.feed_done_icon
        self.swipeBgColor = UIColor.ud.colorfulTurquoise
    }
}

final class FeedActionDoneHandler: FeedActionHandler {
    private let disposeBag = DisposeBag()
    private let context: FeedCardContext
    private let delayTime: CGFloat = 0.9

    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        if let event = model.event, event == .longPress {
            //延迟 0.9 秒让第一个动画走完， iOS 13 没有 contextmenu complete 回调，简单的解决下。
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delayTime) {
                self.moveToDone()
            }
        } else {
            self.moveToDone()
        }
    }

    private func moveToDone() {
        self.willHandle()
        let feedAPI = try? context.userResolver.resolve(assert: FeedAPI.self)
        var entityType = model.feedPreview.basicMeta.feedPreviewPBType
        if entityType == .thread, model.feedPreview.preview.threadData.entityType == .msgThread {
            // 如果是话题消息的话需要传.msgThread的类型
            entityType = .msgThread
        }
        feedAPI?.moveToDone(feedId: model.feedPreview.id, entityType: entityType)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.didHandle()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.didHandle(error: error)
            }).disposed(by: self.disposeBag)
    }

    override func trackHandle(status: FeedActionStatus) {
        guard let event = model.event else { return }
        if case .willHandle = status {
            switch event {
            case .rightSwipe:
                FeedTeaTrack.trackDoneFeed(model.feedPreview, true, false)
                if let filterType = model.groupType {
                    FeedTracker.Main.Click.Done(filter: filterType, isSmallSlide: true, padUnfoldStatus)
                }
            case .longPress:
                FeedTeaTrack.trackDoneFeed(model.feedPreview, false, true)
                FeedTracker.Press.Click.Item(
                    itemValue: FeedActionType.clickTrackValue(type: .done, feedPreview: model.feedPreview),
                    feedPreview: model.feedPreview,
                    basicData: model.basicData
                )
            case .leftSwipe:
                break
            @unknown default:
                break
            }
        }
    }

    private var padUnfoldStatus: String? {
        let service = try? context.userResolver.resolve(assert: FeedThreeBarService.self)
        if let unfold = service?.padUnfoldStatus {
            return unfold ? "unfold" : "fold"
        }
        return nil
    }
}
