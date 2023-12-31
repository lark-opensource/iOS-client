//
//  EventEditWebinarAttendeeView.swift
//  Calendar
//
//  Created by tuwenbo on 2023/1/28.
//

import UniverseDesignIcon
import UIKit
import SnapKit
import CalendarFoundation
import RxSwift
import RxCocoa
import LarkBizAvatar

protocol EventEditWebinarAttendeeViewDataType {
    var avatars: [Avatar] { get }
    var countStr: String { get }
    var isVisible: Bool { get }
    var enableAdd: Bool { get }
    var isLoading: Bool { get }
    var attendeeType: WebinarAttendeeType { get }
}

final class EventEditWebinarAttendeeView: UIView, ViewDataConvertible {
    struct Config {
        static let contentLeftMargin: CGFloat = EventEditUIStyle.Layout.contentLeftMargin
        static let contentRightMargin: CGFloat = 16
    }
    var viewData: EventEditWebinarAttendeeViewDataType? {
        didSet {
            let avatars = viewData?.avatars ?? []
            let enableAdd = viewData?.enableAdd ?? false
            let isLoading = viewData?.isLoading ?? false
            let attendeeType: WebinarAttendeeType? = viewData?.attendeeType

            var contentView: UIView? = nil

            if avatars.isEmpty {
                switch attendeeType {
                case .speaker:
                    emptyAttendeeContentView.icon = UDIcon.getIconByKey(.webinarOutlined, size: EventEditUIStyle.Layout.cellLeftIconSize)
                    emptyAttendeeContentView.title = BundleI18n.Calendar.Calendar_Edit_AddPanelists
                case .audience:
                    emptyAttendeeContentView.icon = UDIcon.getIconByKey(.communityTabOutlined, size: EventEditUIStyle.Layout.cellLeftIconSize)
                    emptyAttendeeContentView.title = BundleI18n.Calendar.Calendar_Edit_AddAttendees
                @unknown default:
                    print()
                }
                contentView = emptyAttendeeContentView
            } else {
                attendeesContentView.countStr = viewData?.countStr ?? ""
                switch attendeeType {
                case .speaker:
                    attendeesContentView.iconImage = UDIcon.getIconByKey(.webinarOutlined, size: EventEditUIStyle.Layout.cellLeftIconSize)
                    attendeesContentView.title = BundleI18n.Calendar.Calendar_Edit_PanelistsTag
                case .audience:
                    attendeesContentView.iconImage = UDIcon.getIconByKey(.communityTabOutlined, size: EventEditUIStyle.Layout.cellLeftIconSize)
                    attendeesContentView.title = BundleI18n.Calendar.Calendar_Edit_AttendeesTag
                @unknown default:
                    print()
                }

                // 获取当前能显示人的最大宽度
                let maxAttendeesWidth = self.bounds.size.width - Self.Config.contentLeftMargin - Self.Config.contentRightMargin - EventEditUIStyle.Layout.avatarSize.width
                // 计算出最大显示的人数
                let maxAvatarCount = Int(maxAttendeesWidth / (EventEditUIStyle.Layout.avatarSize.width + WebinarAttendeeContentView.itemSpacing))
                attendeesContentView.removeAvatarViews()
                viewData?.avatars.prefix(maxAvatarCount).forEach { avatar in
                    let avatarView = AvatarView()
                    attendeesContentView.addAvatarView(avatarView)
                    avatarView.setAvatar(avatar, with: EventEditUIStyle.Layout.avatarSize.width)  // 32*32
                    avatarView.snp.makeConstraints {
                        $0.size.equalTo(EventEditUIStyle.Layout.avatarSize.width)
                    }
                }

                attendeesContentView.addAvatarView(addAttendeeButton)
                addAttendeeButton.snp.makeConstraints {
                    $0.size.equalTo(EventEditUIStyle.Layout.avatarSize.width)
                }

                contentView = attendeesContentView
            }

            addContent(contentView: contentView)
            isHidden = !(viewData?.isVisible ?? false)
        }
    }

