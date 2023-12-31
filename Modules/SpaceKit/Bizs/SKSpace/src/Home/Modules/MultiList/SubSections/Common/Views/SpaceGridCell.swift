//
//  SpaceGridCell.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/4.
// swiftlint:disable file_length

import UIKit
import SnapKit
import RxSwift
import RxRelay
import RxCocoa
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignTheme
import UniverseDesignTag
import SKResource
import SKUIKit
import SKCommon
import SKFoundation
import LarkInteraction
import ByteWebImage
import SKInfra
import LarkDocsIcon
import LarkContainer

extension SpaceGridCell {
    static let thumbnailSizeForRequest: CGSize = {
        let maxWidth: CGFloat = 232
        let imageWidth = maxWidth - Layout.thumbnailEdgesInset * 2
        let maxHeight: CGFloat = 144
        let imageHeight = maxHeight - Layout.thumbnailEdgesInset - Layout.infoPanelHeight
        return CGSize(width: imageWidth * SKDisplay.scale,
                      height: imageHeight * SKDisplay.scale)
    }()
}

private extension SpaceGridCell {

    // 提供左上角、右上角是圆角的背景颜色，同时不影响外层设置shadow
    class ThumbnailShadowView: UIView {
        private lazy var backgroundView: UIView = {
            let view = UIView()
            view.clipsToBounds = true
            view.layer.cornerRadius = 3
            view.layer.maskedCorners = .top
            view.backgroundColor = UDColor.bgBody
            return view
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupUI()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupUI()
        }

        private func setupUI() {
            backgroundColor = .clear
            addSubview(backgroundView)
            backgroundView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    enum Layout {
        static let bigTypeImageSize = 48
        static let thumbnailEdgesInset: CGFloat = 8
        static let statusSize: CGFloat = 12
        static let iconSize: CGFloat = 20
        static let iconTitleSpacing: CGFloat = 8
        static var iconTitleSpacingWithStatus: CGFloat { iconTitleSpacing + statusSize / 2 }
        static let infoPanelHeight: CGFloat = 60
        static let titleMoreSpacing = 8
        static let moreButtonSize = 20
        static let tipsSize: CGFloat = 20
        static let tipsEdgeInset = 8
        static let thumbnailInfoSeperatorHeight = 0.5
    }
}

class SpaceGridCell: UICollectionViewCell {

    private var hasBeenReused = false

    // MARK: - info panels
    private lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()

    /// shortcut
    private lazy var shortCutImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.wikiShortcutarrowColorful
        return imageView
    }()

    private lazy var syncStatusView: SyncStatusView = {
        let view = SyncStatusView()
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.ud.setBorderColor(UDColor.bgBody)
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UDColor.textTitle
        label.layer.masksToBounds = true
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var moreButton: UIButton = {
        let button = UIButton()
        button.hitTestEdgeInsets = UIEdgeInsets(top: -14, left: -24, bottom: -14, right: 0)
        button.setImage(UDIcon.moreVerticalOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UDColor.iconN2
        return button
    }()

    // [iconImageView(redPointView)(statusImageView) - titleLabel - (templateTag/externalTag) - moreButton]
    private lazy var infoPanelView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = UDColor.bgBody
        view.alignment = .center
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 8
        return view
    }()
    
    private lazy var infoPanleTitleAndTagView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = UDColor.bgBody
        view.alignment = .leading
        view.axis = .vertical
        view.distribution = .fill
        view.spacing = 2
        return view
    }()
    
    private lazy var tagViews: SKListCellView = {
        let view = SKListCellView()
        return view
    }()

    // MARK: - tips
    private lazy var accessoryButton: UIButton = {
        let permTipButton = UIButton()
        permTipButton.setImage(UDIcon.warningOutlined.withRenderingMode(.alwaysTemplate),
                               for: .normal)
        permTipButton.backgroundColor = UDColor.bgBody
        permTipButton.imageView?.contentMode = .scaleAspectFit
        permTipButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        return permTipButton
    }()

