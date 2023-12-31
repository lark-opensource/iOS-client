//
//  MeetingNotesCreateView.swift
//  Calendar
//
//  Created by huoyunjie on 2023/8/9.
//

import Foundation
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont

protocol MeetingNotesCreateViewDelegate: AnyObject {
    /// 创建AI文档
    func clickAICreateView()
    /// 关联文档
    func clickAssociateDocView()
    /// 创建空白文档
    func clickFakeListItemView()
}

class MeetingNotesCreateView: UIView {

    private(set) lazy var aiCreateView: UIView = {
        makeAICreateView()
    }()

    private(set) lazy var fakeListItemView: UIView = {
        makeFakeListItemView()
    }()

    private(set) lazy var labelCreateView: UIView = {
        makeLabelCreateView()
    }()

    private(set) lazy var createView: UIView = {
        switch self.createViewType {
        case .ai: return aiCreateView
        case .label: return labelCreateView
        case .list: return fakeListItemView
        }
    }()

    private lazy var associateDocView: UIView = {
        makeAssociateDocView()
    }()

    private var aiLabel: UILabel?

    private var moreLabel: UILabel?

    weak var delegate: MeetingNotesCreateViewDelegate?

    let createViewType: CreateViewType

    enum CreateViewType {
        /// 编辑页fakeList样式
        case list
        /// 详情页label样式
        case label
        /// 编辑页面 AI样式
        case ai

        var bottomOffset: Int {
            switch self {
            case .list, .label: return 10
            case .ai: return 15
            default: return 15
            }
        }
    }

    init(createViewType: CreateViewType) {
        self.createViewType = createViewType
        super.init(frame: .zero)
        self.setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let topView = createView
        let offset = createViewType.bottomOffset

        addSubview(topView)
        addSubview(associateDocView)

        topView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        associateDocView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.top.equalTo(topView.snp.bottom).offset(offset)
        }
    }

    private func makeLabelCreateView() -> UIView {
        let label = getLabel(text: I18n.Calendar_G_CreateMeetingNotes_Click,
                             font: UDFont.body0,
                             lineHeight: 22)
        label.textColor = UDColor.primaryContentDefault

        let tap = UITapGestureRecognizer(target: self, action: #selector(clickFakeListItemView))
        label.addGestureRecognizer(tap)

        label.isUserInteractionEnabled = true

        return label
    }

    private func makeAICreateView() -> UIView {
        let iconImage = UIImageView(image: UDIcon.myaiColorful)
        let label = getLabel(text: I18n.Calendar_G_CreateMeetingNotes_Click,
                             font: UDFont.body0,
                             lineHeight: 22)
        label.numberOfLines = 0
        aiLabel = label

        let container = UIView()
        container.addSubview(iconImage)
        container.addSubview(label)

        iconImage.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(3)
            make.size.equalTo(16)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(iconImage.snp.trailing).offset(4)
            make.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(clickAICreateView))
        container.addGestureRecognizer(tap)

        return container
    }

    @objc
    private func clickAICreateView() {
        delegate?.clickAICreateView()
    }

    private func makeAssociateDocView() -> UIView {
        let label = getLabel(text: I18n.Calendar_G_CanAlsoLinkDocs_Desc, font: UDFont.body0, lineHeight: 22)
        label.textColor = UDColor.textTitle
        label.numberOfLines = 0

        let rightIconView = UIImageView(image: UDIcon.rightBoldOutlined.renderColor(with: .n3))

        let containerView = UIView()
        containerView.addSubview(label)
        containerView.addSubview(rightIconView)

        label.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.equalTo(rightIconView.snp.leading).offset(-4)
        }

        rightIconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
            make.trailing.lessThanOrEqualToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(clickAssociateDocView))
        containerView.addGestureRecognizer(tap)

        moreLabel = label
        return containerView
    }

    @objc
    private func clickAssociateDocView() {
        delegate?.clickAssociateDocView()
    }

    private func makeFakeListItemView() -> UIView {
        let containerView = UIView()
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UDColor.lineDividerDefault.cgColor

        let firstListItem = makeListItem(text: I18n.Calendar_G_AddAgendaKnowWhattoDiscuss_Placeholder)

        let listItemStackView = UIStackView(arrangedSubviews: [firstListItem])
        listItemStackView.axis = .vertical
        listItemStackView.spacing = 2

        containerView.addSubview(listItemStackView)

        listItemStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(clickFakeListItemView))
        containerView.addGestureRecognizer(tap)

        containerView.snp.makeConstraints { make in
            make.height.equalTo(70)
        }

        return containerView
    }

    @objc
    private func clickFakeListItemView() {
        delegate?.clickFakeListItemView()
    }

    private func makeListItem(text: String, hiddenEllipse: Bool = true) -> UIView {
        let view = UIView()

        let ellipse = UIView()
        ellipse.backgroundColor = UDColor.iconN3
        ellipse.layer.cornerRadius = 2
        ellipse.clipsToBounds = true
        ellipse.isHidden = hiddenEllipse

        let label = getLabel(text: text, font: UDFont.body2, lineHeight: 22)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textColor = EventEditUIStyle.Color.dynamicGrayText

        view.addSubview(ellipse)
        view.addSubview(label)

        ellipse.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(4)
        }
        label.snp.makeConstraints { make in
            if hiddenEllipse {
                make.leading.equalToSuperview()
            } else {
                make.leading.equalTo(ellipse.snp.trailing).offset(8)
            }
            make.top.bottom.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        return view
    }

    private func getLabel(text: String, font: UIFont, lineHeight: CGFloat) -> UILabel {
        let label = UILabel()
        label.setText(text: text, font: font, lineHeight: lineHeight)
        return label
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setAILabelColor()
        fixLabelView()
    }

    private func setAILabelColor() {
        if let label = aiLabel {
            label.setNeedsLayout()
            label.layoutIfNeeded()
            label.textColor = UDColor.AIPrimaryContentDefault(ofSize: label.bounds.size)
        }
    }

    private func fixLabelView() {
        /// https://meego.feishu.cn/larksuite/issue/detail/14786418
        moreLabel?.preferredMaxLayoutWidth = associateDocView.bounds.width - 5 - 12 - 4
    }
}
