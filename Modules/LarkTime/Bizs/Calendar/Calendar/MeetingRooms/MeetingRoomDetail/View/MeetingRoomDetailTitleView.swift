//
//  MeetingRoomDetailTitleView.swift
//  Calendar
//
//  Created by LiangHongbin on 2021/1/13.
//

import UIKit
import UniverseDesignIcon
import Foundation
import LarkLocalizations
import UniverseDesignFont
import UniverseDesignColor
import RichLabel

extension MeetingRoomStatus {
    typealias Colors = (light: UIColor, normal: UIColor, dark: UIColor)
    typealias StateInfo = (colors: Colors, stateText: String, image: UIImage)

    func getStateInfo() -> StateInfo {
        switch self {
        case .canReserve:
            let colors: Colors = (light: UIColor.ud.G50, normal: UIColor.ud.G100, dark: UIColor.ud.G600)
            return (colors: colors, stateText: BundleI18n.Calendar.Calendar_Edit_MeetingRoomCanBeReserve, image: UDIcon.getIconByKeyNoLimitSize(.roomOutlined).ud.withTintColor(UIColor.ud.G600))
        case .inUse:
            let colors: Colors = (light: UIColor.ud.R50, normal: UIColor.ud.R100, dark: UIColor.ud.R600)
            return (colors: colors, stateText: BundleI18n.Calendar.Calendar_Edit_MeetingRoomReserved, image: UDIcon.getIconByKeyNoLimitSize(.roomOutlined).ud.withTintColor(UIColor.ud.colorfulRed))
        case .canNotReserve:
            let colors: Colors = (light: UIColor.ud.N100, normal: UIColor.ud.textDisabled, dark: UIColor.ud.N600)
            return (colors: colors, stateText: BundleI18n.Calendar.Calendar_Edit_MeetingRoomCantReserve, image: UDIcon.getIconByKeyNoLimitSize(.roomUnavailableOutlined).renderColor(with: .n3))
        @unknown default:
            let colors: Colors = (light: UIColor.ud.G50, normal: UIColor.ud.G100, dark: UIColor.ud.G600)
            return (colors: colors, stateText: BundleI18n.Calendar.Calendar_Edit_MeetingRoomCanBeReserve, image: UDIcon.getIconByKeyNoLimitSize(.roomOutlined).ud.withTintColor(UIColor.ud.G600))
        }
    }
}

protocol MeetingRoomDetailTitleViewDataType {
    var title: String { get }
    var subTitle: String { get }
    var roomState: MeetingRoomStatus? { get }
}

final class MeetingRoomDetailTitleView: UIView, ViewDataConvertible {
    var viewData: MeetingRoomDetailTitleViewDataType? {
        didSet {
            guard let viewData = viewData else { return }

            if oldValue?.title != viewData.title {
                titleLabel.text = viewData.title
            }
            if oldValue?.subTitle != viewData.subTitle {
                subTitleLabel.text = viewData.subTitle
                let subTitleAttrString = NSAttributedString(string: viewData.subTitle, attributes: [
                    .font: UDFont.body0(.fixed),
                    .foregroundColor: UDColor.textTitle
                ])
                subTitleLabel.attributedText = subTitleAttrString
            }

            guard let roomState = viewData.roomState else {
                roomStateView.isHidden = true
                roomStateView.removeFromSuperview()
                titleLabel.snp.remakeConstraints {
                    $0.left.equalToSuperview().offset(16)
                    $0.top.equalToSuperview().offset(12)
                    $0.height.greaterThanOrEqualTo(34)
                    $0.right.equalToSuperview().offset(-16)
                }
                subTitleLabel.snp.remakeConstraints {
                    $0.left.equalTo(titleLabel.snp.left)
                    $0.top.equalTo(titleLabel.snp.bottom)
                    $0.right.equalToSuperview().offset(-16)
                    $0.bottom.equalToSuperview().offset(-20)
                    $0.height.greaterThanOrEqualTo(22)
                }
                return
            }
            if oldValue?.roomState != roomState {
                addSubview(roomStateView)
                roomStateView.snp.makeConstraints {
                    $0.right.equalToSuperview().offset(-16)
                    $0.top.equalToSuperview().offset(12)
                    $0.bottom.lessThanOrEqualToSuperview().offset(-20)
                    // 设计认为目前只支持中英日三种语言，有需要（lable显示不全）可能会改图标
                    let isEnglish = LanguageManager.currentLanguage == .en_US
                    $0.size.equalTo(CGSize(width: isEnglish ? 68 : 64, height: 64))
                }
                roomStateView.state = roomState
            }
        }
    }

