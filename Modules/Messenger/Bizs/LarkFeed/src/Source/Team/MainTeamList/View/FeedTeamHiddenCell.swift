//
//  FeedTeamHiddenCell.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/10/27.
//

import Foundation
import UIKit
import SnapKit
import RustPB
import LarkModel
import EENavigator
import LarkUIKit
import LarkNavigator
import UniverseDesignColor

final class FeedTeamHiddenCell: UITableViewCell {
    static var identifier: String = "FeedTeamHiddenCell"
    var viewModel: FeedTeamChatItemViewModel?
    var highlightColor = UIColor.ud.fillHover
    let nameLabel = UILabel()

    public var selectedColor = UDMessageColorTheme.imFeedFeedFillActive

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        layout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.setBackViewColor(backgroundColor(highlighted))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.setBackViewColor(backgroundColor(selected))
    }

    func setupView() {
        selectionStyle = .none
        let bgColor = UIColor.ud.bgBody
        self.backgroundColor = .clear
        setupBackgroundViews(highlightOn: true)
        nameLabel.textColor = UIColor.ud.linkColor
        nameLabel.font = UIFont.ud.title4
        self.clipsToBounds = true
        self.contentView.clipsToBounds = true
    }

    func layout() {
        self.contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(76)
            make.centerY.equalToSuperview()
        }
    }

    func set(count: Int, mode: SwitchModeModule.Mode) {
        let leftInset: CGFloat
        switch mode {
        case .standardMode:
            leftInset = 36
        case .threeBarMode(_):
            leftInset = 16
        }
        nameLabel.snp.updateConstraints { make in
            make.leading.equalToSuperview().offset(leftInset)
        }
        self.nameLabel.text = BundleI18n.LarkFeed.Project_MV_NumberHiddenGroups(count)
    }
}

extension FeedTeamHiddenCell {
    func backgroundColor(_ highlighted: Bool) -> UIColor {
        var backgroundColor = UIColor.ud.fillHover

        let needShowSelected = (self.viewModel?.isSelected ?? false) &&
            self.horizontalSizeClass == .regular

        if FeedSelectionEnable && needShowSelected {
            backgroundColor = self.selectedColor
        } else {
            backgroundColor = highlighted ? self.highlightColor : UIColor.ud.bgBody
        }
        return backgroundColor
    }
}
