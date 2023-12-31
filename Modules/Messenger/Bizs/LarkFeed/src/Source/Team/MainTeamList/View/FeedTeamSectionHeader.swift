//
//  FeedTeamSectionHeader.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
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

protocol FeedTeamSectionHeaderDelegate: AnyObject {
    func expandAction(_ header: FeedTeamSectionHeader, team: FeedTeamItemViewModel)
    func moreAction(_ header: FeedTeamSectionHeader, team: FeedTeamItemViewModel)
}

final class FeedTeamSectionHeader: UITableViewHeaderFooterView {
    static var identifier: String = "FeedTeamSectionHeader"
    var viewModel: FeedTeamItemViewModel?
    weak var delegate: FeedTeamSectionHeaderDelegate?
    private var context: FeedContextService?
    private let arrowImageView = UIImageView()
    private let avatarView = BizAvatar()
    private let nameLabel = UILabel()
    let moreButton = UIButton()
    private let separatorView = UIView()
    private let badgeView = BadgeView(with: .label(.number(0)))
    private var eventID: Int64 = 0

    private static let downsampleSize = CGSize(width: 24, height: 24)

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
        layout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let bgColor = UIColor.ud.bgBody
        self.backgroundColor = bgColor
        self.contentView.backgroundColor = bgColor

        let tapGes = UITapGestureRecognizer(target: self, action: #selector(expandAction))
        self.contentView.addGestureRecognizer(tapGes)

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
            make.size.equalTo(12)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }

        avatarView.snp.makeConstraints { make in
            make.leading.equalTo(arrowImageView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(Self.downsampleSize)
        }

        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
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
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    func set(_ viewModel: FeedTeamItemViewModel, context: FeedContextService?, mode: SwitchModeModule.Mode) {
        switch mode {
        case .standardMode:
            arrowImageView.isHidden = false
            arrowImageView.snp.updateConstraints { (make) in
                make.size.equalTo(12)
                make.leading.equalToSuperview().offset(16)
            }
        case .threeBarMode(_):
            arrowImageView.isHidden = true
            arrowImageView.snp.updateConstraints { (make) in
                make.leading.equalToSuperview().offset(16 - 8)
                make.size.equalTo(0)
            }
        }
        self.viewModel = viewModel
        self.context = context
        let entityId = String(viewModel.teamEntity.id)
        let avatarKey = viewModel.teamEntity.avatarKey
        if (!entityId.isEmpty) && (!avatarKey.isEmpty) {
            avatarView.setAvatarByIdentifier(
                entityId,
                avatarKey: avatarKey,
                scene: .Feed,
                options: [.downsampleSize(Self.downsampleSize)],
                avatarViewParams: .init(sizeType: .size(Self.downsampleSize.width)),
                completion: { result in
                    if case let .failure(error) = result {
                        FeedContext.log.error("teamlog/image/team. \(viewModel.teamEntity.id), \(error)")
                    }
                })
        } else {
            avatarView.image = nil
        }
        self.nameLabel.text = viewModel.teamEntity.name

        if !viewModel.isExpanded, let badgeInfo = viewModel.badgeInfo {
            badgeView.isHidden = false
            badgeView.type = badgeInfo.type
            badgeView.style = badgeInfo.style
        } else {
            badgeView.isHidden = true
        }
        layoutExpanded(viewModel.isExpanded)
    }

    private func layoutExpanded(_ isExpanded: Bool) {
        self.separatorView.isHidden = true
        let rotation = getRotation(isWillExpanded: isExpanded)
        UIView.animate(withDuration: 0.3, animations: {
            self.arrowImageView.transform = CGAffineTransform(rotationAngle: rotation)
        }) { _ in
            if !isExpanded {
                self.separatorView.isHidden = false
            }
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

    @objc
    private func expandAction() {
        guard preCheck() else { return }
        guard let vm = self.viewModel, !arrowImageView.isHidden else { return }
        FeedContext.log.info("teamlog/action/header/expand. team: \(vm.teamEntity.id), \(!vm.isExpanded)")
        layoutExpanded(!vm.isExpanded)
        delegate?.expandAction(self, team: vm)
    }

    @objc
    private func moreAction() {
        guard preCheck() else { return }
        guard let vm = self.viewModel else { return }
        delegate?.moreAction(self, team: vm)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event) else {
            self.eventID = 0
            return nil
        }
        self.eventID = self.viewModel?.teamEntity.id ?? 0
        return view
    }

    private func preCheck() -> Bool {
        return self.eventID == self.viewModel?.teamEntity.id
    }
}
