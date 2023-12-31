//
//  SelectTranslateHeadView.swift
//  LarkAI
//
//  Created by zhaoyujie on 2022/8/3.
//

import Foundation
import UIKit
import RxSwift
import UniverseDesignIcon

protocol SelectTranslateHeadViewDelegate: AnyObject {
    /// ×号的点击事件
    func cancelFeedback()

}

private enum UI {
    static let dismissButtonHeight: CGFloat = 16
    static let dismissButtonWidth: CGFloat = 25
    static let dismissButtonRight: CGFloat = 21
    static let translateCardTitleFontSize: CGFloat = 17
}

final class SelectTranslateHeadView: UIView {
    /// 标题
    lazy var titleLabel: UILabel = {
        let titleLabel: UILabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: UI.translateCardTitleFontSize, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = BundleI18n.LarkAI.Lark_ASL_SelectTranslate_TranslationResult_TitleTranslate
        return titleLabel
    }()
    /// ×号
    private lazy var dismissButton: UIButton = {
        let dismissButton = UIButton(type: .custom)
        dismissButton.setImage(Resources.translate_close.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissButtonClick), for: .touchUpInside)
        return dismissButton
    }()

    private weak var delegate: SelectTranslateHeadViewDelegate?

    init(delegate: SelectTranslateHeadViewDelegate) {
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
            make.top.equalToSuperview().inset(26)
        }

        addSubview(dismissButton)
        dismissButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.size.equalTo(CGSize(width: UI.dismissButtonWidth, height: UI.dismissButtonHeight))
            make.left.equalToSuperview().offset(UI.dismissButtonRight)
        }
    }

    @objc
    func dismissButtonClick() {
        delegate?.cancelFeedback()
    }

}
