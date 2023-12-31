//
//  ChatKeyboardTopExtendDemoSubModule.swift
//  LarkOpenChat
//
//  Created by zc09v on 2021/8/11.
//

import UIKit
import Foundation
import SnapKit
import LarkOpenIM

open class ChatKeyboardTopExtendDemoSubModule: ChatKeyboardTopExtendSubModule {
    private var demoContentView: DemoView?

    private var display: Bool = true
    public override func contentView() -> UIView? {
        return display ? self.demoContentView : nil
    }

    public override class func canInitialize(context: ChatKeyboardTopExtendContext) -> Bool {
        return true
    }

    public override var type: ChatKeyboardTopExtendType {
        return .demo
    }

    public override func modelDidChange(model: ChatKeyboardTopExtendMetaModel) {
        print("model did change")
//        if display {
//            self.display = false
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                self.context.refresh()
//            }
//        }
    }

    public override func handler(model: ChatKeyboardTopExtendMetaModel) -> [Module<ChatKeyboardTopExtendContext, ChatKeyboardTopExtendMetaModel>] {
        return [self]
    }

    public override func canHandle(model: ChatKeyboardTopExtendMetaModel) -> Bool {
        return model.chat.type != .p2P
    }

    public override func createContentView(model: ChatKeyboardTopExtendMetaModel) {
        self.demoContentView = DemoView(frame: .zero)
    }
}

private final class DemoView: UIView {
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.green
        let content: UILabel = UILabel(frame: .zero)
        content.text = "键盘上方扩展区域demo视图"
        self.addSubview(content)
        content.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
