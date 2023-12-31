//
//  RedPacketResultSectionHeaderView.swift
//  Pods
//
//  Created by ChalrieSu on 2018/10/23.
//

import Foundation
import UIKit

final class RedPacketResultSectionHeaderView: UIView {

    private let containerView = UIView()
    private let splitArea = UIView()
    private let senderLabel = UILabel()

    init(text: String,
         sender: String?) {
        super.init(frame: .zero)

        backgroundColor = UIColor.clear

        containerView.addSubview(splitArea)
        splitArea.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(8)
        }
        splitArea.backgroundColor = UIColor.ud.bgBase
        splitArea.lu.addTopBorder(color: UIColor.ud.lineDividerDefault)
        splitArea.lu.addBottomBorder(color: UIColor.ud.lineDividerDefault)

        containerView.backgroundColor = UIColor.ud.bgBody
        addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textCaption
        label.text = text
        containerView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalTo(splitArea.snp.bottom).offset(8)
            make.left.equalTo(20)
            make.right.lessThanOrEqualToSuperview()
        }

        containerView.addSubview(senderLabel)
        senderLabel.textColor = UIColor.ud.textCaption
        senderLabel.font = UIFont.systemFont(ofSize: 12)
        senderLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-13)
            make.left.greaterThanOrEqualTo(containerView.snp.centerX)
        }
        if let sender = sender {
            senderLabel.text = BundleI18n.LarkFinance.Lark_DesignateRedPacket_RedPacketSentByName_CardText(sender)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
