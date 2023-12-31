//
//  UDButtonWrapper.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/4/21.
//

import UIKit
import Foundation
import UniverseDesignButton
import SnapKit
import LarkInteraction

public final class UDButtonWrapper: UIView {
    public let button: UDButton

    public override init(frame: CGRect) {
        button = UDButton()
        super.init(frame: frame)
        addSubview(button)
        button.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.backgroundColor = .clear

        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .highlight)
            )
            button.addLKInteraction(pointer)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static func sizeToFit(_ size: CGSize,
                                 iconSize: CGFloat,
                                 title: String = "",
                                 type: UDButtonUIConifg.ButtonType) -> CGSize {
        if title.isEmpty {
            return CGSize(width: iconSize, height: iconSize)
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        paragraphStyle.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        let contentPadding = type.edgeInsets() * 2
        let size = NSAttributedString(
            string: title,
            attributes: [
                .font: type.font(),
                .paragraphStyle: paragraphStyle
            ]
        ).componentTextSize(for: CGSize(width: size.width - iconSize - contentPadding, height: size.height),
                            limitedToNumberOfLines: 1)

        let typeSize = type.size()
        var buttonWidth = iconSize + size.width + contentPadding
        buttonWidth = buttonWidth > typeSize.width ? buttonWidth : typeSize.width

        return CGSize(
            width: iconSize + size.width + contentPadding,
            height: iconSize > size.height ? iconSize : typeSize.height
        )
    }
}
