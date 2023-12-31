//
//  MyAITopExtendSubModule.swift
//  LarkChat
//
//  Created by 李勇 on 2023/4/11.
//

import RxSwift
import SnapKit
import Foundation
import LarkOpenChat
import LarkOpenKeyboard
import LarkMessageCore
import LKCommonsLogging
import LarkMessengerInterface
import UniverseDesignFont

/// My AI：https://bytedance.feishu.cn/wiki/VExuwU5SCiQ8tlkq9d4c0lF8nGc
public final class MyAITopExtendSubModule: ChatKeyboardTopExtendSubModule {
    static let logger = Logger.log(MyAITopExtendSubModule.self, category: "Module.LarkAI")
    private var myAIPageService: MyAIPageService?

    /// 一旦canHandle为true，则innerContentView不会为nil，My AI场景预期只展示此SubModule的视图
    private var moduleContentView: UIView?
    public override func contentView() -> UIView? { self.moduleContentView }
    /// MyAI场景，不在ChatKeyboardTopExtendView中加顶部的margin，内部自己控制
    public override func contentTopMargin() -> CGFloat { return 0 }

    public override class func canInitialize(context: ChatKeyboardTopExtendContext) -> Bool {
        MyAITopExtendSubModule.logger.info("my ai can initialize")
        return true
    }

    public override func onInitialize() {
        self.myAIPageService = try? self.context.userResolver.resolve(type: MyAIPageService.self)
    }

    public override var type: ChatKeyboardTopExtendType { .myAI }

    public override func canHandle(model: ChatKeyboardTopExtendMetaModel) -> Bool {
        guard model.chat.isP2PAi else { return false }
        // 分对话升级为场景后，此时不由键盘上方处理，交给MyAIChatModeViewController-createFloatStopGeneratingViewIfNeeded中处理
        if self.myAIPageService?.chatMode ?? false, self.myAIPageService?.larkMyAIScenariosThread ?? false { return false }
        MyAITopExtendSubModule.logger.info("my ai can handle, chat id: \(model.chat.id)")
        return true
    }

    /// 后续优化：输入框上方区域上边框没有阴影，导致和消息气泡重叠时颜色一致了，无法区分
    public override func createContentView(model: ChatKeyboardTopExtendMetaModel) {
        MyAITopExtendSubModule.logger.info("my ai begin create interact view")
        self.subCreateContentView(model: model)
        // 之前需要调用refresh是因为键盘上方内容出现后，需要重新设置tableView的高度约束，会看到表格视图被顶起来
        // 现在不需要设置了，因为我们通过ChatMessagesViewController-keyboardTopStackViewInitHeight，在MyAI场景对键盘上方区域设置了固定高度
        // 还是需要调用，因为浮窗模式进入时，keyboardFrameChanged调用self.keyboardTopStackView.bounds.height为0（不知道为啥）
        self.context.refresh()
        MyAITopExtendSubModule.logger.info("my ai finish create interact view")
    }

    /// 创建contentView逻辑
    private func subCreateContentView(model: ChatKeyboardTopExtendMetaModel) {
        // “停止生成”
        let stopGeneratingViewModel = MyAIStopGeneratingViewModel(userResolver: self.context.userResolver, chat: model.chat)
        let stopGeneratingView = MyAIStopGeneratingView(viewModel: stopGeneratingViewModel)
        stopGeneratingView.targetVC = (try? self.context.userResolver.resolve(type: ChatOpenService.self))?.chatVC()

        // “新话题”、“场景对话”、“快捷指令”
        let myAIInteractViewModel = MyAIInteractViewModel(userResolver: self.context.userResolver, chat: model.chat)
        // AIInteractView 需要监听“停止生成”按钮状态，显示/隐藏快捷指令按钮，因此需要弱引用此属性
        myAIInteractViewModel.stopGeneratingIsShown = stopGeneratingViewModel.currIsShow
        let myAIInteractView = MyAIInteractView(viewModel: myAIInteractViewModel)
        myAIInteractView.targetVC = (try? self.context.userResolver.resolve(type: ChatOpenService.self))?.chatVC()

        // 添加视图
        let contentView = UIView()
        contentView.addSubview(myAIInteractView)
        contentView.addSubview(stopGeneratingView)
        contentView.snp.makeConstraints {
            $0.height.equalTo(28.auto() + ChatKeyboardTopExtendView.contentTopMargin)
        }
        myAIInteractView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(28.auto())
        }
        stopGeneratingView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(28.auto())
        }
        self.moduleContentView = contentView
    }
}
