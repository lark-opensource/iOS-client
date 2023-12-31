//
//  FeedbackRegenerateComponentViewModel.swift
//  LarkAI
//
//  Created by 李勇 on 2023/6/16.
//

import RustPB
import RxSwift
import Foundation
import LarkMessageBase
import LarkSDKInterface
import LarkMessengerInterface

public protocol FeedbackRegenerateViewModelContext: ViewModelContext {
    var myAIPageService: MyAIPageService? { get }
}

public class FeedbackRegenerateComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: FeedbackRegenerateViewModelContext>: NewMessageSubViewModel<M, D, C> {
    private let disposeBag = DisposeBag()

    /// 当前赞踩&重新生成是显示/隐藏状态
    public private(set) var currIsShow: Bool = false {
        didSet {
            if currIsShow != oldValue {
                self.binderAbility?.syncToBinder()
                // 这里得用reloadTable，否则得话会和follow up有时序问题，导致界面没有往上滚动，follow up没有完全展示出来
                // 1.follow up重新计算布局，此时布局后高度新增了X，还没触发roloadTable
                // 2.此currIsShow被调用，触发了CommonTable.refresh(indexPaths:xxx，但是guarantLastCellVisible是false，不会自动往上滚动
                // 3.接着上面的1，roloadTable最终触发了CommonTable.reloadAndGuarantLastCellVisible(，虽然guarantLastCellVisible是true，但是stickToBottom判断不贴底了，也无法往上滚动了
                // 解决办法：改为调用roloadTable，guarantLastCellVisible为true，会自动往上滚动
                self.binderAbility?.updateComponentAndRoloadTable()
            }
        }
    }
    /// 当前重新生成是loading/正常状态
    public var currIsLoading: Bool = false {
        didSet {
            if currIsLoading != oldValue {
                self.binderAbility?.syncToBinder()
                self.binderAbility?.updateComponent(animation: .none)
            }
        }
    }

    public override func initialize() {
        super.initialize()
        // 监听 AIRoundInfo
        guard let myAIPageService = self.context.myAIPageService else { return }
        myAIPageService.aiRoundInfo
            .filter({ $0.chatId != AIRoundInfo.default.chatId })
            .subscribe(onNext: { [weak self] (aiRoundInfo) in
                guard let `self` = self else { return }
                let oldIsShow = self.currIsShow; self.currIsShow = self.judgeCurrShowStatus(by: aiRoundInfo)
                // 如果是从显示到隐藏，则恢复状态；增加oldIsShow判断是为了减少不相关的消息刷新
                if oldIsShow, !self.currIsShow { self.currIsLoading = false }
            }).disposed(by: self.disposeBag)
        // 监听假消息上屏，隐藏 FeedBack 按钮区
        myAIPageService.onQuasiMessageShown.observeOn(MainScheduler.instance)
            .skip(1)
            .subscribe(onNext: { [weak self] in
                self?.currIsShow = false
            }).disposed(by: disposeBag)
    }

    /// 判断当前是否应该展示、隐藏；此时传入的AIRoundInfo一定是当前主分会场对应的，MyAIPageService中已经过滤了
    private func judgeCurrShowStatus(by: AIRoundInfo) -> Bool {
        guard let myAIPageService = self.context.myAIPageService else { return false }
        // 当前消息是否是最后一轮的最后一条消息，主会场用message.position、分会场用message.threadPosition
        if !myAIPageService.chatMode, self.metaModel.message.position != by.roundLastPosition { return false }
        if myAIPageService.chatMode, self.metaModel.message.threadPosition != by.roundLastPosition { return false }
        // 是否已经回复完成
        return by.status.isFinished
    }
}
