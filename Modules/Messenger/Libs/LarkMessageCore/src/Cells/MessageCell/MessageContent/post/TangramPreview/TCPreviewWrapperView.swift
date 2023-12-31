//
//  TCPreviewWrapperView.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2021/4/28.
//

// 为了防止AsyncComponent复用时，复用到其他的UIView，需要wrapper一层
import UIKit
import Foundation
import TangramUIComponent

public final class TCPreviewWrapperView: UIView {
    public typealias OnTap = () -> Void

    public let tcContainer: UIViewWrapper = UIViewWrapper(frame: .zero)
    public var onTap: OnTap?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        addSubview(tcContainer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        // https://meego.feishu.cn/larksuite/issue/detail/16671783
        // TCPreviewWrapperView总是比tcContainer多2px，怀疑是border的问题，调了下Component得属性没有解决，在此处兜底下
        tcContainer.frame.size = bounds.size
        super.layoutSubviews()
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if onTap == nil {
            super.touchesBegan(touches, with: event)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        // LKLabel在touchesEnded里处理点击事件，此处不能通过加gesture的方式处理点击事件（gesture会拦截touch）
        if bounds.contains(point), let tap = onTap {
            tap()
        } else {
            super.touchesEnded(touches, with: event)
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if onTap == nil {
            super.touchesCancelled(touches, with: event)
        }
    }
}
