//
//  ParticipantsTileView.swift
//  ByteView
//
//  Created by chentao on 2019/6/30.
//

import UIKit
import ByteViewCommon
import ByteViewUI
import ByteViewNetwork
import UniverseDesignIcon

final class ParticipantsTileView: UIStackView {
    private var maxNumberInPreview: Int = 6
    private var itemRadius: CGFloat = 20
    private var itemSpacing: CGFloat = 8
    var tappedAction: (([PreviewParticipant]) -> Void)?

    private var avatarViews: [AvatarView] = []
    lazy private var countLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor.ud.textCaption
        label.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.layer.cornerRadius = itemRadius
        label.layer.masksToBounds = true
        return label
    }()

    lazy private var moreImageView: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.isUserInteractionEnabled = false
        button.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
        button.layer.masksToBounds = true
        button.setImage(UDIcon.getIconByKey(.moreOutlined, iconColor: .ud.iconN2, size: CGSize(width: 12, height: 12)), for: .normal)
        return button
    }()

    private var showCount: Bool {
        return participants.count > maxNumberInPreview
    }

    private lazy var avatarPath: UIBezierPath = {
        let angle = CGFloat(acos((itemRadius + itemSpacing) / itemRadius))
        return eclipsePath(center: CGPoint(x: 0.5 * avatarWidth, y: itemRadius),
                           radius: avatarWidth * 0.5,
                           angle: angle)
    }()

    private var avatarWidth: CGFloat {
        return itemSpacing < 0 ? 2 * itemRadius + itemSpacing : 2 * itemRadius
    }

    var participants: [PreviewParticipant] = [] {
        didSet {
            updateParticipants(participants)
            setNeedsLayout()
        }
    }

    init(frame: CGRect, itemRadius: CGFloat, itemSpacing: CGFloat, maxNumberInPreview: Int) {
        super.init(frame: frame)
        self.itemRadius = itemRadius
        self.itemSpacing = itemSpacing
        self.maxNumberInPreview = maxNumberInPreview
        initialize()
    }

    init() {
        super.init(frame: .zero)
        initialize()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didTap() {
        if let action = tappedAction {
            action(participants)
        }
    }

    private func initialize() {
        manageAppearance()
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    private func manageAppearance() {
        axis = .horizontal
        alignment = .center
        distribution = .fillProportionally
        spacing = itemSpacing < 0 ? 0 : itemSpacing
    }

    private func updateParticipants(_ participants: [PreviewParticipant]) {
        // remove old avaters
        for avaterView in avatarViews {
            avaterView.removeFromSuperview()
        }
        avatarViews.removeAll()
        countLabel.removeFromSuperview()
        moreImageView.removeFromSuperview()

        let maxCount = showCount ? maxNumberInPreview - 1 : maxNumberInPreview
        // add new avaters
        let height = 2 * itemRadius
        for index in 0 ..< min(maxCount, participants.count) {
            let eclipse = showCount ? true : index != min(maxCount, participants.count) - 1
            let avaterView = imageView(for: participants[index], eclipse: eclipse)
            avatarViews.append(avaterView)
            addArrangedSubview(avaterView)
            let avaterWidth = eclipse ? avatarWidth : height
            let avaterHeight = height
            avaterView.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(avaterWidth)
                make.height.equalTo(avaterHeight)
            }
        }
        if showCount {
            if participants.count > 999 {
                moreImageView.isHidden = false
                countLabel.isHidden = true
                addArrangedSubview(moreImageView)
                moreImageView.layer.cornerRadius = height / 2
                moreImageView.snp.makeConstraints { (make) -> Void in
                    make.width.equalTo(height)
                    make.height.equalTo(height)
                }
            } else {
                moreImageView.isHidden = true
                countLabel.isHidden = false
                countLabel.text = "+\(participants.count - maxCount)"
                addArrangedSubview(countLabel)
                countLabel.snp.makeConstraints { (make) -> Void in
                    make.width.equalTo(height)
                    make.height.equalTo(height)
                }
            }
        }
    }

    private func imageView(for participant: PreviewParticipant, eclipse: Bool = true) -> AvatarView {
        let imageView = AvatarView()
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = eclipse ? avatarPath.cgPath : eclipsePath(center: CGPoint(x: itemRadius, y: itemRadius),
                                                                    radius: avatarWidth * 0.5,
                                                                    angle: 0).cgPath
        imageView.layer.mask = shapeLayer
        imageView.setAvatarInfo(participant.avatarInfo)
        return imageView
    }

    private func eclipsePath(center: CGPoint, radius: CGFloat, angle: CGFloat) -> UIBezierPath {
        guard angle > 0, angle <= CGFloat.pi * 0.5 else {
            return UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: 0,
                                endAngle: CGFloat.pi * 2,
                                clockwise: false)
        }
        let spacing = cos(angle) * radius
        var anoterCenter = center
        anoterCenter.x = center.x + 2 * spacing
        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: angle,
                                endAngle: 2 * CGFloat.pi - angle,
                                clockwise: true)
        path.addArc(withCenter: anoterCenter,
                    radius: radius,
                    startAngle: CGFloat.pi + angle,
                    endAngle: CGFloat.pi - angle,
                    clockwise: false)
        path.close()
        return path
    }

}
