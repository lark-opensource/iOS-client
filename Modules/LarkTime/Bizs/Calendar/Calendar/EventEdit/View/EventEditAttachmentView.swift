//
//  EventEditAttachmentView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/18.
//
import UniverseDesignIcon
import UniverseDesignTag
import UniverseDesignProgressView
import UniverseDesignLoading
import RxRelay
import UIKit

protocol EventEditAttachmentItemViewDataType {
    var icon: UIImage { get }
    var name: String { get }
    var type: CalendarEventAttachment.TypeEnum { get }
    var sizeString: String { get }
    var token: String { get }
    var isLargeAttachments: Bool { get }
    var tipInfo: (String?, UIColor) { get }
    var hasBeenDeleted: Bool { get }
    var isFileRisk: Bool { get }
    var canDelete: Bool { get }
    var status: UploadStatus { get }
    var googleDriveLink: String { get }
    var urlLink: String { get }
}

protocol EventEditAttachmentViewDataType {
    var title: String { get }
    var items: [EventEditAttachmentItemViewDataType] { get }
    var isVisible: Bool { get }
    var isEditable: Bool { get }
    var needResetAllItems: Bool { get }
    var source: Rust.CalendarEventSource { get }
}

final class EventEditAttachmentView: UIView, ViewDataConvertible {

    var viewData: EventEditAttachmentViewDataType? {
        didSet {
            let shouldHidden = !(viewData?.isVisible ?? false)
            let shouldHideAdd = !(viewData?.isEditable ?? false)
            let isItemsEmpty = viewData?.items.filter { !$0.hasBeenDeleted }.isEmpty ?? true
            // 所有内容是否为空
            let contentIsHidden = isItemsEmpty && shouldHideAdd
            // 没有查看权限隐藏；有查看权限且所有内容为空隐藏
            let newIsHidden = shouldHidden || contentIsHidden
            guard (!newIsHidden || !isHidden) || addingView.isHidden != shouldHideAdd else { return }

            headerView.isHidden = isItemsEmpty
            headerView.content = .title(.init(text: viewData?.title ?? "", color: shouldHideAdd ? UIColor.ud.textDisabled : UIColor.ud.textTitle))
            updateItemViews()
            isHidden = newIsHidden
            addingView.isHidden = shouldHideAdd
            let titleContent = EventBasicCellLikeView.ContentTitle(
                text: I18n.Calendar_Attachment_Add,
                color: isItemsEmpty ? EventEditUIStyle.Color.dynamicGrayText : (shouldHideAdd ? UIColor.ud.textDisabled : UIColor.ud.primaryContentDefault),
                font: UIFont.cd.regularFont(ofSize: 16)
            )
            headerView.icon = .customImageWithoutN3(shouldHideAdd ? iconImageDisabled : iconImage)
            addingView.content = .title(titleContent)
            addingView.icon = isItemsEmpty ? headerView.icon : .empty
        }
    }

    let itemTappedRelay = PublishRelay<ClickType>()

    var addClickHandler: (() -> Void)? {
        didSet {
            addingView.onClick = addClickHandler
        }
    }

    private var itemViewsMap = [Int: ItemView]()
    private let headerView = EventEditCellLikeView()
    private let stackView = UIStackView()
    private let addingView = EventEditCellLikeView()
    private lazy var iconImage = UDIcon.getIconByKeyNoLimitSize(.attachmentOutlined).renderColor(with: .n3)
    private lazy var iconImageDisabled = UDIcon.getIconByKeyNoLimitSize(.attachmentOutlined).renderColor(with: .n4)

    override init(frame: CGRect) {
        super.init(frame: .zero)
        isHidden = true

        let container = UIStackView()
        container.axis = .vertical
        container.backgroundColor = .ud.bgFloat
        addSubview(container)
        container.snp.makeConstraints { $0.edges.equalToSuperview() }

        headerView.icon = .customImage(iconImage)
        headerView.iconSize = EventEditUIStyle.Layout.cellLeftIconSize

        headerView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        container.addArrangedSubview(headerView)
        headerView.snp.makeConstraints { $0.height.equalTo(48) }

        stackView.axis = .vertical
        stackView.backgroundColor = .ud.bgFloat
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: EventEditUIStyle.Layout.eventEditContentLeftMargin, bottom: 0, right: 16)
        container.addArrangedSubview(stackView)

