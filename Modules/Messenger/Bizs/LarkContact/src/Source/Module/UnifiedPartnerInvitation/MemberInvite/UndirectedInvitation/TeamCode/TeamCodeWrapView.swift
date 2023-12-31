//
//  TeamCodeWrapView.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/4/27.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import LKCommonsLogging
import RxSwift

final class TeamCodeWrapView: UIView, CardBindable {

    private lazy var teamCodeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    init() {
        super.init(frame: .zero)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .ud.bgFloatOverlay
        layer.cornerRadius = IGLayer.commonPopPanelRadius

        addSubview(teamCodeLabel)
        teamCodeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
        }
    }

    func bindWithModel(cardInfo: InviteAggregationInfo) {
        guard let memberExtra = cardInfo.memberExtraInfo else {
            return
        }
        let attributedString = NSMutableAttributedString(string: memberExtra.teamCode,
                                                         attributes: [
                                                            .kern: 8.0
                                                         ])
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributedString.addAttributes([.paragraphStyle: paragraphStyle,
                                        .font: UIFont.boldSystemFont(ofSize: 30),
                                        .foregroundColor: UIColor.ud.textTitle],
                                       range: NSRange(location: 0, length: memberExtra.teamCode.count))
        teamCodeLabel.attributedText = attributedString
    }

}
