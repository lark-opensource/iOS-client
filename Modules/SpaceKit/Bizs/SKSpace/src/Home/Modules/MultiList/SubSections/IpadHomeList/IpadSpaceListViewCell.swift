//
//  IpadHomeListViewCell.swift
//  SKSpace
//
//  Created by majie.7 on 2023/9/22.
//

import SKCommon
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignAvatar
import LarkDocsIcon
import SKFoundation
import LarkContainer
import SKResource
import RxSwift
import SKUIKit


class IpadSpaceListViewCell: UICollectionViewCell {
    
    private lazy var pickBackgroundView: SKPickerBackgroundView = {
        let view = SKPickerBackgroundView()
        view.layer.cornerRadius = 5
        return view
    }()
    
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    private lazy var titleView: SKListCellView = {
        let view = SKListCellView()
        return view
    }()
    
    private lazy var avatarView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 6
        view.alignment = .center
        return view
    }()
    
    private lazy var avatarViewControl: UIControl = {
        let view = UIControl()
        view.backgroundColor = .clear
        view.docs.addStandardHighlight()
        return view
    }()
    
    private lazy var avatarIcon: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .clear
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textCaption
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var placeHolderView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textCaption
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var singleTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textCaption
        label.font = .systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()
    
    private lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.moreOutlined,
                                            iconColor: UDColor.iconN2,
                                            size: CGSize(width: 16, height: 16)),
                        for: .normal)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -16, left: -16, bottom: -16, right: -16)
        button.docs.addStandardHighlight()
        return button
    }()
    
    private lazy var indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    private var reuseBag = DisposeBag()
    private var disposeBag = DisposeBag()
    
    private(set) var hoverGesture: UIGestureRecognizer?
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                pickBackgroundView.isHighlighted = true
            } else {
                // delay 一下是为了让高亮效果停留一下，避免闪烁的效果
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) { [weak self] in
                    guard self?.isHighlighted == false else { return }
                    self?.pickBackgroundView.isHighlighted = false
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        if #available(iOS 13.0, *) {
            setupHoverInteraction()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if contentView.frame.width < 780, contentView.frame.width >= 600 {
            // 中尺寸时隐藏第二列view
            avatarView.isHidden = true
            timeLabel.isHidden = true
            avatarViewControl.isHidden = true
            
            singleTimeLabel.isHidden = false
            titleView.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(iconView.snp.right).offset(16)
                make.right.lessThanOrEqualTo(singleTimeLabel.snp.left).offset(-16)
            }
        } else if contentView.frame.width < 600 {
            // 小尺寸时隐藏二、三列view，仅展示标题和more按钮
            avatarView.isHidden = true
            timeLabel.isHidden = true
            singleTimeLabel.isHidden = true
            avatarViewControl.isHidden = true
            
            titleView.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(iconView.snp.right).offset(16)
                make.right.lessThanOrEqualTo(moreButton.snp.left).offset(-16)
            }
        } else {
            // 全尺寸展示所有需要展示的view元素
            singleTimeLabel.isHidden = true
            
            avatarView.isHidden = false
            avatarViewControl.isHidden = false
            timeLabel.isHidden = false
            titleView.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(iconView.snp.right).offset(16)
                make.right.lessThanOrEqualTo(avatarView.snp.left).offset(-16)
            }
        }
    }
    
    private func setupUI() {
        contentView.addSubview(pickBackgroundView)
        contentView.addSubview(moreButton)
        contentView.addSubview(timeLabel)
        contentView.addSubview(avatarView)
        contentView.addSubview(titleView)
        contentView.addSubview(iconView)
        contentView.addSubview(indicatorView)
        contentView.addSubview(singleTimeLabel)
        
        pickBackgroundView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
        
        moreButton.snp.makeConstraints { make in
            make.height.width.equalTo(24)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(36)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.width.equalTo(160)
            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.right.equalTo(moreButton.snp.left).offset(-16)
        }
        
        avatarView.snp.makeConstraints { make in
            make.width.equalTo(160)
            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.right.equalTo(timeLabel.snp.left).offset(-16)
        }
        
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(24)
        }
        
        titleView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconView.snp.right).offset(16)
            make.right.lessThanOrEqualTo(avatarView.snp.left).offset(-16)
        }
        
        indicatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
            make.left.equalToSuperview().inset(24)
            make.right.equalToSuperview().inset(24)
        }
        
        singleTimeLabel.snp.makeConstraints { make in
            make.width.equalTo(160)
            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.right.equalTo(moreButton.snp.left).offset(-16)
        }
        
        setupAvatarUI()
    }
    
    private func setupAvatarUI() {
        avatarView.addArrangedSubview(avatarIcon)
        avatarIcon.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        avatarView.addArrangedSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
        }
        avatarView.addArrangedSubview(placeHolderView)
        
        contentView.addSubview(avatarViewControl)
        avatarViewControl.snp.makeConstraints { make in
            make.left.equalTo(avatarIcon.snp.left)
            make.right.equalTo(nameLabel.snp.right)
            make.top.equalTo(nameLabel.snp.top)
            make.bottom.equalTo(nameLabel.snp.bottom)
        }
    }
    
    func update(item: SpaceListItem) {
        let timeText = item.entry.timeTitleBySortType(sortType: item.sortType)
        timeLabel.text = timeText
        if item.sortType == .title {
            singleTimeLabel.text = item.entry.timeTitleBySortType(sortType: .lastModifiedTime)
        } else {
            singleTimeLabel.text = timeText
        }
        
        setState(enable: item.enable)
        setupIcon(item: item)
        setTitle(item: item)
        
        setupMoreItem(item: item)
    }
    
    // 展示的第一列和第二列的排序时间
    func updateMultiTimeInfo(first: String, second: String) {
        avatarIcon.image = nil
        avatarIcon.isHidden = true
        avatarViewControl.isHidden = true
        nameLabel.text = first
        timeLabel.text = second
    }
    
    private func setState(enable: Bool) {
        contentView.alpha = enable ? 1.0 : 0.3
    }
    
    private func setTitle(item: SpaceListItem) {
        var views: [SKListCellElementType] = [.titleLabel(text: item.title),
                                              .template(visable: item.hasTemplateTag),
                                              .star(visable: item.isStar)]
        if let tagValue = item.organizationTagValue, UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
            views.insert(.customTag(text: tagValue, visable: !tagValue.isEmpty), at: 2)
        } else {
            views.insert(.external(visable: item.isExternal), at: 2)
        }
        titleView.update(views: views)
    }
    
    // nolint: duplicated_code
    private func setupIcon(item: SpaceListItem) {
        switch item.listIconType {
        case let .thumbIcon(thumbInfo):
            iconView.layer.cornerRadius = 6
            iconView.di.setCustomDocsIcon(model: thumbInfo,
                                          container: ContainerInfo(isShortCut: item.isShortCut),
                                          errorImage: BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail)
        case .icon:
            iconView.di.setDocsImage(iconInfo: item.entry.iconInfo ?? "",
                                     token: item.entry.realToken,
                                     type: item.entry.realType,
                                     shape: .SQUARE,
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
    
    func setupAvator(item: SpaceListItem, clickHandler: ((String) -> Void)?) {
        if let avatarUrl = item.entry.ownerAvatarUrl {
            avatarIcon.kf.setImage(with: URL(string: avatarUrl),
                                   placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
        }
        
        nameLabel.text = item.entry.owner
        
        avatarViewControl.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { _ in
                guard let ownerId = item.entry.ownerID else {
                    return
                }
                clickHandler?(ownerId)
            })
            .disposed(by: reuseBag)
    }
    
    private func setupMoreItem(item: SpaceListItem) {
        moreButton.isEnabled = item.enable
        moreButton.rx.tap.subscribe(onNext: { [weak moreButton] _ in
            guard let moreButton else { return }
            item.moreHandler?(moreButton)
        }).disposed(by: reuseBag)
    }
    
    @available(iOS 13.0, *)
    private func setupHoverInteraction() {
        let gesture = UIHoverGestureRecognizer()
        gesture.rx.event.subscribe(onNext: { [weak self] gesture in
            guard let self = self else { return }
            switch gesture.state {
            case .began, .changed:
                self.pickBackgroundView.isHovered = true
            case .ended, .cancelled:
                self.pickBackgroundView.isHovered = false
            default:
                break
            }
        }).disposed(by: disposeBag)
        hoverGesture = gesture
        contentView.addGestureRecognizer(gesture)
    }
}
