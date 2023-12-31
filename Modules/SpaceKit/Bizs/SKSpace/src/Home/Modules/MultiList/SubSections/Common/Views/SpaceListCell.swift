//
//  SpaceListCell.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/4.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxRelay
import SKUIKit
import LarkUIKit
import UniverseDesignColor
import SKResource
import SKCommon
import SKFoundation
import UniverseDesignBadge
import ByteWebImage
import UniverseDesignIcon
import UniverseDesignTag
import SKInfra
import LarkDocsIcon
import LarkContainer

private extension Notification.Name {
    static let SpaceListCellDidBeginSlide = Notification.Name(rawValue: "SpaceListCellDidBeginSlide")
}

private extension SpaceListCell {
    enum Layout {
        static let redPointSize: CGFloat = 8
        static let iconLeftInset = 16
        static let iconSize: CGFloat = 40
        static let iconSizeForBase: CGFloat = 36
        static let iconPanelSpacing: CGFloat = 12

        static let infoTopInset = 12
        static let infoPanelHeight: CGFloat = 24
        static let infoDetailSpacing = 2
        static let starSize = 16

        static let detailPanelHeight = 20
        static let detailStatusSize: CGFloat = 12

        static let panelRightInset = 16
        static let tipsSize = 20
        static let tipsRightInset: CGFloat = 22

        static let cellHeight: CGFloat = 68
        static var infoCenterAlignTopInset: CGFloat {
            (cellHeight - infoPanelHeight) / 2
        }
    }
}

class SpaceListCell: SlideableCell {

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var infoPanelView: SKListCellView = {
        let view = SKListCellView()
        return view
    }()

    private lazy var starView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.collectFilled.ud.withTintColor(UDColor.colorfulYellow)
        return view
    }()

    private lazy var syncStatusView = SyncStatusView()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UDColor.textPlaceholder
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var detailPanelView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 4
        return view
    }()

    private lazy var panelContainerView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var accessoryButton: UIButton = {
        let accessoryButton = UIButton()
        return accessoryButton
    }()

    private lazy var containerRightAnchor = UIView()

    // [iconView - panelContainerView - permissionContainerView - containerRightAnchor]
    private lazy var containerStackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 12
        return view
    }()

    private var swipeHandler: ((UIView, SlideAction) -> Void)?
    private var tracker: SpaceListCellTracker?

    // 不需要重用的 bag
    private let disposeBag = DisposeBag()
    // 重用时清理的 bag
    private var reuseBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        delegate = self
        container.addSubview(containerStackView)
        containerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerStackView.addArrangedSubview(iconView)
        containerStackView.setCustomSpacing(Layout.iconPanelSpacing, after: iconView)
        containerStackView.addArrangedSubview(panelContainerView)
        containerStackView.addArrangedSubview(accessoryButton)
        containerStackView.addArrangedSubview(containerRightAnchor)

        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.iconSize)
            make.left.equalToSuperview().inset(Layout.iconLeftInset)
        }
        panelContainerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualTo(containerRightAnchor)
                .offset(-Layout.panelRightInset)
            make.right.lessThanOrEqualTo(accessoryButton.snp.left)
                .offset(-Layout.panelRightInset)
        }
        panelContainerView.addSubview(infoPanelView)
        infoPanelView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.top.equalToSuperview().inset(Layout.infoTopInset)
            make.height.equalTo(Layout.infoPanelHeight)
        }

        panelContainerView.addSubview(detailPanelView)
        detailPanelView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.top.equalTo(infoPanelView.snp.bottom).offset(Layout.infoDetailSpacing)
            make.height.equalTo(Layout.detailPanelHeight)
        }
        setupDetailPanel()

        accessoryButton.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.tipsSize)
        }
        containerStackView.setCustomSpacing(Layout.tipsRightInset, after: accessoryButton)

        containerRightAnchor.snp.makeConstraints { make in
            make.width.equalTo(0)
            make.top.bottom.equalToSuperview()
        }

        NotificationCenter.default.rx.notification(.SpaceListCellDidBeginSlide)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let self = self,
                      let currentCell = notification.object as? SpaceListCell,
                      self != currentCell else {
                    return
                }
                if self.swipeState != .hide {
                    self.cancelCell()
                }
            })
            .disposed(by: disposeBag)
    }

    private func setupDetailPanel() {
        detailPanelView.addArrangedSubview(syncStatusView)
        syncStatusView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.detailStatusSize)
        }
        detailPanelView.addArrangedSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
        }
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.layer.cornerRadius = 0
        cancelCell(animated: false)
        enable = true
        setSlideAction(actions: nil)
        swipeHandler = nil
        reuseBag = DisposeBag()
    }
}

