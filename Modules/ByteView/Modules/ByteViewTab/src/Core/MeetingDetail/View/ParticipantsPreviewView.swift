//
//  ParticipantsPreviewView.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/2/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon
import ByteViewUI

@objc protocol ParticipantsPreviewViewDelegate: AnyObject {
    @objc optional func didTapParticipantsPreviewView(_ preview: ParticipantsPreviewView)
}

protocol AvatarProvider {
    var avatarInfo: AvatarInfo { get }
}

class ParticipantsPreviewView: UIStackView {

    private let cellDiameter: CGFloat = 24.0
    private var cellRadius: CGFloat = 12.0
    private var cellSpacing: CGFloat = 2.0
    private var font: UIFont = .systemFont(ofSize: 15)

    private var countOfParticipantsInCell = 5

    var isAutoResizingEnabled: Bool = false {
        didSet {
            cellRadius = (isAutoResizingEnabled ? CGFloat(cellDiameter) : cellDiameter) / 2.0
            setNeedsLayout()
        }
    }

    weak var delegate: ParticipantsPreviewViewDelegate?

    var countBackgroundColor: UIColor = UIColor.ud.N300.dynamicColor {
        didSet {
            countLabel.backgroundColor = countBackgroundColor
        }
    }
    var countTextColor: UIColor = UIColor.ud.textCaption {
        didSet {
            countLabel.textColor = countTextColor
        }
    }

    private var avatarViews: [AvatarView] = []
    lazy private var countLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = countTextColor
        label.textAlignment = .center
        label.font = font
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
         countOfParticipantsInCell: Int,
         font: UIFont) {
        super.init(frame: frame)
        self.cellRadius = cellRadius
        self.cellSpacing = cellSpacing
        self.countOfParticipantsInCell = countOfParticipantsInCell
        self.font = font
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
        delegate?.didTapParticipantsPreviewView?(self)
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

    func updateParticipants(_ participants: [AvatarProvider], totalCount: Int) {
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
            let isRoundLayout: Bool = totalCount < 1000 // 4位数（及以上）的情况异化显示逻辑
            if totalCount < 105 {
                countLabel.text = "+\(totalCount - maxCount)"
            } else {
                countLabel.text = "···"
            }

            addArrangedSubview(countBackgroundView)
            countBackgroundView.snp.makeConstraints { (maker) -> Void in
                maker.height.equalTo(2 * cellRadius)
                if isRoundLayout {
                    maker.width.equalTo(2 * cellRadius)
                }
            }
            countBackgroundView.addSubview(countLabel)
            countLabel.snp.makeConstraints { (maker) in
                maker.center.equalToSuperview()
                if !isRoundLayout {
                    maker.left.right.equalToSuperview().inset(4.0)
                }
            }
        }
    }

    private func imageView(for participant: AvatarProvider, eclipse: Bool = true) -> AvatarView {
        let imageView = AvatarView()
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