        addingView.icon = .empty
        addingView.iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        addingView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        let titleContent = EventBasicCellLikeView.ContentTitle(
            text: I18n.Calendar_Attachment_Add,
            color: EventEditUIStyle.Color.dynamicGrayText,
            font: UIFont.cd.regularFont(ofSize: 16)
        )
        addingView.content = .title(titleContent)
        container.addArrangedSubview(addingView)
        addingView.snp.makeConstraints { $0.height.equalTo(EventEditUIStyle.Layout.singleLineCellHeight) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateItemViews() {
        guard let viewData = viewData else { return }
        guard viewData.needResetAllItems else {
            // 无增减，仅刷数据
            viewData.items.enumerated().forEach { (index, itemData) in
                itemViewsMap[index]?.viewData = itemData
                if !itemData.token.isEmpty {
                    itemViewsMap[index]?.clickHandler = { [weak self] in
                        var click: ClickType
                        switch $0 {
                        case .open: click = .open(token: itemData.token)
                        case .delete: click = .delete(index: index)
                        case .reUpload: click = .reUpload(index: index)
                        case .jump: click = .jump(link: itemData.googleDriveLink)
                        case .url: click = .url(link: itemData.urlLink, token: itemData.token)
                        }
                        self?.itemTappedRelay.accept(click)
                    }
                }
            }
            return
        }
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        itemViewsMap = .init()
        viewData.items.enumerated().forEach { (index, itemData) in
            let itemView = ItemView()
            itemView.source = viewData.source
            itemView.viewData = itemData
            itemViewsMap[index] = itemView
            itemView.clickHandler = { [weak self] in
                var click: ClickType
                switch $0 {
                case .open: click = .open(token: itemData.token)
                case .delete: click = .delete(index: index)
                case .reUpload: click = .reUpload(index: index)
                case .jump: click = .jump(link: itemData.googleDriveLink)
                case .url: click = .url(link: itemData.urlLink, token: itemData.token)
                }
                self?.itemTappedRelay.accept(click)
            }
            stackView.addArrangedSubview(itemView)
        }

        if !viewData.isEditable, !itemViewsMap.isEmpty {
            let space = UIView()
            space.snp.makeConstraints { $0.height.equalTo(4) }
            stackView.addArrangedSubview(space)
        }
    }
}

extension EventEditAttachmentView {

    enum ClickType {
        case open(token: String = "")
        case delete(index: Int = -1)
        case reUpload(index: Int = -1)
        case jump(link: String = "")
        case url(link: String = "", token: String = "")
    }

    final class ItemView: EventBasicCellLikeView.BackgroundView {

        var source: Rust.CalendarEventSource = .unknownSource
        var secondLine: UIStackView = UIStackView()

        var viewData: EventEditAttachmentItemViewDataType? {
            didSet {
                guard let viewData = viewData, !viewData.hasBeenDeleted else {
                    isHidden = true
                    return
                }
                refreshView(with: viewData, source: source)
            }
        }

        var clickHandler: ((_ action: ClickType) -> Void)?

        private var borderColor: UIColor = .ud.lineBorderCard {
            didSet {
                layer.ud.setBorderColor(borderColor)
            }
        }

        // only for uploadingRefresh
        private var isUploadingFirstResponse = true

        private var tapGesture: UITapGestureRecognizer?

