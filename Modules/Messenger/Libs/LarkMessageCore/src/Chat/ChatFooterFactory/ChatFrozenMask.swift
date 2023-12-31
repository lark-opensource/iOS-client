//
//  ChatFrozenMask.swift
//  LarkMessageCore
//
//  Created by zhaojiachen on 2023/3/1.
//

import UIKit
import Foundation

final public class ChatFrozenMask: UIView {
    private static let maskContentHeight: CGFloat = 62

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.N00

        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        let label = UILabel()
        label.text = BundleI18n.LarkMessageCore.Lark_IM_CantSendMsgThisDisbandedGrp_Desc
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        let contentLayoutGuide = UILayoutGuide()

        self.addLayoutGuide(contentLayoutGuide)
        self.addSubview(lineView)
        self.addSubview(label)
        lineView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale * 2)
        }
        contentLayoutGuide.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(Self.maskContentHeight)
            make.bottom.equalTo(self.safeAreaLayoutGuide)
        }
        label.snp.makeConstraints { (make) in
            make.center.equalTo(contentLayoutGuide)
            make.width.height.lessThanOrEqualTo(contentLayoutGuide)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
