//
//  AtWhenMultiEditTipsView.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/8/15.
//

import UIKit
import Foundation
import UniverseDesignColor

final class AtWhenMultiEditTipsView: UIView, KeyboardTipsView {

    lazy var label: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkMessageCore.Lark_IM_EditMessage_EditedMessageNoNotifications_Text
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = .ud.textCaption
        return label
    }()

    init(scene: KeyboardTipScene) {
        super.init(frame: .zero)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(scene == .compose ? 12 : 8)
            make.right.lessThanOrEqualToSuperview().offset(scene == .compose ? -12 : -8)
        }
        backgroundColor = .ud.bgBodyOverlay
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func suggestHeight(maxWidth: CGFloat) -> CGFloat {
        let textHeight = label.text?.lu.height(font: label.font, width: maxWidth - 24) ?? 0
        //上间距是8
        return textHeight + 8
    }
}
