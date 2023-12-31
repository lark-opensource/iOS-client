//
//  EventDetailTableWebinarView.swift
//  Calendar
//
//  Created by tuwenbo on 2022/11/1.
//

import UIKit
import CalendarFoundation
import UniverseDesignIcon

protocol EventDetailTableWebinarViewDataType {
    var countText: String? { get }
    var statusText: String? { get }
    var avatars: [(avatar: Avatar, statusImage: UIImage?)] { get }
    var withEllipsisIcon: Bool { get }
}

class EventDetailTableWebinarView: EventBasicCellLikeView, ViewDataConvertible {

    var viewData: EventDetailTableWebinarViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            updateView(with: viewData)
        }
    }

    lazy var countLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.ud.body0(.fixed)
        return label
    }()

    lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 0
        label.font = UIFont.ud.body2(.fixed)
        return label
    }()

    lazy var avatarContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()
    private let image = UDIcon.getIconByKey(.rightOutlined, size: EventBasicCellLikeView.Style.rightIconSize).renderColor(with: .n2)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColors = (UIColor.clear, UIColor.ud.fillHover)
        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initView() {
        assert(false, "initView() has not been implemented")
    }

    func setupContentView() -> UIView {
        let content = UIView()

        content.addSubview(countLabel)
          countLabel.snp.makeConstraints {
              $0.left.right.equalToSuperview()
              $0.height.equalTo(22)
              $0.top.equalToSuperview().offset(10)
          }

          content.addSubview(statusLabel)
          statusLabel.snp.makeConstraints {
              $0.left.right.equalToSuperview()
              $0.height.greaterThanOrEqualTo(20)
              $0.top.equalTo(countLabel.snp.bottom).offset(2)
          }

          content.addSubview(avatarContainer)
          avatarContainer.snp.makeConstraints {
              $0.left.equalToSuperview()
              $0.right.lessThanOrEqualToSuperview()
              $0.height.equalTo(32)
              $0.top.equalTo(statusLabel.snp.bottom).offset(14)
              $0.bottom.equalToSuperview().offset(-10)
          }

        return content
    }

    func updateView(with viewData: EventDetailTableWebinarViewDataType) {
        countLabel.text = viewData.countText
        statusLabel.text = viewData.statusText
        avatarContainer.subviews.forEach { $0.removeFromSuperview() }
        avatarContainer.isHidden = viewData.avatars.isEmpty
        if viewData.avatars.isEmpty { accessory = .none } else { accessory = .customImage(image) }
        if avatarContainer.isHidden {
            statusLabel.snp.remakeConstraints {
                $0.left.right.equalToSuperview()
                $0.height.greaterThanOrEqualTo(20)
                $0.top.equalTo(countLabel.snp.bottom).offset(2)
                $0.bottom.equalToSuperview().offset(-10)
            }
        } else {
            statusLabel.snp.remakeConstraints {
                $0.left.right.equalToSuperview()
                $0.height.greaterThanOrEqualTo(20)
                $0.top.equalTo(countLabel.snp.bottom).offset(2)
            }
        }
        guard viewData.avatars.count <= 6 else {
            EventDetail.logInfo("attendee count: \(viewData.avatars.count)")
            return
        }
        viewData.avatars.forEach { (avatar, statusImage) in
            let avatarView = EventDetailAvatarView()
            avatarView.setStatusImage(statusImage)
            avatarContainer.addArrangedSubview(avatarView)
            avatarView.snp.makeConstraints {
                $0.size.equalTo(CGSize(width: 32, height: 32))
            }
            avatarView.setAvatar(avatar, with: 32)
        }
        if viewData.withEllipsisIcon {
            let iconImage = UDIcon.getIconByKey(.moreBoldOutlined).renderColor(with: .n3)
            let ellipsisIcon = UIImageView(image: iconImage)
            let iconWrapper = UIView()
            iconWrapper.layer.cornerRadius = 16
            iconWrapper.addSubview(ellipsisIcon)
            iconWrapper.backgroundColor = UIColor.ud.bgBodyOverlay
            ellipsisIcon.snp.makeConstraints {
                $0.size.equalTo(CGSize(width: 16, height: 16))
                $0.centerX.centerY.equalToSuperview()
            }
            avatarContainer.addArrangedSubview(iconWrapper)
            iconWrapper.snp.makeConstraints {
                $0.size.equalTo(CGSize(width: 32, height: 32))
            }
        }

        // dirty 不展示人数相关内容
        guard let countLabelText = countLabel.text, let statusLabelText = statusLabel.text,
              !countLabelText.isEmpty, !statusLabelText.isEmpty else {
            countLabel.isHidden = true
            statusLabel.isHidden = true
            iconAlignment = .topByOffset(18)
            avatarContainer.snp.remakeConstraints {
                $0.left.equalToSuperview()
                $0.right.lessThanOrEqualToSuperview()
                $0.height.equalTo(32)
                $0.top.equalToSuperview().offset(10)
                $0.bottom.equalToSuperview().offset(-10)
            }
            return
        }
    }
}
