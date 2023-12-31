//
//  FilterTabArchivedNoticeView.swift
//  Todo
//
//  Created by baiyantao on 2023/2/16.
//

import Foundation
import UniverseDesignButton
import UniverseDesignIcon
import UniverseDesignFont

final class FilterTabArchivedNoticeView: UIView {

    var canEdit = false {
        didSet {
            guard oldValue != canEdit else { return }
            unarchiveBtn.isHidden = !canEdit
        }
    }

    var unarchiveHandler: (() -> Void)?

    private lazy var iconView = initIconView()
    private lazy var titlLabel = initTitleLabel()
    private lazy var unarchiveBtn = initUnarchiveBtn()

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBase

        addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.left.equalToSuperview().offset(16)
            $0.width.height.equalTo(16)
        }
        addSubview(unarchiveBtn)
        unarchiveBtn.snp.makeConstraints {
            $0.centerY.equalTo(iconView)
            $0.right.equalToSuperview().offset(-16)
        }
        addSubview(titlLabel)
        titlLabel.snp.makeConstraints {
            $0.centerY.equalTo(iconView)
            $0.left.equalTo(iconView.snp.right).offset(8)
            $0.right.lessThanOrEqualTo(unarchiveBtn.snp.left).offset(-8)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initIconView() -> UIImageView {
        let view = UIImageView()
        view.image = UDIcon.massageBoxOutOutlined
            .ud.withTintColor(UIColor.ud.iconN2)
        return view
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 14)
        label.text = I18N.Todo_TaskList_Archived_BotTitle
        label.numberOfLines = 1
        return label
    }

    private func initUnarchiveBtn() -> UIButton {
        var config = UDButtonUIConifg.secondaryGray
        config.normalColor = UDButtonUIConifg.ThemeColor(
            borderColor: UIColor.ud.lineBorderComponent,
            backgroundColor: UIColor.ud.bgFloat,
            textColor: UIColor.ud.textTitle
        )
        let button = UDButton(config)
        button.setTitle(I18N.Todo_TaskList_Restore_Button, for: .normal)
        button.addTarget(self, action: #selector(onUnarchiveBtnClick), for: .touchUpInside)
        return button
    }

    @objc
    private func onUnarchiveBtnClick() {
        unarchiveHandler?()
    }
}
