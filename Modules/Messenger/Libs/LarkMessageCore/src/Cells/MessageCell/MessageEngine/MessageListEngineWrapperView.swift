//
//  MessageListEngineWrapperView.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/3/28.
//

import UIKit

public final class MessageListEngineWrapperView: UIView {
    public let container: UIView = UIView(frame: .zero)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(container)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