        private func refreshView(with viewData: EventEditAttachmentItemViewDataType, source: Rust.CalendarEventSource) {
            iconImageView.image = viewData.icon
            titleLabel.text = viewData.name
            sizeLabel.text = viewData.sizeString
            riskTag.isHidden = !viewData.isFileRisk
            deleteButton.isHidden = !viewData.canDelete

            // reset components
            progressBar.isHidden = true
            tipLabel.isHidden = true
            loadingIcon.isHidden = true
            reUploadButton.isHidden = true
            badgeView.isHidden = true
            sizeLabel.isHidden = true

            switch viewData.status {
            case .awaiting:
                loadingIcon.isHidden = false
                sizeLabel.isHidden = false

                borderColor = .ud.lineBorderCard
                tapGesture?.isEnabled = false
            case .cancel:
                isHidden = true
            case .failed(let errorTip):
                reUploadButton.isHidden = false
                tipLabel.isHidden = false
                tipLabel.text = errorTip
                tipLabel.textColor = .ud.functionDangerContentDefault
                borderColor = .ud.functionDangerContentDefault
                tapGesture?.isEnabled = false
            case .success:
                sizeLabel.isHidden = false
                let (tip, color) = viewData.tipInfo
                if !tip.isEmpty {
                    tipLabel.text = tip ?? ""
                    tipLabel.textColor = color
                    tipLabel.isHidden = false
                } else {
                    tipLabel.isHidden = true
                }
                tapGesture?.isEnabled = true
                badgeView.isHidden = !(viewData.isLargeAttachments || viewData.type == .url)
                borderColor = .ud.lineBorderCard
            case .uploading(let ratio):
                sizeLabel.isHidden = false
                progressBar.isHidden = false
                progressBar.setProgress(CGFloat(ratio), animated: true)

                // 避免按压态被后续更新刷掉
                if isUploadingFirstResponse {
                    borderColor = .ud.lineBorderCard
                    isUploadingFirstResponse = false
                }
                sizeLabel.text = viewData.sizeString
            }
            verticalBar.isHidden = tipLabel.isHidden || sizeLabel.isHidden

            if source == .google {
                layoutGoogleAttachmentStyle()
            }
        }

        private func layoutGoogleAttachmentStyle() {
            secondLine.isHidden = true
            iconImageView.image = UDIcon.getIconByKey(.fileLinkBlueColorful, size: CGSize(width: 36, height: 36)).withRenderingMode(.alwaysOriginal)
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColors = (.ud.bgFloat, .ud.bgFloat)
            layer.borderWidth = 1
            layer.cornerRadius = 8
            clipsToBounds = true

            onHighLightedChanged = { [weak self] in
                guard let self = self else { return }
                self.layer.ud.setBorderColor($0 ? .ud.primaryContentDefault : self.borderColor)
            }

            addSubview(iconImageView)
            iconImageView.snp.makeConstraints {
                $0.left.top.bottom.equalToSuperview()
                    .inset(UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 0))
                $0.width.equalTo(36)
                $0.height.equalTo(36)
            }

            addSubview(badgeView)
            badgeView.snp.makeConstraints {
                $0.bottom.equalTo(iconImageView).offset(3)
                $0.trailing.equalTo(iconImageView)
                $0.size.equalTo(CGSize(width: 12, height: 12))
            }

            let firstLine = UIStackView(arrangedSubviews: [titleLabel, riskTag])
            firstLine.spacing = 4
            firstLine.alignment = .center
            firstLine.snp.makeConstraints { $0.height.equalTo(22) }

            secondLine = UIStackView(arrangedSubviews: [sizeLabel, verticalBar, tipLabel])
            secondLine.spacing = 8
            secondLine.alignment = .center
            secondLine.snp.makeConstraints { $0.height.equalTo(18) }

            let infos = UIStackView(arrangedSubviews: [firstLine, secondLine])
            infos.axis = .vertical
            infos.alignment = .leading