    private lazy var starView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.collectFilled, iconColor: UDColor.colorfulYellow, size: CGSize(width: 14, height: 14))
        view.backgroundColor = UDColor.bgBody
        view.contentMode = .center
        return view
    }()

    // [accessoryButton - starView]
    private lazy var tipsStackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 4
        return view
    }()

    private lazy var bigTypeImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var thumbnailImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UDColor.bgBody.nonDynamic
        view.ud.setMaskView()
        view.contentMode = .center
        return view
    }()

    private lazy var thumbnailShadowView: ThumbnailShadowView = {
        let view = ThumbnailShadowView()
        view.layer.ud.setShadowColor(UDColor.shadowDefaultSm)
        view.layer.shadowOffset = CGSize(width: 2, height: -2)
        view.layer.shadowRadius = 6
        view.layer.shadowOpacity = 0.5
        return view
    }()

    private lazy var seperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineBorderCard
        return view
    }()

    // 存储当前使用的缩略图，布局变化的时候用于重新裁剪图片为合适的大小
    private var thumbnailInfo: SpaceList.ThumbnailInfo?
    // 记录上次使用缩略图时，ImageView 的尺寸，用于判断布局是否发生变化
    private var previousThumbnailSize: CGSize?

    private var accurateThumbnailSize: CGSize {
        let thumbnailEdgeInsets = UIEdgeInsets(top: Layout.thumbnailEdgesInset,
                                               left: Layout.thumbnailEdgesInset,
                                               bottom: Layout.infoPanelHeight,
                                               right: Layout.thumbnailEdgesInset)
        return frame.inset(by: thumbnailEdgeInsets).size
    }

    private var hoverGesture: UIGestureRecognizer?

    private let disposeBag = DisposeBag()
    private var reuseBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
        thumbnailImageView.image = nil
        thumbnailImageView.contentMode = .center
        thumbnailImageView.backgroundColor = UDColor.bgBody.nonDynamic
        bigTypeImageView.image = nil
        iconImageView.image = nil
        iconImageView.layer.cornerRadius = 0
        thumbnailInfo = nil
        previousThumbnailSize = nil
        hasBeenReused = true
    }

    private func setupUI() {
        contentView.backgroundColor = UDColor.bgBodyOverlay
        contentView.layer.ud.setBorderColor(UDColor.lineBorderCard)
        contentView.layer.borderWidth = 0.5
        contentView.layer.cornerRadius = 6

        contentView.addSubview(thumbnailShadowView)
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(bigTypeImageView)
        contentView.addSubview(infoPanelView)
        contentView.addSubview(tipsStackView)
        contentView.addSubview(seperatorView)

        thumbnailShadowView.snp.makeConstraints { make in
            make.edges.equalTo(thumbnailImageView)
        }

        thumbnailImageView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview().inset(Layout.thumbnailEdgesInset)
            make.bottom.equalTo(infoPanelView.snp.top)
        }

        bigTypeImageView.snp.makeConstraints { make in
            make.center.equalTo(thumbnailImageView)
            make.width.height.equalTo(Layout.bigTypeImageSize)
        }

        seperatorView.snp.makeConstraints { make in
            make.left.right.top.equalTo(infoPanelView)
            make.height.equalTo(Layout.thumbnailInfoSeperatorHeight)
        }

        infoPanelView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(Layout.infoPanelHeight)
        }
        setupInfoPanel()

        tipsStackView.snp.makeConstraints { make in
            make.top.right.equalToSuperview().inset(Layout.tipsEdgeInset)
        }
        setupTips()

        moreButton.docs.addHighlight(with: .zero, radius: 4)

        if #available(iOS 13.0, *) {
            setupHoverInteraction()
        }
    }

    @available(iOS 13.0, *)
    private func setupHoverInteraction() {
        let gesture = UIHoverGestureRecognizer()
        gesture.rx.event.subscribe(onNext: { [weak self] gesture in
            guard let self = self else { return }
            switch gesture.state {
            case .began, .changed:
                self.contentView.layer.ud.setBorderColor(UIColor.ud.colorfulBlue)
            case .ended, .cancelled:
                self.contentView.layer.ud.setBorderColor(UDColor.lineBorderCard)
            default:
                break
            }
        }).disposed(by: disposeBag)
        hoverGesture = gesture
        contentView.addGestureRecognizer(gesture)
    }

    private func setupInfoPanel() {
        infoPanelView.addArrangedSubview(iconImageView)
        infoPanelView.addSubview(shortCutImageView)
        infoPanelView.addSubview(syncStatusView)
        infoPanelView.addArrangedSubview(infoPanleTitleAndTagView)
        infoPanelView.addArrangedSubview(moreButton)

        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(8)
            make.width.height.equalTo(Layout.iconSize)
        }
        shortCutImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(iconImageView)
            make.center.equalTo(iconImageView)
        }


        syncStatusView.layer.cornerRadius = Layout.statusSize / 2
        syncStatusView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.statusSize)
            make.centerX.equalTo(iconImageView.snp.right)
            make.centerY.equalTo(iconImageView.snp.bottom)
        }
        infoPanleTitleAndTagView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview().offset(10)
            make.bottom.lessThanOrEqualToSuperview().offset(-10)
            make.right.lessThanOrEqualTo(moreButton.snp.left).offset(-Layout.titleMoreSpacing)
            make.centerY.equalToSuperview()
        }
        setupInfoPanelTitleAndTags()

        moreButton.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.moreButtonSize)
        }
    }
    
    private func setupInfoPanelTitleAndTags() {
        infoPanleTitleAndTagView.addArrangedSubview(titleLabel)
        infoPanleTitleAndTagView.addArrangedSubview(tagViews)
        
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        tagViews.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
    }

    private func setupTips() {
        tipsStackView.addArrangedSubview(starView)
        tipsStackView.addArrangedSubview(accessoryButton)

        starView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.tipsSize)
        }
        starView.layer.cornerRadius = Layout.tipsSize / 2
        starView.clipsToBounds = true

        accessoryButton.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.tipsSize)
        }
        accessoryButton.layer.cornerRadius = Layout.tipsSize / 2
        accessoryButton.clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 避免离屏渲染
        thumbnailShadowView.layer.shadowPath = UIBezierPath(rect: thumbnailShadowView.bounds).cgPath

        let path = UIBezierPath(roundedRect: thumbnailImageView.bounds,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: CGSize(width: 3, height: 3))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        thumbnailImageView.layer.mask = mask

        // iPad 分屏导致布局变化后，需要重新计算一次缩略图尺寸
        if let thumbnailInfo = thumbnailInfo,
           let previousThumbnailSize = previousThumbnailSize,
           previousThumbnailSize != accurateThumbnailSize {
            setup(thumbnailInfo: thumbnailInfo)
        }
    }
}

