//
//  GridReorderTagView.swift
//  ByteView
//
//  Created by Tobb Huang on 2022/12/8.
//

import Foundation

class GridReorderTagView: UIView {

    lazy var alreadyReorderLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_VideoOrderAdjusted
        label.textColor = .ud.textTitle
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    lazy var syncButton: UIButton = {
        let button = UIButton()
        button.setTitle(I18n.View_G_SyncLatestOrder, for: .normal)
        button.setTitleColor(.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.contentEdgeInsets = .init(top: 0, left: 4, bottom: 0, right: 4)
        button.vc.setBackgroundColor(.clear, for: .normal)
        button.vc.setBackgroundColor(.ud.udtokenBtnTextBgPriPressed.withAlphaComponent(0.2), for: .highlighted)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.titleLabel?.numberOfLines = 1
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        return button
    }()

    lazy var abandonButton: UIButton = {
        let button = UIButton()
        button.setTitle(I18n.View_G_AdjustOrderLater, for: .normal)
        button.setTitleColor(.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.contentEdgeInsets = .init(top: 0, left: 4, bottom: 0, right: 4)
        button.vc.setBackgroundColor(.clear, for: .normal)
        button.vc.setBackgroundColor(.ud.udtokenBtnTextBgPriPressed.withAlphaComponent(0.2), for: .highlighted)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.titleLabel?.numberOfLines = 1
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .ud.vcTokenMeetingBgFloat
        self.layer.cornerRadius = 8
        self.layer.ud.setShadow(type: .s4Down)

        addSubview(alreadyReorderLabel)
        alreadyReorderLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(14)
            make.top.bottom.equalToSuperview().inset(10)
            make.height.equalTo(20)
        }

        addSubview(syncButton)
        syncButton.snp.makeConstraints { make in
            make.left.equalTo(alreadyReorderLabel.snp.right).offset(24)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }

        addSubview(abandonButton)
        abandonButton.snp.makeConstraints { make in
            make.left.equalTo(syncButton.snp.right).offset(6)
            make.right.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