            reUploadButton.addTarget(self, action: #selector(reUploadTapped), for: .touchUpInside)
            deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

            let container = UIStackView(arrangedSubviews: [infos, loadingIcon, reUploadButton, deleteButton])
            container.spacing = 20
            container.setCustomSpacing(18, after: infos)
            container.alignment = .center

            addSubview(container)
            container.snp.makeConstraints {
                $0.left.equalTo(iconImageView.snp.right).offset(8)
                $0.right.equalTo(-18)
                $0.centerY.equalToSuperview()
            }

            addSubview(progressBar)
            progressBar.snp.makeConstraints {
                $0.left.right.bottom.equalToSuperview()
            }

            let tap = UITapGestureRecognizer(target: self, action: #selector(itemTapped))
            addGestureRecognizer(tap)
            tapGesture = tap
        }

        private(set) var iconImageView = UIImageView()

        private(set) lazy var badgeView: UIView = {
            let badgeView = UIView()
            badgeView.backgroundColor = UIColor.ud.bgBody
            badgeView.contentMode = .center
            badgeView.layer.cornerRadius = 6
            badgeView.snp.makeConstraints { $0.size.equalTo(CGSize(width: 12, height: 12)) }

            let innerImageView = UIImageView()
            innerImageView.image = UDIcon.getIconByKey(.cloudOutlined,
                                                       renderingMode: .automatic,
                                                       iconColor: UIColor.ud.primaryContentDefault)

            badgeView.addSubview(innerImageView)
            innerImageView.snp.makeConstraints {
                $0.top.equalTo(1)
                $0.bottom.equalTo(-3)
                $0.leading.equalTo(2)
                $0.trailing.equalTo(-2)
            }
            return badgeView
        }()

        private(set) var titleLabel = UILabel.cd.textLabel()

        private(set) lazy var riskTag: UDTag = {
            let tag = UDTag(withText: I18n.Lark_FileSecurity_Tag_Risky)
            tag.sizeClass = .mini
            tag.colorScheme = .red
            return tag
        }()

        private(set) var sizeLabel = UILabel.cd.subTitleLabel(fontSize: 12)

        private(set) lazy var verticalBar: UIView = {
            let bar = UIView()
            bar.backgroundColor = UIColor.ud.lineDividerDefault
            bar.snp.makeConstraints { $0.size.equalTo(CGSize(width: 1, height: 8)) }
            return bar
        }()

        private(set) lazy var tipLabel = UILabel.cd.subTitleLabel(fontSize: 12)

        private let reUploadButton: UIButton = {
            let button = UIButton.cd.button()
            let reloadImage = UDIcon.getIconByKeyNoLimitSize(.refreshOutlined, renderingMode: .alwaysOriginal, iconColor: .ud.primaryContentDefault)
            button.setImage(reloadImage, for: .normal)
            button.snp.makeConstraints { $0.size.equalTo(CGSize(width: 20, height: 20)) }
            return button
        }()

        private let loadingIcon = UDLoading.spin(config: .init(indicatorConfig: .init(size: 20, color: .ud.primaryContentDefault), textLabelConfig: nil))

        private let deleteButton: UIButton = {
            let button = UIButton.cd.button()
            let trashImage = UDIcon.getIconByKeyNoLimitSize(.deleteTrashOutlined, renderingMode: .alwaysOriginal, iconColor: .ud.iconN2)
            button.setImage(trashImage, for: .normal)
            button.snp.makeConstraints { $0.size.equalTo(CGSize(width: 20, height: 20)) }
            return button
        }()

        private let progressBar: UDProgressView = {
            let bar = UDProgressView(config: .init(themeColor: .init(successIndicatorColor: .ud.primaryContentDefault)),
                                     layoutConfig: .init(linearSmallCornerRadius: 0, linearProgressDefaultHeight: 6))
            return bar
        }()

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc
        private func reUploadTapped() {
            clickHandler?(.reUpload())
        }

        @objc
        private func deleteTapped() {
            clickHandler?(.delete())
        }

        @objc
        private func itemTapped() {
            if source == .google {
                clickHandler?(.jump())
            } else if viewData?.type == .url {
                clickHandler?(.url())
            } else {
                clickHandler?(.open())
            }
        }
    }
}