    var titleLabel = UILabel()

    lazy var subTitleLabel: LKLabel = {
        let label = LKLabel()
        label.font = UDFont.body0(.fixed)
        label.textColor = UDColor.textTitle
        label.numberOfLines = 3
        label.delegate = self

        // "更多"
        let moreStr = NSAttributedString(string: "\u{2026}", attributes: [
            .foregroundColor: UDColor.textTitle,
            .font: UDFont.body0(.fixed)
        ])

        let expand = NSAttributedString(string: I18n.Calendar_Onboarding_Show, attributes: [
            .font: UDFont.body0(.fixed),
            .foregroundColor: UDColor.primaryContentDefault
        ])

        let builder = NSMutableAttributedString(attributedString: moreStr)
        builder.append(expand)

        label.outOfRangeText = NSAttributedString(attributedString: builder)

        label.backgroundColor = .clear
        return label
    }()

    var roomStateView = RoomStateView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(subTitleLabel)
        addSubview(roomStateView)

        titleLabel.font = UIFont.ud.title0(.fixed)
        titleLabel.numberOfLines = 0

        titleLabel.snp.makeConstraints {
            $0.left.top.equalToSuperview().offset(12)
            $0.right.equalTo(roomStateView.snp.left).offset(-16)
            $0.height.greaterThanOrEqualTo(34)
        }

        subTitleLabel.snp.makeConstraints {
            $0.left.equalTo(titleLabel.snp.left)
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.right.equalTo(roomStateView.snp.left).offset(-16)
            $0.bottom.lessThanOrEqualToSuperview().offset(-20)
            $0.height.greaterThanOrEqualTo(22)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let preferredMaxLayoutWidth = subTitleLabel.frame.maxX - subTitleLabel.frame.minX
        subTitleLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        subTitleLabel.invalidateIntrinsicContentSize()
        subTitleLabel.setNeedsLayout()
    }
}

// MARK: subTitle expand tapped delegate

extension MeetingRoomDetailTitleView: LKLabelDelegate {
    func tapShowMore(_ label: LKLabel) {
        subTitleLabel.numberOfLines = 0
        subTitleLabel.invalidateIntrinsicContentSize()
        subTitleLabel.setNeedsLayout()
    }
}

final class RoomStateView: UIView {
    private static var recWidth = 64
    var state: MeetingRoomStatus? {
        didSet {
            guard let state = state else { return }
            guard oldValue != state else { return }
            // change UI Stage
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let state = state else { return }
        let stateInfo = state.getStateInfo()
        stateLabel.text = stateInfo.stateText
        backLayer.colors = [stateInfo.colors.light.cgColor,
                            stateInfo.colors.light.cgColor,
                            stateInfo.colors.normal.cgColor,
                            stateInfo.colors.normal.cgColor]
        stateLabel.textColor = stateInfo.colors.dark
        buildingImage.image = stateInfo.image
    }

    private var backLayer = CAGradientLayer()
    private var stateLabel = UILabel()
    private var buildingImage = UIImageView()

    init() {
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: RoomStateView.recWidth, height: RoomStateView.recWidth)))
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backLayer.frame = CGRect(origin: .zero, size: bounds.size)
    }

    func setupSubviews() {
        backLayer.startPoint = CGPoint(x: 0.5, y: 0)
        backLayer.endPoint = CGPoint(x: 0.5, y: 1)
        backLayer.locations = [0, NSNumber(value: 11.0 / 16.0), NSNumber(value: 11.0 / 16.0), 1]
        backLayer.cornerRadius = CGFloat(RoomStateView.recWidth * 1 / 16)
        layer.addSublayer(backLayer)

        addSubview(buildingImage)
        buildingImage.snp.makeConstraints {
            $0.width.height.equalTo(RoomStateView.recWidth * 7 / 16)
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(8)
        }

        addSubview(stateLabel)
        // 设计认为目前只支持中英日三种语言，有需要（lable显示不全）可能会改图标
        let isEnglish = LanguageManager.currentLanguage == .en_US
        let fontSize: CGFloat = isEnglish ? 10 : 12
        stateLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        stateLabel.snp.makeConstraints {
            $0.centerX.bottom.equalToSuperview()
            $0.centerY.equalTo(RoomStateView.recWidth * 27 / 32)
        }
    }
}
