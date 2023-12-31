//
//  FlodApproveViewComponent.swift
//  LarkMessageCore
//
//  Created by Bytedance on 2022/9/23.
//

import UIKit
import Foundation
import AsyncComponent

public final class FlodApproveViewComponent<C: AsyncComponent.Context>: ASComponent<FlodApproveViewComponent.Props, EmptyState, FlodApproveView, C> {
    public final class Props: ASComponentProps {
        /// +1回调，如果触发连续，则只回调最后一个数字
        public weak var delegate: FlodApproveViewDelegate?
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override var isComplex: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        // 计算按钮占用的宽度
        let titleWidth = self.textSize(text: BundleI18n.LarkMessageCore.Lark_IM_StackMessage_MeToo_Button, font: UIFont.systemFont(ofSize: 16)).width
        // 最大宽度为父视图宽度 - 24
        let sizeToFitWidth = min(24 + 22 + 4 + titleWidth + 24, size.width - 24)
        return CGSize(width: sizeToFitWidth, height: size.height)
    }

    public override func update(view: FlodApproveView) {
        super.update(view: view)
        view.delegate = self.props.delegate
    }

    private func textSize(text: String, font: UIFont) -> CGSize {
        return NSString(string: text).boundingRect(with: .zero, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil).size
    }
}
