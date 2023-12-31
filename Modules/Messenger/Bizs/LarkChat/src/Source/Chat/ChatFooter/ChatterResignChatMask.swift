//
//  ChatterResignChatMask.swift
//  LarkChat
//
//  Created by zc09v on 2018/8/31.
//

import UIKit
import Foundation
import LarkMessageCore

final class ChatterResignChatMask: UIView {
    private static let resignLabelHeight: CGFloat = 55

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.N00
        /// 离职视图需要适配安全区域
        self.snp.makeConstraints { (make) in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.bottom)
                .offset(-ChatterResignChatMask.resignLabelHeight)
        }
        let label = UILabel()
        label.text = BundleI18n.LarkChat.Lark_Legacy_ChatterResignPermissionMask
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.N500
        label.textAlignment = .center
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(ChatterResignChatMask.resignLabelHeight)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
