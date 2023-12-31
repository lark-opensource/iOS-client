//
//  PadToolBarNotesView.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/9/13.
//

import Foundation
import ByteViewUI
import UniverseDesignIcon
import ByteViewCommon

struct NotesCollaboratorInfo: Equatable {
    /// 正在显示头像的协作者
    let showAvatarCollaborator: NotesCollaborator?
    /// 协作者数量
    let collaboratorsCount: NSInteger
    /// 默认无协作者
    static let `default` = NotesCollaboratorInfo(showAvatarCollaborator: nil,
                                                  collaboratorsCount: 0)
}

class PadToolBarNotesView: PadToolBarTitledView {

    var collaboratorsInfo: NotesCollaboratorInfo = .default {
        didSet {
            Logger.notes.info("collaboratorsInfo did changed to: \(collaboratorsInfo)")
            superview?.setNeedsLayout()
        }
    }

    let collaboratorsView: NotesCollaboratorsView = {
        let view = NotesCollaboratorsView()
        return view
    }()

    override func setupSubviews() {
        super.setupSubviews()
        button.addSubview(collaboratorsView)
        if let item = self.item as? ToolBarNotesItem {
            Logger.notes.info("in setupSubviews, will update collaboratorsInfo")
            self.collaboratorsInfo = item.notesCollaboratorsInfo ?? .default
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collaboratorsView.isHidden = !(collaboratorsInfo.collaboratorsCount > 0)
        collaboratorsView.frame = CGRect(x: 12 + 20 + 6 + itemTitleWidth + 6, y: 10, width: collaboratorsViewWidth, height: 20)
        collaboratorsView.updateDisplayParams(collaboratorsInfo)
    }

    override var itemWidth: CGFloat {
        showTitle ? 12 + 20 + 6 + itemTitleWidth + spaceBeforeCollaboratorsView + collaboratorsViewWidth + 12 : 40
    }


    private var spaceBeforeCollaboratorsView: CGFloat {
        return collaboratorsInfo.collaboratorsCount == 0 ? 0 : 6
    }

    private var collaboratorsViewWidth: CGFloat {
        guard collaboratorsInfo.collaboratorsCount >= 0 else { return 0 }
        switch collaboratorsInfo.collaboratorsCount {
        case 0: return 0
        case 1: return 20
        default: return 36
        }
    }

}

class NotesCollaboratorsView: UIView {

    static let moreIcon = UDIcon.getIconByKey(.moreOutlined,
                                              iconColor: .ud.textCaption,
                                              size: CGSize(width: 12, height: 12))

    var displayParams: NotesCollaboratorInfo = .default

    // MARK: - Views Defines

    let horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.spacing = -4
        stackView.distribution = .fill
        return stackView
    }()

    /// 协作者头像
    let avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = ByteViewCommon.BundleResources.ByteViewCommon.Avatar.unknown
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        return imageView
    }()

    /// 协作者数量背景
    let roundBgView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.bgBody
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()

    /// 协作者数量在2～100之间显示的“+N”
    let collaboratorsCountLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.textColor = .ud.textCaption
        return label
    }()

    /// 超过100人后显示的“···”
    lazy var moreImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Self.moreIcon
        imageView.isHidden = true
        return imageView
    }()

    // MARK: - Allocations

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layouts

    private func setupViews() {
        addSubview(horizontalStackView)
        horizontalStackView.addArrangedSubview(avatarView)
        horizontalStackView.addArrangedSubview(roundBgView)
        roundBgView.addSubview(collaboratorsCountLabel)
        roundBgView.addSubview(moreImageView)

        horizontalStackView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }
        avatarView.snp.remakeConstraints {
            $0.size.equalTo(20)
        }
        roundBgView.snp.remakeConstraints {
            $0.size.equalTo(20)
        }
        collaboratorsCountLabel.snp.remakeConstraints {
            $0.center.equalToSuperview()
        }
        moreImageView.snp.remakeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(12)
        }
    }

    func updateDisplayParams(_ displayParams: NotesCollaboratorInfo) {
        self.displayParams = displayParams
        reloadHiddens()
        reloadCollaboratorsText()
        updateAvatarEclipseStyle()
    }

    private func updateAvatarEclipseStyle() {
        let count = displayParams.collaboratorsCount >= 0 ? displayParams.collaboratorsCount : 0
        if count > 1 {
            let eclipseShapeLayer = CAShapeLayer()
            eclipseShapeLayer.path = avatarPath.cgPath
            avatarView.layer.mask = eclipseShapeLayer
        } else {
            let roundShapeLayer = CAShapeLayer()
            roundShapeLayer.path = roundPath.cgPath
            avatarView.layer.mask = roundShapeLayer
        }
    }

    private lazy var roundPath: UIBezierPath = {
        return roundPath(center: CGPoint(x: 10, y: 10),
                           radius: 10,
                           angle: 0)
    }()

    private lazy var avatarPath: UIBezierPath = {
        return eclipsePath(center1: CGPoint(x: 10, y: 10),
                           center2: CGPoint(x: 26, y: 10),
                           radius1: 10,
                           radius2: 12,
                           angle1: CGFloat(acos(6.5 / 10)),
                           angle2: CGFloat(acos(9.5 / 12)))
    }()

    private func reloadHiddens() {
        let count = displayParams.collaboratorsCount >= 0 ? displayParams.collaboratorsCount : 0
        roundBgView.isHidden = (count < 2)
    }

    private func reloadCollaboratorsText() {
        let count = displayParams.collaboratorsCount >= 0 ? displayParams.collaboratorsCount : 0
        if count <= 100 {
            collaboratorsCountLabel.isHidden = false
            moreImageView.isHidden = true
            collaboratorsCountLabel.text = "+\(count - 1)"
        } else {
            collaboratorsCountLabel.isHidden = true
            moreImageView.isHidden = false
        }
        avatarView.vc.setImage(url: displayParams.showAvatarCollaborator?.avatarUrl ?? "",
                               accessToken: "")
    }

    private func roundPath(center: CGPoint, radius: CGFloat, angle: CGFloat) -> UIBezierPath {
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

    private func eclipsePath(center1: CGPoint, center2: CGPoint, radius1: CGFloat, radius2: CGFloat, angle1: CGFloat, angle2: CGFloat) -> UIBezierPath {
        let path = UIBezierPath(arcCenter: center1,
                                radius: radius1,
                                startAngle: angle1,
                                endAngle: 2 * CGFloat.pi - angle1,
                                clockwise: true)
        path.addArc(withCenter: center2,
                    radius: radius2,
                    startAngle: CGFloat.pi + angle2,
                    endAngle: CGFloat.pi - angle2,
                    clockwise: false)
        path.close()
        return path
    }

}
