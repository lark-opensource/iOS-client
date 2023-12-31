//
//  SubscribeMeetingRoomCell.swift
//  Calendar
//
//  Created by zhuheng on 2021/2/16.
//

import UIKit
import UniverseDesignIcon
import Foundation
import SnapKit
protocol SubscribeMeetingRoomCellDataType {
    var name: String { get }
    // 需要审批（审批类会议室）
    var needsApproval: Bool { get }
    var capacityDesc: String { get }
    var location: String { get }
    var state: SubscribeStatus { get }
    var pathName: String { get }
}

// 会议室查询界面使用二级样式 （默认）
// 会议室搜索界面使用一级样式  (setFirstLevelStyle)
final class SubscribeMeetingRoomCell: UITableViewCell, ViewDataConvertible {
    var viewData: SubscribeMeetingRoomCellDataType? {
        didSet {
            let (meetingRoomIcon, capacityIcon): (UIImage, UIImage)
            meetingRoomIcon = UDIcon.getIconByKeyNoLimitSize(.roomOutlined).renderColor(with: .n3)

            iconView.image = meetingRoomIcon.withRenderingMode(.alwaysOriginal)
            infoView.titleLabel.text = viewData?.name
            infoView.approveTag.isHidden = !(viewData?.needsApproval ?? false)
            infoView.capacityLabel.text = viewData?.capacityDesc
            infoView.updateEquipment(text: viewData?.location)
            infoView.updatePathName(text: viewData?.pathName)

            subscribeButton.setSubStatus(viewData?.state ?? .noSubscribe)
        }
    }

    private var iconView = UIImageView()
    private let subscribeButton = SubscribeButton()
    private let containerView = UIView()
    private let infoView = MeetingRoomHomeTableViewCell.InfoView()

    var onTapped: (() -> Void)?
    var subscribeButtonTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(contentOnClick))
        containerView.addGestureRecognizer(tapGesture)

        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(48)
            $0.right.top.bottom.equalToSuperview()
        }
        containerView.addBottomSepratorLine()

        let infoContainerView = UIView()
        containerView.addSubview(infoContainerView)
        containerView.addSubview(subscribeButton)

        infoContainerView.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview()
            $0.right.equalTo(subscribeButton.snp.left).offset(-16)
        }

        subscribeButton.addTarget(self, action: #selector(subButtonOnClick), for: .touchUpInside)
        subscribeButton.increaseClickableArea(top: -15,
                                        left: 0,
                                        bottom: -15,
                                        right: 0)
        subscribeButton.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-15)
            $0.height.equalTo(28)
            $0.centerY.equalToSuperview()
        }

        infoContainerView.addSubview(iconView)
        infoContainerView.addSubview(infoView)

        infoView.titleLabel.font = UIFont.systemFont(ofSize: 16)
        infoView.titleLabel.textColor = UIColor.ud.textTitle

        infoView.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(14)
            make.top.bottom.equalToSuperview().inset(12)
            make.trailing.lessThanOrEqualToSuperview()
        }

        iconView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 16, height: 16))
            $0.left.equalToSuperview()
            $0.centerY.equalTo(infoView.titleLabel)
        }
    }

    @objc
    private func contentOnClick() {
        onTapped?()
    }

    func setFirstLevelStyle() {
        containerView.snp.updateConstraints {
            $0.left.equalToSuperview().offset(16)
        }
    }

    @objc
    func subButtonOnClick() {
        subscribeButtonTapped?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = size
        size.height = 68
        return size
    }

}
