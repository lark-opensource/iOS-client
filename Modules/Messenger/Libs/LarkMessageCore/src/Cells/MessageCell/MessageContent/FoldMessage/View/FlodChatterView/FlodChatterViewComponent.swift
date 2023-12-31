//
//  FlodChatterViewComponent.swift
//  LarkMessageCore
//
//  Created by Bytedance on 2022/9/23.
//

import UIKit
import Foundation
import AsyncComponent

public final class FlodChatterViewComponent<C: AsyncComponent.Context>: ASComponent<FlodChatterViewComponent.Props, EmptyState, FlodChatterView, C> {
    public final class Props: ASComponentProps {
        /// 所有待展示的人，不一定能展示全
        public var foldChatters: [FlodChatter] = []
        /// 头像、其他区域点击回调
        public weak var delegate: FlodChatterViewDelegate?
    }

    /// 布局计算
    private var flodChatterLayout = FlodChatterLayout(chatters: [])

    public override var isSelfSizing: Bool {
        return true
    }

    public override var isComplex: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        self.flodChatterLayout = FlodChatterLayout(chatters: self.props.foldChatters)
        self.flodChatterLayout.layout(size)
        return self.flodChatterLayout.contentSize
    }

    public override func update(view: FlodChatterView) {
        super.update(view: view)
        view.delegate = self.props.delegate
        view.setup(chatters: self.flodChatterLayout.chatters, chatterFrames: self.flodChatterLayout.chatterFrames)
    }
}
