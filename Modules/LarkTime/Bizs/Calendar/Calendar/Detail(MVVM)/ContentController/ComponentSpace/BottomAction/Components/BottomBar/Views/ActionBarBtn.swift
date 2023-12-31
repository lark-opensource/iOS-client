//
//  ActionBarBtn.swift
//  Calendar
//
//  Created by Hongbin Liang on 11/15/22.
//

import UIKit
import Foundation
import LarkInteraction
import UniverseDesignIcon

fileprivate let iconSize = CGSize(width: 16, height: 16)

final class ActionBarBtn: UIView {

    private let container = UIStackView()

    private let statusIcon: UIImageView = {
        let icon = UIImageView()
        icon.snp.makeConstraints { $0.size.equalTo(iconSize) }
        return icon
    }()

    private(set) lazy var title: UILabel = {
        let label = UILabel()
        label.font = .ud.body0(.fixed)
        label.textColor = .ud.textTitle
        return label
    }()

    private(set) lazy var folderIcon: UIImageView = {
        let folder = UIImageView()
        folder.image = UDIcon.getIconByKey(.downBoldOutlined, size: CGSize(width: 12, height: 12)).renderColor(with: .n2)
        return folder
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(container)
        container.spacing = 4.0
        container.alignment = .center
        container.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateWith(type: CalendarEventAttendee.Status, withFolder: Bool = false, withBorder: Bool = false) {
        switch type {
        case .accept:
            statusIcon.image = UDIcon.getIconByKey(.yesFilled, size: iconSize).ud.withTintColor(.ud.colorfulGreen)
            title.text = I18n.Calendar_Detail_Accept
        case .decline:
            statusIcon.image = UDIcon.getIconByKey(.noFilled, size: iconSize).ud.withTintColor(.ud.colorfulRed)
            title.text = I18n.Calendar_Detail_Refuse
        case .tentative:
            statusIcon.image = UDIcon.getIconByKey(.maybeFilled, size: iconSize).renderColor(with: .n3)
            title.text = I18n.Calendar_Detail_Maybe
        case .needsAction:
            title.text = I18n.Calendar_Detail_RSVPGoing
            container.addArrangedSubview(title)
            return
        @unknown default:
            assertionFailure()
            return
        }

        container.addArrangedSubview(statusIcon)
        container.addArrangedSubview(title)
        if withFolder {
            container.addArrangedSubview(folderIcon)
        }

        if withBorder {
            layer.borderWidth = 1
            layer.cornerRadius = 6
            layer.ud.setBorderColor(.ud.lineDividerDefault)
        }
    }
}

class BoundedActionBarBtn: UIButton {
    func setupButton(with type: CalendarEventAttendee.Status) {
        layer.borderWidth = 1
        layer.cornerRadius = 6
        layer.ud.setBorderColor(.ud.lineBorderComponent)

        let titleStr: String
        let icon: UIImage
        switch type {
        case .accept:
            icon = UDIcon.getIconByKey(.yesOutlined, size: iconSize).ud.withTintColor(.ud.functionSuccessContentDefault)
            titleStr = I18n.Calendar_Detail_Accept
        case .decline:
            icon = UDIcon.getIconByKey(.noOutlined, size: iconSize).ud.withTintColor(.ud.functionDangerContentDefault)
            titleStr = I18n.Calendar_Detail_Refuse
        case .tentative:
            icon = UDIcon.getIconByKey(.maybeOutlined, size: iconSize).renderColor(with: .n3)
            titleStr = I18n.Calendar_Detail_Maybe
        @unknown default:
            return
            assertionFailure("wrong button type param")
        }
        setTitle(titleStr, for: .normal)
        setTitleColor(.ud.textTitle, for: .normal)
        setImage(icon, for: .normal)

        imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        contentEdgeInsets = UIEdgeInsets(top: 7, left: 16, bottom: 7, right: 16)

        titleLabel?.font = UIFont.ud.body0(.fixed)
        titleLabel?.adjustsFontSizeToFitWidth = true
        if #available(iOS 13.4, *) {
            lkPointerStyle = PointerStyle(
                effect: .lift,
                shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                    guard let width = interaction.view?.bounds.width,
                          let height = interaction.view?.bounds.height else {
                        return (.zero, 0)
                    }
                    return (CGSize(width: width, height: height), 8)
                }))
        }
    }
}