extension SpaceGridCell {
    func update(item: SpaceListItem) {
        hoverGesture?.isEnabled = item.enable
        contentView.alpha = item.enable ? 1 : 0.3
        moreButton.isUserInteractionEnabled = item.enable
        titleLabel.text = item.title

        if let moreHandler = item.moreHandler {
            moreButton.isHidden = false
            moreButton.isEnabled = item.moreEnable
            moreButton.rx.tap.asDriver()
                .drive(onNext: { [weak self] in
                    guard let self = self else { return }
                    moreHandler(self)
                })
                .disposed(by: reuseBag)
        } else {
            moreButton.isHidden = true
        }

        starView.isHidden = !item.isStar

        var views: [SKListCellElementType] = [.template(visable: item.hasTemplateTag)]
        if let value = item.organizationTagValue, UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
            views.append(.customTag(text: value, visable: !value.isEmpty))
        } else {
            views.append(.external(visable: item.isExternal))
        }
        tagViews.update(views: views)
        shortCutImageView.isHidden = !item.isShortCut

        setup(accessoryItem: item.accessoryItem)
        setupIcon(item: item)
        setup(syncStatus: item.syncStatus)
        setup(thumbnailType: item.thumbnailType)
    }
    
    // nolint: duplicated_code
    private func setupIcon(item: SpaceListItem) {
        switch item.gridIconType {
        case let .thumbIcon(thumbInfo):
            iconImageView.layer.cornerRadius = 6
            iconImageView.di.setCustomDocsIcon(model: thumbInfo,
                                               container: ContainerInfo(isShortCut: item.isShortCut),
                                               errorImage: BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail)
        case .icon:
            iconImageView.di.setDocsImage(iconInfo: item.entry.iconInfo ?? "",
                                          url: item.entry.originUrl ?? "",
                                          shape: .SQUARE,
                                          container: ContainerInfo(isShortCut: item.isShortCut,
                                                                   isShareFolder: item.entry.isShareFolder),
                                          userResolver: Container.shared.getCurrentUserResolver())
        default:
            iconImageView.di.setDocsImage(iconInfo: item.entry.iconInfo ?? "",
                                          token: item.entry.realToken,
                                          type: item.entry.realType,
                                          container: ContainerInfo(isShortCut: item.isShortCut,
                                                                   isShareFolder: item.entry.isShareFolder),
                                          userResolver: Container.shared.getCurrentUserResolver())
        }
    }

    private func setup(thumbnailType: SpaceListItem.ThumbnailType?) {
        guard let thumbnailType = thumbnailType else {
            DocsLogger.error("space.grid.cell.thumbnail --- thumbnail type is nil!")
            return
        }
        switch thumbnailType {
        case let .bigType(image):
            bigTypeImageView.isHidden = false
            thumbnailImageView.isHidden = true
            bigTypeImageView.image = image
        case let .thumbnail(info):
            self.setup(thumbnailInfo: info)
        }
    }

    private func setup(thumbnailInfo info: SpaceList.ThumbnailInfo) {
        thumbnailInfo = info
        let processer: SpaceThumbnailProcesser
        let imageSize = accurateThumbnailSize
        previousThumbnailSize = imageSize
        let handler: (SpaceThumbnailManager.Response) -> Void
        let errorHandler: (SpaceThumbnailManager.Response) -> Void

        bigTypeImageView.isHidden = true
        thumbnailImageView.isHidden = false
        thumbnailImageView.image = info.placeholder
        let resizeImageInsets = UIEdgeInsets(top: 4, left: 4, bottom: 6, right: 4)
        let resizeInfo = SpaceThumbnailProcesserResizeInfo(targetSize: imageSize, imageInsets: resizeImageInsets)
        processer = SpaceGridListProcesser(viewSize: imageSize, resizeInfo: resizeInfo)
        handler = { [weak self] response in
            guard let self = self else { return }
            self.thumbnailImageView.contentMode = .scaleAspectFit
            self.thumbnailImageView.image = response.image
            // 因为缩略图暂时还没有适配 DM，产品要求展示特殊兜底图时，需要加上白色背景，所以需要判断一下图片类型
            if response.type == .thumbnail {
                self.thumbnailImageView.backgroundColor = .clear
            } else {
                self.thumbnailImageView.backgroundColor = UDColor.bgBody.nonDynamic
            }
            if #available(iOS 15.4, *) {
                // iOS 15.4 上存在首次渲染白屏问题，暂不确定原因，这里重新 layout 一次后可以正常展示
                // cell 被重用之后可以正常展示，因此为了避免后续渲染重复layout，这里在 cell 被重用后不再触发 layout
                if !self.hasBeenReused {
                    self.setNeedsLayout()
                }
            }
        }
        errorHandler = { [weak self] response in
            self?.thumbnailImageView.contentMode = .center
            self?.thumbnailImageView.image = response.image
            self?.thumbnailImageView.backgroundColor = UDColor.bgBody.nonDynamic
        }

        let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)
        let request = SpaceThumbnailManager.Request(token: info.token,
                                                    info: info.thumbInfo,
                                                    source: info.source,
                                                    fileType: info.fileType,
                                                    placeholderImage: nil,
                                                    failureImage: nil,
                                                    processer: processer)
        manager?.getThumbnailWithType(request: request)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: handler, onError: { _ in
                let errorImage = info.failedImage ?? BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail
                errorHandler(.init(image: errorImage, type: .failureImage))
            })
            .disposed(by: reuseBag)
    }

    private func setup(syncStatus: SpaceListItem.SyncStatus) {
        if syncStatus.show {
            syncStatusView.isHidden = false
            syncStatusView.image = syncStatus.image
            if syncStatus.isSyncing {
                syncStatusView.startRotation()
            } else {
                syncStatusView.stopRotation()
            }
            infoPanelView.setCustomSpacing(Layout.iconTitleSpacingWithStatus, after: iconImageView)
        } else {
            syncStatusView.stopRotation()
            syncStatusView.isHidden = true
            infoPanelView.setCustomSpacing(Layout.iconTitleSpacing, after: iconImageView)
        }
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
}
