//
//  MeetingSelectorView.swift
//  Calendar
//
//  Created by tuwenbo on 2022/11/25.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignIcon

struct MeetingLinkCellData {
    var parsedLinkData: ParsedEventMeetingLink
    var onClick: ((_ parsedLinkData: ParsedEventMeetingLink) -> Void)?
    var onCopy: ((_ url: String) -> Void)?
}

final class MeetingSelectorView: UIView {

    private let cellIdentifier = "other_meeting_cell"
    private lazy var tableView = UITableView(frame: .zero, style: .plain)

    private lazy var meetingLinks = [MeetingLinkCellData]()

    init(meetingLinks: [MeetingLinkCellData]) {
        super.init(frame: .zero)
        self.meetingLinks = meetingLinks
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.register(MeetingItemCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
    }

    // 此方法用于提前计算 tableview 的高度，完全根据设计稿来，权宜之计. not elegant
    func estimateHeight() -> Int {
        var height = 0
        for meetingLink in meetingLinks {
            let linkWidth = meetingLink.parsedLinkData.vcLink.size(withAttributes: [.font: UIFont.ud.body2(.fixed)]).width
            // 72 是显示一行 link 时的长度， text 最多是两行，两行的话就要多加 20
            height += (72 + (linkWidth > 246 ? 20 : 0))
        }
        return max(height, 72)
    }
}

extension MeetingSelectorView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        meetingLinks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MeetingItemCell,
              let meetingLink = meetingLinks[safeIndex: indexPath.row] else {
            return UITableViewCell()
        }
        cell.backgroundColor = UIColor.ud.bgFloat
        cell.updateContent(itemData: meetingLink)
        cell.needSeparator = indexPath.item < (meetingLinks.count - 1)
        return cell
    }
}

extension MeetingSelectorView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let meetingLink = meetingLinks[indexPath.row]
        meetingLink.onClick?(meetingLink.parsedLinkData)
    }
}

private final class MeetingItemCell: UITableViewCell {

    private var itemData: MeetingLinkCellData?

    private lazy var iconView = UIImageView()

    private lazy var titleView: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.ud.body0(.fixed)
        label.numberOfLines = 1
        return label
    }()

    private lazy var linkView: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.ud.body2(.fixed)
        label.numberOfLines = 2
        return label
    }()

    private lazy var copyButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKeyNoLimitSize(.copyOutlined).scaleInfoSize().renderColor(with: .n3).withRenderingMode(.alwaysOriginal), for: .normal)
        button.increaseClickableArea(top: -16, left: -16, bottom: -16, right: -16)
        button.addTarget(self, action: #selector(didCopyButtonClick), for: .touchUpInside)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private lazy var separatorLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        return line
    }()

    var needSeparator = true {
        didSet {
            separatorLine.isHidden = !needSeparator
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupContentView()
    }

    private func setupContentView() {
        contentView.addSubview(iconView)
        contentView.addSubview(stackView)
        contentView.addSubview(copyButton)
        contentView.addSubview(separatorLine)

        stackView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(60)
            make.right.equalToSuperview().inset(52)
            make.height.greaterThanOrEqualTo(46)
            make.top.bottom.equalToSuperview().inset(13)
        }

        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.height.width.equalTo(32)
            make.centerY.equalToSuperview()
        }

        copyButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.height.width.equalTo(24)
            make.centerY.equalToSuperview()
        }

        separatorLine.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(60)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        stackView.distribution = .equalSpacing
        stackView.spacing = 4

        stackView.addArrangedSubview(titleView)
        stackView.addArrangedSubview(linkView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateContent(itemData: MeetingLinkCellData) {
        self.itemData = itemData
        iconView.image = getIcon(vcType: itemData.parsedLinkData.vcType)
        titleView.text = getTitle(vcType: itemData.parsedLinkData.vcType)
        linkView.text = itemData.parsedLinkData.vcLink
    }

    @objc
    private func didCopyButtonClick() {
        if let item = itemData {
            item.onCopy?(item.parsedLinkData.vcLink)
        }
    }

    private func getIcon(vcType: Rust.ParsedMeetingLinkVCType) -> UIImage {
        switch vcType {
        case .google:
            return UDIcon.getIconByKeyNoLimitSize(.calendarGoogleMeetingColorful)
        case .zoom:
            return UDIcon.getIconByKeyNoLimitSize(.zoomColorful)
        case .teams:
            return UDIcon.getIconByKeyNoLimitSize(.calendarTeamsColorful)
        case .webex:
            return UDIcon.getIconByKeyNoLimitSize(.calendarWebexColorful)
        case .bluejeans:
            return UDIcon.getIconByKeyNoLimitSize(.calendarBluejeansColorful)
        case .tencent:
            return UDIcon.getIconByKeyNoLimitSize(.calendarTecentMeetingColorful)
        @unknown default:
            return UDIcon.getIconByKeyNoLimitSize(.larkLogoColorful)
        }
    }

    private func getTitle(vcType: Rust.ParsedMeetingLinkVCType) -> String {
        switch vcType {
        case .google:
            return BundleI18n.Calendar.Calendar_Join_GoogleMeetClick
        case .zoom:
            return BundleI18n.Calendar.Calendar_Join_ZoomClick
        case .teams:
            return BundleI18n.Calendar.Calendar_Join_TeamsClick
        case .webex:
            return BundleI18n.Calendar.Calendar_Join_WebexClick
        case .bluejeans:
            return BundleI18n.Calendar.Calendar_Join_BlueJeansClick
        case .tencent:
            return BundleI18n.Calendar.Calendar_Join_VooVClick
        @unknown default:
            return BundleI18n.Calendar.Calendar_Join_BrandMeetClick()
        }
    }
}
