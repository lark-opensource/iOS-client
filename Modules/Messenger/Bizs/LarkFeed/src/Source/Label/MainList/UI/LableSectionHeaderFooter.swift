//
//  LableSectionHeaderFooter.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import Foundation
import UIKit
import LarkSwipeCellKit
import RxSwift
import SnapKit
import LarkBizAvatar
import LarkZoomable
import LarkSceneManager
import ByteWebImage
import RustPB
import LarkModel
import LarkBadge
import UniverseDesignDialog
import EENavigator
import LarkInteraction
import LarkOpenFeed

final class LableSectionHeader: UITableViewHeaderFooterView {

    var actionHandlerAdapter: LabelMainListActionHandlerAdapter?
    var viewModel: LabelViewModel?
    var section: Int?
    var displayLine: Bool = false

    static let identifier: String = "LableSectionHeader"
    private var context: FeedContextService?
    private let arrowImageView = UIImageView()
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    let moreButton = UIButton()
    private let separatorView = UIView()
    private let badgeView = BadgeView(with: .label(.number(0)))

    var isExpanded: Bool = false
    private var arrowConfig: (Bool, CGFloat, CGFloat) = (false, 16, 12)

    private static let downsampleSize = CGSize(width: 36, height: 36)

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(viewModel: LabelViewModel,
             isExpanded: Bool,
             displayLine: Bool,
             section: Int,
             labelContext: LabelMainListContext) {
        guard let page = labelContext.vc else { return }

        self.viewModel = viewModel
        self.displayLine = displayLine
        self.section = section
        self.isExpanded = isExpanded
        self.nameLabel.text = viewModel.meta.feedGroup.name
        if !isExpanded, let badgeInfo = viewModel.badgeInfo {
            badgeView.isHidden = false
            badgeView.type = badgeInfo.type
            badgeView.style = badgeInfo.style
        } else {
            badgeView.isHidden = true
        }
        layoutExpanded(isExpanded, displayLine: displayLine)

        let mode = page.vm.switchModeModule.mode
        self.arrowConfig = viewModel.getArrowConfig(mode: mode)
        arrowImageView.isHidden = arrowConfig.0
        arrowImageView.snp.updateConstraints { (make) in
            make.leading.equalToSuperview().offset(arrowConfig.1)
            make.size.equalTo(arrowConfig.2)
        }
        self.actionHandlerAdapter = page.actionHandlerAdapter
    }

    @objc
    private func expandAction() {
        guard let viewModel = self.viewModel, let section = section, !arrowConfig.0 else { return }
        layoutExpanded(isExpanded, displayLine: displayLine)
        actionHandlerAdapter?.expand(label: viewModel, section: section)
    }

    @objc
    private func moreAction() {
        guard let viewModel = self.viewModel, let section = section else { return }
        actionHandlerAdapter?.tryShowSheet(label: viewModel, header: self)
    }

    private func setupView() {
        let bgColor = UIColor.ud.bgBody
        self.backgroundColor = bgColor
        self.contentView.backgroundColor = bgColor

        let tapGes = UITapGestureRecognizer(target: self, action: #selector(expandAction))
        self.contentView.addGestureRecognizer(tapGes)

        avatarView.image = Resources.labelCustomOutlined
        arrowImageView.image = Resources.expandDownFilled
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = UIFont.ud.title3

        moreButton.setImage(Resources.feed_team_more, for: .normal)
        moreButton.addTarget(self, action: #selector(moreAction), for: .touchUpInside)

        badgeView.isHidden = true
        badgeView.setMaxNumber(to: 999)

        separatorView.backgroundColor = UIColor.ud.lineDividerDefault

        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .hover(preferredTintMode: .overlay, prefersShadow: true, prefersScaledContent: true))
            )
            self.moreButton.addLKInteraction(pointer)
            self.moreButton.lkPointerStyle = PointerStyle(
                effect: .highlight,
                shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                    return (CGSize(width: 36, height: 30), 8)
                }))
        }
    }

    private func layout() {
        contentView.addSubview(arrowImageView)
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(badgeView)
        contentView.addSubview(moreButton)
        contentView.addSubview(separatorView)

        arrowImageView.snp.makeConstraints { (make) in
            make.size.equalTo(arrowConfig.2)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(arrowConfig.1)
        }

        avatarView.snp.makeConstraints { make in
            make.leading.equalTo(arrowImageView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.width.equalTo(20)
            make.height.equalTo(20)
        }

        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(badgeView.snp.leading)
        }
        moreButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
            make.width.equalTo(8 + 20 + 8)
            make.trailing.equalToSuperview().offset(-8)
        }

        badgeView.setContentCompressionResistancePriority(.required, for: .horizontal)
        badgeView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(moreButton.snp.leading).offset(-2)
        }

        separatorView.snp.makeConstraints { (make) in
            make.trailing.bottom.equalToSuperview()
            make.leading.equalTo(arrowImageView)
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    private func layoutExpanded(_ isExpanded: Bool, displayLine: Bool) {
        self.separatorView.isHidden = true
        let rotation = getRotation(isWillExpanded: isExpanded)
        UIView.animate(withDuration: 0.3, animations: {
            self.arrowImageView.transform = CGAffineTransform(rotationAngle: rotation)
        }) { _ in
            self.separatorView.isHidden = !displayLine
        }
    }

    private func getRotation(isWillExpanded: Bool) -> CGFloat {
        var targetRotation: CGFloat
        if isWillExpanded {
            // 将要展开
            targetRotation = 0
        } else {
            // 将要收起
            targetRotation = 1 * -(.pi / 2)
        }
        return targetRotation
    }
}

final class LableSectionFooter: UITableViewHeaderFooterView {
    static var identifier: String = "LableSectionFooter"
    let separatorView = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
        layout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        let bgColor = UIColor.ud.bgBody
        self.backgroundColor = bgColor
        self.contentView.backgroundColor = bgColor
        separatorView.backgroundColor = UIColor.ud.lineDividerDefault
    }

    func layout() {
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { (make) in
            make.trailing.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }
}
