//
//  VChatMeetingCardParticipantsPreview.swift
//  LarkChat
//
//  Created by LUNNER on 2019/3/5.
//

import UIKit
import RxSwift
import LarkBizAvatar
import UniverseDesignFont
import ByteViewCommon

protocol VChatMeetingCardParticipantsPreviewDelegate: AnyObject {
    func didTapVChatMeetingCardParticipantsPreview(_ participantsView: VChatMeetingCardParticipantsPreview)
}

extension VChatMeetingCardParticipantsPreviewDelegate {
    func didTapVChatMeetingCardParticipantsPreview(_ participantsView: VChatMeetingCardParticipantsPreview) {
        // this is a empty implementation to allow this method to be optional
    }
}

class VChatMeetingCardParticipantsPreview: UIStackView {

    private let cellDiameter: CGFloat = 24.0
    private var cellRadius: CGFloat = 12.0
    private var cellSpacing: CGFloat = 2.0

    var isAutoResizingEnabled: Bool = false {
        didSet {
            cellRadius = (isAutoResizingEnabled ? CGFloat(cellDiameter).roundAuto() : cellDiameter) / 2.0
            setNeedsLayout()
        }
    }

    private var countOfParticipantsInCell: Int = MeetingCardConstant.countOfParticipantsInCell

    weak var delegate: VChatMeetingCardParticipantsPreviewDelegate?

    var countBackgroundColor: UIColor = UIColor.ud.bgFiller {
        didSet {
            countBackgroundView.backgroundColor = countBackgroundColor
        }
    }
    var countTextColor: UIColor = UIColor.ud.textCaption {
        didSet {
            countLabel.textColor = countTextColor
        }
    }

    private var avatarViews: [BizAvatar] = []
    lazy private var countLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = countTextColor
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 10, weight: .medium)
        return label
    }()

    private lazy var countBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = countBackgroundColor
        view.layer.cornerRadius = cellRadius
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var eclipsePath: UIBezierPath = {
        // 从右下角的交点开始，先顺时针画左侧长弧线，再逆时针补充右侧短弧线
        // 相关计算请参考：https://bytedance.feishu.cn/docs/doccnbZDNj9cyn0C5szZ2jznotd
        let radius = self.cellRadius
        let spacing = self.cellSpacing

        let footPointToLeftCircleCenter: CGFloat = (4 * radius * radius + 3 * spacing * spacing - 10 * radius * spacing) / (4 * radius - 4 * spacing)
        let alphaCornerRadian: CGFloat = CGFloat(acos(footPointToLeftCircleCenter / radius))
        let leftCircleCenter: CGPoint = CGPoint(x: radius, y: radius)
        let leftCircleStartRadian: CGFloat = alphaCornerRadian
        let leftCircleEndRadian: CGFloat = CGFloat.pi * 2 - alphaCornerRadian

        let footPointToRightCircleCenter: CGFloat = 2 * radius - 2 * spacing - footPointToLeftCircleCenter
        let betaCornerRadian: CGFloat = CGFloat(acos(footPointToRightCircleCenter / (radius + spacing)))
        let rightCircleCenter: CGPoint = CGPoint(x: radius * 3 - spacing * 2, y: radius)
        let rightCircleStartRadian: CGFloat = CGFloat.pi + betaCornerRadian
        let rightCircleEndRadian: CGFloat = CGFloat.pi - betaCornerRadian

        let path = UIBezierPath(arcCenter: leftCircleCenter,
                                radius: radius,
                                startAngle: leftCircleStartRadian,
                                endAngle: leftCircleEndRadian,
                                clockwise: true)
        path.addArc(withCenter: rightCircleCenter,
                    radius: radius + spacing,
                    startAngle: rightCircleStartRadian,
                    endAngle: rightCircleEndRadian,
                    clockwise: false)
        path.close()
        return path
    }()

    private lazy var roundPath: UIBezierPath = {
        return UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 2 * cellRadius, height: 2 * cellRadius))
    }()

    init(frame: CGRect,
         cellRadius: CGFloat,
         cellSpacing: CGFloat,
         countOfParticipantsInCell: Int) {
        super.init(frame: frame)
        self.cellRadius = cellRadius
        self.cellSpacing = cellSpacing
        self.countOfParticipantsInCell = countOfParticipantsInCell
        initialize()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        manageAppearance()
    }

    @objc
    private func didTap() {
        delegate?.didTapVChatMeetingCardParticipantsPreview(self)
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
        spacing = -cellSpacing * 2 // 3.41之前横幅头像的布局比较紧凑，和UX确定在“字体大小一期”统一成会议卡片的头像布局
    }

    func updateParticipants(_ participants: [VChatPreviewedParticipant], totalCount: Int) {
        // remove old avaters
        while let view = avatarViews.popLast() {
            view.removeFromSuperview()
        }
        countBackgroundView.removeFromSuperview()
        // add new avaters
        let showCount = totalCount > countOfParticipantsInCell
        let maxCount = showCount ? countOfParticipantsInCell - 1 : countOfParticipantsInCell
        for index in 0 ..< min(maxCount, participants.count) {
            let eclipse = showCount ? true : index != min(maxCount, participants.count) - 1
            let avaterView = imageView(for: participants[index], eclipse: eclipse)
            avatarViews.append(avaterView)
            addArrangedSubview(avaterView)
        }
        if showCount {
            let count = totalCount - countOfParticipantsInCell + 1
            var countStr = (count > 99) ? "···" : "+\(count)"

            countLabel.text = countStr
            addArrangedSubview(countBackgroundView)
            countBackgroundView.snp.remakeConstraints { (maker) in
                maker.height.equalTo(2 * cellRadius)
                maker.width.equalTo(2 * cellRadius)
            }
            countBackgroundView.addSubview(countLabel)
            countLabel.snp.remakeConstraints { (maker) in
                maker.center.equalToSuperview()
                maker.left.right.equalToSuperview()
            }
        }
    }

    private func imageView(for participant: VChatPreviewedParticipant, eclipse: Bool = true) -> BizAvatar {
        let imageView = BizAvatar()
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = eclipse ? eclipsePath.cgPath : roundPath.cgPath
        imageView.layer.mask = shapeLayer
        imageView.setAvatarInfo(participant.avatarInfo)
        imageView.snp.makeConstraints { (make) in
            make.width.equalTo(2 * cellRadius)
            make.height.equalTo(2 * cellRadius)
        }
        return imageView
    }
}

private extension CGFloat {

    func roundAuto() -> CGFloat {
        let currentScale = UDZoom.currentZoom.scale
        return (self * currentScale).rounded()
    }
}

private extension BizAvatar {
    private static let logger = Logger.getLogger("Avatar")

    /// 设置头像
    /// - Parameters:
    ///   - info: 头像信息
    ///   - avatarSize: 头像大小，默认为.medium；如果头像的最长边超过98pt，此处应填.large
    func setAvatarInfo(_ info: AvatarInfo) {
        backgroundColor = UIColor.ud.N300
        switch info {
        case .remote(key: let remoteKey, entityId: let entityId):
            setAvatarByIdentifier(entityId, avatarKey: remoteKey, avatarViewParams: .defaultMiddle)
        case .asset(let image):
            avatar.image = image
            avatar.backgroundColor = .clear
        @unknown default:
            BizAvatar.logger.warn("set avatar info with unknown enum, no default execution.")
        }
    }
}