    private lazy var addAttendeeButton: UIButton = {
        let button = UIButton()
        let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.addOutlined).renderColor(with: .n2))
        button.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(16)
        }
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.ud.iconN2.cgColor
        button.addTarget(self, action: #selector(handleAddAttendee), for: .touchUpInside)
        return button
    }()

    private lazy var emptyAttendeeContentView: EmptyWebinarAttendeeContentView = {
        let emptyView = EmptyWebinarAttendeeContentView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleAddAttendee))
        emptyView.addGestureRecognizer(tap)
        return emptyView
    }()

    private lazy var attendeesContentView: WebinarAttendeeContentView = {
        let attendeeContentView = WebinarAttendeeContentView()
        attendeeContentView.onClick = tapAddendeesView
        return attendeeContentView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgFloat
    }

    fileprivate func addContent(contentView: UIView?) {
        guard let contentView = contentView else { return }
        subviews.forEach { $0.removeFromSuperview() }
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    var addHandler: (() -> Void)?
    var clickHandler: (() -> Void)?

    @objc
    private func handleAddAttendee() {
        addHandler?()
    }

    @objc
    private func tapAddendeesView() {
        clickHandler?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


fileprivate final class EmptyWebinarAttendeeContentView: UIView {

    fileprivate var icon: UIImage = UDIcon.getIconByKey(.webinarOutlined, size: CGSize(width: 16, height: 16)) {
        didSet {
            iconView.image = icon.renderColor(with: .n3)
        }
    }

    fileprivate var title: String = BundleI18n.Calendar.Calendar_Edit_AddGuest {
        didSet {
            titleLabel.text = title
        }
    }

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView(image: icon)
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = title
        label.textColor = EventEditUIStyle.Color.dynamicGrayText
        label.font = UIFont.ud.body0(.fixed)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgFloat

        layoutUI()
    }

    private func layoutUI() {
        self.snp.makeConstraints { make in
            make.height.equalTo(EventEditUIStyle.Layout.singleLineCellHeight)
        }

        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.size.equalTo(EventEditUIStyle.Layout.cellLeftIconSize)
            make.top.equalToSuperview().inset(15)
            make.left.equalToSuperview().inset(16)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 15, left: 46, bottom: 15, right: 16))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate final class WebinarAttendeeContentView: EventEditCellLikeView {
    static let itemSpacing: CGFloat = 8

    fileprivate var iconImage: UIImage = UDIcon.getIconByKey(.webinarOutlined, size: CGSize(width: 16, height: 16)) {
        didSet {
            icon = .customImage(iconImage.renderColor(with: .n3))
        }
    }

    fileprivate var title: String = BundleI18n.Calendar.Calendar_Edit_AttendeesTag {
        didSet {
            titleLabel.text = title
        }
    }

    fileprivate var countStr: String = "" {
        didSet {
            countLabel.text = countStr
        }
    }

    // 显示嘉宾/观众及对应人数
    private lazy var titleContainer = UIView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = title
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.ud.body0(.fixed)
        return label
    }()

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.text = countStr
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.ud.body2(.fixed)
        return label
    }()

    private lazy var avatarContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = Self.itemSpacing
        return stackView
    }()

    fileprivate func removeAvatarViews() {
        avatarContainer.subviews.forEach { $0.removeFromSuperview() }
    }

    fileprivate func addAvatarView(_ avatarView: UIView) {
        avatarContainer.addArrangedSubview(avatarView)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgFloat
        backgroundColors = EventEditUIStyle.Color.cellBackgrounds

        translatesAutoresizingMaskIntoConstraints = false
        let contentView = setupContentView()
        content = .customView(contentView)
        icon = .customImage(iconImage.renderColor(with: .n3))
        iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        iconAlignment = .topByOffset(15)

        accessory = .type(.next())
        accessoryAlignment = .centerYEqualTo(refView: titleContainer)
    }

    private func setupContentView() -> UIView {
        let contentView = UIView()

        titleContainer.addSubview(titleLabel)
        titleContainer.addSubview(countLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview()
        }
        countLabel.snp.makeConstraints { make in
            make.top.right.bottom.equalToSuperview()
        }

        contentView.addSubview(titleContainer)
        titleContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.height.equalTo(24)
            make.left.right.equalToSuperview()
        }

        contentView.addSubview(avatarContainer)
        avatarContainer.snp.makeConstraints { make in
            make.height.equalTo(32)
            make.top.equalTo(titleContainer.snp.bottom).offset(12)
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(28)
            make.bottom.equalToSuperview().inset(20)
        }

        return contentView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
