//
//  EventEditVideoMeetingView.swift
//  Calendar
//
//  Created by zhuheng on 2021/4/7.
//

import UIKit
import SnapKit
import CalendarRichTextEditor
import UniverseDesignIcon

protocol EventEditVideoMeetingViewDataType {
    var title: String { get }
    var isOpen: Bool { get }
    var editable: Bool { get }
    var isVisible: Bool { get }
    var isShowSetting: Bool { get }
    var videoIcon: UIImage { get }
    var zoomConfig: Rust.ZoomVideoMeetingConfigs? { get }
    var videoType: VideoItemType { get }
}

final class EventEditVideoMeetingView: UIView, ViewDataConvertible {
    var videoMeetingClickHandler: ((Bool) -> Void)? {
        didSet {
            videoMeetingItem.onClick = { [weak self] in
                self?.videoMeetingClickHandler?(self?.viewData?.editable ?? false)
            }
        }
    }

    var settingClickHandler: ((Bool) -> Void)? {
        didSet {
            settingItem.onItemSelected = { [weak self] in
                self?.settingClickHandler?(self?.viewData?.editable ?? false)
            }
        }
    }

    var viewData: EventEditVideoMeetingViewDataType? {
        didSet {
            videoMeetingItem.isHidden = !(viewData?.isVisible ?? false)
            guard let viewData = viewData else {
                return
            }
            videoMeetingItem.titleLabel.text = viewData.title
            videoMeetingItem.titleLabel.textColor = viewData.editable ? UIColor.ud.textTitle : UIColor.ud.textDisabled
            videoMeetingItem.tailLabel.isHidden = viewData.isOpen == false
            videoMeetingItem.tailLabel.textColor = viewData.editable ? EventEditUIStyle.Color.dynamicGrayText : UIColor.ud.textDisabled
            videoMeetingItem.icon = viewData.editable ? .customImage(viewData.videoIcon) : .customImageWithoutN3(viewData.videoIcon)
            videoMeetingItem.iconSize = EventEditUIStyle.Layout.cellLeftIconSize
            videoMeetingItem.accessory = .type(.next(viewData.editable ? .n3 : .n4))

            zoomAccountItem.isHidden = !(viewData.videoType == .zoom)
            zoomAccountItem.configAccountInfo(info: viewData.zoomConfig)

            settingItem.isHidden = !viewData.isShowSetting
            settingItem.titleLable.textColor = viewData.editable ? UIColor.ud.textTitle : UIColor.ud.textDisabled
            settingItem.iconView.isHidden = !viewData.editable
            isHidden = videoMeetingItem.isHidden && zoomAccountItem.isHidden && settingItem.isHidden
        }
    }

    private lazy var zoomAccountItem: ZoomAccountItem = {
        let view = ZoomAccountItem()
        view.isHidden = true
        return view
    }()

    let videoMeetingItem = EventEditVideoMeetingItem()
    private let settingItem = VideoSettingItem(title: I18n.Calendar_Edit_JoinSettings)

    var forGuideFrame: CGRect?
    override init(frame: CGRect) {
        super.init(frame: frame)

        let stackView = UIStackView()
        stackView.axis = .vertical
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(videoMeetingItem)
        stackView.addArrangedSubview(zoomAccountItem)
        stackView.addArrangedSubview(settingItem)

        forGuideFrame = videoMeetingItem.tailLabel.frame
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class EventEditVideoMeetingItem: EventEditCellLikeView {
    let titleLabel = UILabel()
    let tailLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessory = .type(.next())
        backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        content = .customView(titleContentView())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: EventEditUIStyle.Layout.singleLineCellHeight)
    }

    private func titleContentView() -> UIView {
        let titleContentView = UIView()
        titleLabel.text = BundleI18n.Calendar.Calendar_Edit_FeishuVC()
        titleLabel.font = UIFont.cd.regularFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle

        tailLabel.text = BundleI18n.Calendar.Calendar_Common_Enabled
        tailLabel.font = UIFont.ud.body2
        tailLabel.textColor = EventEditUIStyle.Color.dynamicGrayText
        tailLabel.textAlignment = .right

        titleContentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerY.left.equalToSuperview()
        }

        let tailWidth = BundleI18n.Calendar.Calendar_Common_Enabled.width(with: tailLabel.font)
        titleContentView.addSubview(tailLabel)
        tailLabel.snp.makeConstraints {
            $0.centerY.right.equalToSuperview()
            $0.left.equalTo(titleLabel.snp.right)
            $0.width.equalTo(tailWidth + 20)
        }

        titleContentView.isUserInteractionEnabled = false
        return titleContentView
    }
}

final class VideoSettingItem: UIView {
    var onItemSelected: (() -> Void)?
    let titleLable: UILabel = UILabel()

    let iconView: UIImageView = {
        let iconView: UIImageView = UIImageView()
        iconView.contentMode = .scaleToFill
        iconView.isUserInteractionEnabled = false
        iconView.image = UDIcon.getIconByKey(.rightBoldOutlined, size: EventBasicCellLikeView.Style.iconSize).renderColor(with: .n3)
        return iconView
    }()
    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgFloat
        addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.size.equalTo(12)
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().inset(16)
        }

        titleLable.font = UIFont.cd.regularFont(ofSize: 16)
        titleLable.textColor = UIColor.ud.textTitle
        titleLable.text = title
        titleLable.textAlignment = .left

        addSubview(titleLable)
        titleLable.snp.makeConstraints {
            $0.left.equalToSuperview().inset(EventEditUIStyle.Layout.eventEditContentLeftMargin)
            $0.right.equalTo(iconView.snp.left).offset(-16)
            $0.right.equalToSuperview().inset(EventBasicCellLikeView.Style.rightInset)
            $0.centerY.equalToSuperview()
        }

        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(contentTapped))
        addGestureRecognizer(tapGesture)

        snp.makeConstraints { $0.height.equalTo(48) }
    }

    @objc func contentTapped() {
        onItemSelected?()
    }

    required init?(coder: NSCoder) {
        fatalError(" init(coder:) has not been implemented")
    }

}

final class ZoomAccountItem: UIView {
    private lazy var zoomAccountInfoView: ZoomAccountInfoView = {
        let view = ZoomAccountInfoView()
        return view
    }()

    var status: ZoomAccountStatus = .inital {
        didSet {
            zoomAccountInfoView.status = status
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgFloat
        layoutZoomAccoutInfo()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutZoomAccoutInfo() {
        addSubview(zoomAccountInfoView)
        zoomAccountInfoView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: EventEditUIStyle.Layout.eventEditContentLeftMargin, bottom: 8, right: 16))
        }
    }

    func configAccountInfo(info: Rust.ZoomVideoMeetingConfigs?) {
        if let info = info {
            zoomAccountInfoView.configMeetingDescInfo(meetingNo: info.meetingNo, password: info.password, fontSize: 16)
            if info.password.isEmpty {
                self.status = .normalOneLine
                return
            }
        }
        self.status = .normal
    }
}
