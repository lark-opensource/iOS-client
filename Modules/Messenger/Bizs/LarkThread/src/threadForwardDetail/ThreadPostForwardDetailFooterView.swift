//
//  ThreadPostForwardDetailFooterView.swift
//  LarkThread
//
//  Created by liluobin on 2021/6/16.
//

import UIKit
import Foundation
import SnapKit
import LarkUIKit

final class ThreadPostForwardDetailFooterView: UIView {
    let label = UILabel()
    let space: CGFloat = 32

    init(text: String = BundleI18n.LarkThread.Lark_Group_UnableToReplyNotGroupMember) {
        super.init(frame: .zero)
        setupView(text: text)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView(text: String) {
        addSubview(label)
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = text
        label.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(space)
            make.right.equalToSuperview().offset(-space)
            make.top.equalToSuperview().offset(11)
            make.bottom.equalToSuperview().offset(-24)
        }
    }

    func contentHeightForMaxWidth(_ width: CGFloat) -> CGFloat {
        guard let font = label.font, let text = label.text else {
            return 0
        }
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width - space * 2, height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.height) + 24 + 11 + (Display.iPhoneXSeries ? 34 : 0)
    }
}
