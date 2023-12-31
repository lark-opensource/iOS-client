//
//  RecordWithTextButtonView.swift
//  LarkAudio
//
//  Created by 李晨 on 2020/2/4.
//

import Foundation
import UIKit
import LarkFeatureGating
import LarkContainer

protocol RecordWithTextButtonViewDelegate: AnyObject {
    func recordWithTextButtonViewClickCancel(buttonView: BaseRecordWithTextButtonView)
    func recordWithTextButtonViewClickSendAll(buttonView: BaseRecordWithTextButtonView)
    func recordWithTextButtonViewClickSendAudio(buttonView: BaseRecordWithTextButtonView)
    func recordWithTextButtonViewClickSendText(buttonView: BaseRecordWithTextButtonView)
}

protocol BaseRecordWithTextButtonView {
    var stackView: UIStackView? { get set }
    var sessionId: String { get }
    var actionButton: BaseRecordWithTextActionView? { get set }

    func showActionsIfNeeded(stackInfo: StackViewInfo, animation: Bool, alpha: Bool, sendEnabled: Bool, showTipView: Bool)
    func showSendAllButtonLoading()
    func hideSendAllButtonLoading()
}

protocol BaseRecordWithTextActionView: UIView {
    var sendAudioButton: UIButton { get set }
    var sendAllButton: UIButton { get set }
    var sendTextButton: UIButton { get set }
    func setButtomInCenter()
    func setButtonAverage()
}

struct StackViewInfo {
    var stackView: UIStackView?
    var location: Int
}

final class RecordWithTextTipView: UIView {
    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView(image: Resources.warningIcon)
        return iconImageView
    }()
    private lazy var tipLabel: UILabel = {
        let tipLabel = UILabel()
        tipLabel.text = BundleI18n.LarkAudio.Lark_Chat_SendAudioAndTextPoorNetworkTip
        tipLabel.font = UIFont.systemFont(ofSize: 12)
        tipLabel.textColor = UIColor.ud.textTitle
        return tipLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUpSubViews() {

        addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.height.equalTo(18)
            make.center.equalToSuperview()
        }

        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.centerY.equalToSuperview()
            make.right.equalTo(tipLabel.snp.left).offset(-4)
        }
    }
}
