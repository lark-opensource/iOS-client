//
//  RedPacketHistoryNoDataView.swift
//  LarkFinance
//
//  Created by SuPeng on 12/25/18.
//

import Foundation
import UIKit
import UniverseDesignEmpty
import UniverseDesignFont

final class RedPacketHistoryNoDataView: UIView {

    private let descrpitionLabel = UILabel()

    init(type: SendReceiveType) {
        switch type {
        case .receive:
            descrpitionLabel.text = BundleI18n.LarkFinance.Lark_Legacy_HongbaoHistoryNeverReceived
        case .send:
            descrpitionLabel.text = BundleI18n.LarkFinance.Lark_Legacy_HistorySendEmpty
        }

        super.init(frame: .zero)

        backgroundColor = UIColor.ud.bgBody
        descrpitionLabel.textColor = UIColor.ud.textPlaceholder
        descrpitionLabel.font = UDFont.body2
        addSubview(descrpitionLabel)
        descrpitionLabel.snp.remakeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