extension SpaceListCell {
    func update(item: SpaceListItem, tracker: SpaceListCellTracker) {
        self.tracker = tracker
        container.alpha = item.enable ? 1 : 0.3
        if item.enable {
            setup(slideConfig: item.slideConfig)
        } else {
            setup(slideConfig: nil)
        }
        var views: [SKListCellElementType] = [.titleLabel(text: item.title),
                                              .template(visable: item.hasTemplateTag),
                                              .star(visable: item.isStar)]
        if let tagValue = item.organizationTagValue, UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
            views.insert(.customTag(text: tagValue, visable: !tagValue.isEmpty), at: 2)
        } else {
            views.insert(.external(visable: item.isExternal), at: 2)
        }
        infoPanelView.update(views: views)

        setupIcon(item: item)
        setup(accessoryItem: item.accessoryItem)
        setup(syncStatus: item.syncStatus, subtitle: item.subtitle)
    }

    private func setup(accessoryItem: SpaceListItem.AccessoryItem?) {
        guard let accessoryItem = accessoryItem else {
            accessoryButton.isHidden = true
            return
        }
        accessoryButton.isHidden = false
        accessoryButton.setImage(accessoryItem.image, for: .normal)
        accessoryButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                accessoryItem.handler(self)
            })
            .disposed(by: reuseBag)
    }

    private func setup(slideConfig: SpaceListItem.SlideConfig?) {
        guard let config = slideConfig else {
            swipeEnbale = false
            setSlideAction(actions: nil)
            return
        }
        swipeEnbale = true
        swipeHandler = config.handler
        setSlideAction(actions: config.actions)
    }
    
    private func updateIconSizeForBase() {
        iconView.snp.remakeConstraints { make in
            make.width.height.equalTo(Layout.iconSizeForBase)
            make.left.equalToSuperview().inset(Layout.iconLeftInset)
        }
    }
    
    // nolint: duplicated_code
    private func setupIcon(item: SpaceListItem) {
        
        switch item.listIconType {
        case let .thumbIcon(thumbInfo):
            iconView.layer.cornerRadius = 6
            iconView.di.setCustomDocsIcon(model: thumbInfo,
                                          container: ContainerInfo(isShortCut: item.isShortCut),
                                          errorImage: BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail)
        case let .icon(_, preferSquareDefaultIcon):
            if preferSquareDefaultIcon {
                updateIconSizeForBase()
            }
            iconView.di.setDocsImage(iconInfo: item.entry.iconInfo ?? "",
                                    token: item.entry.realToken,
                                    type: item.entry.realType,
                                    shape: preferSquareDefaultIcon ? .SQUARE : .CIRCLE,
                                          container: ContainerInfo(isShortCut: item.isShortCut,
                                                                   isShareFolder: item.entry.isShareFolder),
                                     userResolver: Container.shared.getCurrentUserResolver())
        default:
            iconView.di.setDocsImage(iconInfo: item.entry.iconInfo ?? "",
                                     token: item.entry.realToken,
                                     type: item.entry.realType,
                                     container: ContainerInfo(isShortCut: item.isShortCut,
                                                              isShareFolder: item.entry.isShareFolder),
                                     userResolver: Container.shared.getCurrentUserResolver())
        }
    } 

    private func setup(syncStatus: SpaceListItem.SyncStatus, subtitle: String?) {
        if subtitle == nil {
            detailPanelView.isHidden = true
            infoPanelView.snp.updateConstraints { make in
                make.top.equalToSuperview().inset(Layout.infoCenterAlignTopInset)
            }
            return
        }

        detailPanelView.isHidden = false
        infoPanelView.snp.updateConstraints { make in
            make.top.equalToSuperview().inset(Layout.infoTopInset)
        }
        if syncStatus.show {
            syncStatusView.isHidden = false
            subtitleLabel.text = syncStatus.title
            syncStatusView.image = syncStatus.image
            if syncStatus.isSyncing {
                syncStatusView.startRotation()
            } else {
                syncStatusView.stopRotation()
            }
        } else {
            subtitleLabel.text = subtitle
            syncStatusView.stopRotation()
            syncStatusView.isHidden = true
        }
    }
}

extension SpaceListCell: OneCellDragged {
    func getSlideAction(for file: SpaceEntry, source: FileSource) -> [SlideAction]? {
        nil
    }

    func cancelDraggedView(to: SlideableCell) {}

    func cancelOtherCell(current: SlideableCell) {
        NotificationCenter.default.post(name: .SpaceListCellDidBeginSlide, object: self)
    }

    func setDraggedView(to: SlideableCell) {
        tracker?.reportLeftSlide()
        tracker?.reportShowLeftSlide()
        tracker?.reportShowListSlide()
    }

    func performAction(action: SlideAction, cell: SlideableCell?) {
        cancelCell()
        swipeHandler?(self, action)
    }

    func disableScroll() {}

    func enableScroll() {}
}
