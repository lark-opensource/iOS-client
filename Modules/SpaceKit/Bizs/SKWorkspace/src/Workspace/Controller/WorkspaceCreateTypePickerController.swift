//
//  WorkspaceCreateTypePickerController.swift
//  SKWorkspace
//
//  Created by Weston Wu on 2023/9/27.
//

import Foundation
import SKUIKit
import UniverseDesignColor
import UniverseDesignTag
import SnapKit
import RxSwift
import RxCocoa
import SKCommon
import SKResource

public class WorkspaceCreateTypePickerController: SKPanelController {

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .leading
        view.distribution = .fill
        view.spacing = 2
        return view
    }()

    private let items: [SpaceCreatePanelItem]
    private let preferWidth: CGFloat

    public init(items: [SpaceCreatePanelItem], sourceView: UIView) {
        self.items = items
        preferWidth = sourceView.frame.width
        super.init(nibName: nil, bundle: nil)
        setupPopover(sourceView: sourceView, direction: .up)
        popoverPresentationController?.popoverBackgroundViewClass = WorkspaceCreatePopoverBackgroundView.self
        dismissalStrategy = [.systemSizeClassChanged, .larkSizeClassChanged]
        automaticallyAdjustsPreferredContentSize = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func setupUI() {
        super.setupUI()
        containerView.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.edges.equalTo(containerView.safeAreaLayoutGuide).inset(4)
        }
        setupItems()
    }

    private func setupItems() {
        items.forEach { item in
            let itemView = WorkspaceCreateItemView()
            itemView.update(item: item)
            itemView.onClick = { [weak self] itemEnable in
                guard let self else { return }
                let createEvent = SpaceCreatePanelItem.CreateEvent(createController: self, itemEnable: itemEnable)
                item.clickHandler(createEvent)
            }
            stackView.addArrangedSubview(itemView)
            itemView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
            }
        }
    }

    public override func transitionToRegularSize() {
        super.transitionToRegularSize()
        view.superview?.layer.cornerRadius = 8
        containerView.layer.cornerRadius = 0
        let contentHeight = containerView.systemLayoutSizeFitting(CGSize(width: preferWidth,
                                                                         height: UIView.layoutFittingExpandedSize.height)).height
        preferredContentSize = CGSize(width: preferWidth, height: contentHeight)
    }
}

private class WorkspaceCreateItemView: UIControl {
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    // doc1.0 标识tag
    private lazy var versionTag: UDTag = {
        let config = UDTagConfig.TextConfig(font: UIFont.systemFont(ofSize: 10),
                                            cornerRadius: 4,
                                            textColor: UDColor.udtokenTagNeutralTextNormal,
                                            backgroundColor: UDColor.udtokenTagNeutralBgNormal,
                                            height: 13)
        let tag = UDTag(text: BundleI18n.SKResource.CreationMobile_Common_Tag_DocGen1, textConfig: config)
        return tag
    }()

    private var itemEnabled: Bool = true {
        didSet {
            alpha = itemEnabled ? 1 : 0.5
        }
    }

    override var isHighlighted: Bool {
        didSet {
            guard itemEnabled else { return }
            if isHighlighted {
                backgroundColor = UDColor.fillPressed
            } else {
                backgroundColor = .clear
            }
        }
    }

    private var hoverGesture: UIGestureRecognizer?
    private var titleCenterConstraint: Constraint?
    var onClick: ((Bool) -> Void)?

    private let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 6
        clipsToBounds = true
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
            make.top.bottom.equalToSuperview().inset(12)
            make.left.equalToSuperview().inset(12)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(8)
            make.left.equalTo(iconView.snp.right).offset(12).priority(.medium)
            titleCenterConstraint = make.left.equalToSuperview().inset(12).priority(.required).constraint
        }
        titleCenterConstraint?.deactivate()

        addTarget(self, action: #selector(didClick), for: .touchUpInside)

        if #available(iOS 13.0, *) {
            setupHoverInteraction()
        }
    }

    @available(iOS 13.0, *)
    private func setupHoverInteraction() {
        guard SKDisplay.pad else { return }
        let gesture = UIHoverGestureRecognizer()
        gesture.rx.event.subscribe(onNext: { [weak self] gesture in
            guard let self else { return }
            switch gesture.state {
            case .began, .changed:
                if !self.isHighlighted, self.itemEnabled {
                    self.backgroundColor = UDColor.fillHover
                }
            case .ended, .cancelled:
                if !self.isHighlighted {
                    self.backgroundColor = .clear
                }
            default:
                break
            }
        })
        .disposed(by: disposeBag)
        hoverGesture = gesture
        addGestureRecognizer(gesture)
    }

    override func layoutSubviews() {
        if frame.width < 110 {
            titleCenterConstraint?.activate()
            iconView.isHidden = true
        } else {
            titleCenterConstraint?.deactivate()
            iconView.isHidden = false
        }
        super.layoutSubviews()
    }

    func update(item: SpaceCreatePanelItem) {
        iconView.image = item.icon
        titleLabel.text = item.title
        setupVersionTag(item: item)
        
        item.enableState.asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] enabled in
                self?.itemEnabled = enabled
            })
            .disposed(by: disposeBag)
    }

    @objc
    private func didClick() {
        onClick?(itemEnabled)
    }
    
    private func setupVersionTag(item: SpaceCreatePanelItem) {
        guard item.itemType == .doc, LKFeatureGating.createDocXEnable else { return }
        setupVersionTagLayout()
        // 设置字体格式
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        let attributeString = NSMutableAttributedString(string: item.title + " ", attributes: [.paragraphStyle: style, .foregroundColor: UDColor.textTitle])
        // 设置标签image
        versionTag.isHidden = false
        let tag = NSTextAttachment()
        tag.image = versionTag.transformImage()
        tag.bounds = CGRect(x: 0, y: titleLabel.font.descender + 2, width: versionTag.frame.width, height: 13)
        
        let imageAttr = NSMutableAttributedString(attachment: tag)
        versionTag.isHidden = true
        attributeString.append(imageAttr)
        titleLabel.attributedText = attributeString
    }
    
    private func setupVersionTagLayout() {
        insertSubview(versionTag, belowSubview: titleLabel)
        versionTag.snp.makeConstraints { make in
            make.top.left.equalTo(titleLabel)
        }
        layoutIfNeeded()
    }
}

private class WorkspaceCreatePopoverBackgroundView: UIPopoverBackgroundView {
    public override var arrowOffset: CGFloat {
        get { return 0 }
        set { }
    }

    public override var arrowDirection: UIPopoverArrowDirection {
        get { return .up }
        set { }
    }

    public override class func contentViewInsets() -> UIEdgeInsets {
        return .zero
    }

    public override class func arrowHeight() -> CGFloat {
        return 4
    }

    public override class func arrowBase() -> CGFloat {
        return 0
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowOpacity = 0
    }
}
