//
//  MessageFeedBackHeadView.swift
//  LarkChat
//
//  Created by bytedance on 2020/8/25.
//

import Foundation
import UIKit
import RxSwift
import UniverseDesignIcon

protocol MessageTranslateFeedbackHeadViewDelegate: AnyObject {
    /// ×号的点击事件
    func cancelFeedback()

}

private enum UI {
    static let dismissButtonHeight: CGFloat = 16
    static let dismissButtonWidth: CGFloat = 25
    static let dismissButtonRight: CGFloat = 21
}

final class MessageTranslateFeedbackHeadView: UIView {

    /// 标题
    lazy var titleLabel: UILabel = {
        let titleLabel: UILabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = BundleI18n.LarkAI.Lark_Chat_TranslationFeedbackTitle
        return titleLabel
    }()
    /// ×号
    private lazy var dismissButton: UIButton = {
        let dismissButton = UIButton(type: .custom)
        dismissButton.setImage(Resources.translate_close, for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissButtonClick), for: .touchUpInside)
        return dismissButton
    }()

    private weak var delegate: MessageTranslateFeedbackHeadViewDelegate?

    public init(delegate: MessageTranslateFeedbackHeadViewDelegate) {
        self.delegate = delegate
        super.init(frame: CGRect.zero)
        setupSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubViews() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(14)
        }

        addSubview(dismissButton)
        dismissButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: UI.dismissButtonWidth, height: UI.dismissButtonHeight))
            make.left.equalToSuperview().offset(UI.dismissButtonRight)
        }
    }

    @objc
    func dismissButtonClick() {
        delegate?.cancelFeedback()
    }

}
