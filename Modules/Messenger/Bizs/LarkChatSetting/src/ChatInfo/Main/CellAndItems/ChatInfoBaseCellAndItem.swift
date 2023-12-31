//
//  ChatInfoBaseCellAndItem.swift
//  Lark
//
//  Created by K3 on 2018/8/9.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit

typealias ChatInfoAvatarEditHandler = () -> Void
typealias ChatInfoTapHandler = (_ cell: UITableViewCell) -> Void
typealias ChatInfoSwitchHandler = (_ switchControl: LoadingSwitch, _ status: Bool) -> Void
typealias ChatInfoHelpButtonHandler = () -> Void

class ChatInfoCell: BaseSettingCell, CommonCellProtocol {
    fileprivate(set) var separater: UIView = .init()
    fileprivate(set) var arrow: UIImageView = .init(image: nil)
    private var tapIdentify: String?
    var canHandleEvent: Bool {
        self.tapIdentify == item?.tapIdentify
    }

    var item: CommonCellItemProtocol? {
        didSet {
            setCellInfo()
        }
    }

    func setCellInfo() {
        assert(false, "没有实现对应的填充方法")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        separater = UIView()
        separater.backgroundColor = UIColor.ud.lineDividerDefault
        separater.isHidden = true
        contentView.addSubview(separater)

        arrow = UIImageView(image: Resources.right_arrow)
        contentView.addSubview(arrow)
        arrow.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().offset(-16)
            maker.width.height.equalTo(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view != nil {
            self.tapIdentify = self.item?.tapIdentify
        }
        return view
    }

    func layoutSeparater(_ style: SeparaterStyle) {
        if style == .none {
            separater.isHidden = true
        } else {
            separater.isHidden = false
            separater.snp.remakeConstraints { (maker) in
                maker.bottom.right.equalToSuperview()
                maker.height.equalTo(0.5)
                maker.left.equalToSuperview().offset(style == .half ? 16 : 0)
            }
        }
    }

    func updateAvailableMaxWidth(_ width: CGFloat) {}
}
