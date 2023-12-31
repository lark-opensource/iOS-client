//
//  OpenMessageMenuItem.swift
//  LarkOpenChat
//
//  Created by Ping on 2023/11/21.
//

public struct OpenMessageMenuItem {
    public var text: String
    public var icon: UIImage
    public var canInitialize: (OpenMessageMenuContext) -> Bool
    public var tapAction: (OpenMessageMenuContext) -> Void

    public init(
        text: String,
        icon: UIImage,
        canInitialize: @escaping (OpenMessageMenuContext) -> Bool,
        tapAction: @escaping (OpenMessageMenuContext) -> Void
    ) {
        self.text = text
        self.icon = icon
        self.canInitialize = canInitialize
        self.tapAction = tapAction
    }
}
