//
//  SpaceCommonListPanel.swift
//  SKCommon
//
//  Created by majie.7 on 2023/9/13.
//

import Foundation
import SKUIKit
import UniverseDesignColor
import SKResource
import RxSwift


public class SpaceCommonListPanel: SKBlurPanelController {
    private lazy var headerView: SKPanelHeaderView = {
        let view = SKPanelHeaderView()
        view.setCloseButtonAction(#selector(didClickMask), target: self)
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.backgroundColor = UDColor.bgFloat
        view.spacing = 0
        view.alignment = .center
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton()
        let fontSize: CGFloat = 16
        button.setTitle(BundleI18n.SKResource.LarkCCM_NewCM_Default_Button, withFontSize: fontSize, fontWeight: .regular, color: UDColor.functionInfoContentDefault, forState: .normal)
        button.addTarget(self, action: #selector(clickResetButton), for: .touchUpInside)
        return button
    }()
    
    private var canRest: Bool {
        return config.resetHandler != nil
    }
    
    private var config: SpaceCommonListConfig
    let disposeBag = DisposeBag()
    
    public init(title: String, config: SpaceCommonListConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
        headerView.setTitle(title)
        dismissalStrategy = [.systemSizeClassChanged]
        transitioningDelegate = panelTransitioningDelegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public override func setupUI() {
        super.setupUI()
        containerView.addSubview(headerView)
        containerView.addSubview(stackView)
        
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
        
        if canRest {
            headerView.addSubview(resetButton)
            resetButton.snp.makeConstraints { make in
                make.centerY.equalTo(headerView.titleCenterY)
                make.trailing.equalToSuperview().inset(16)
            }
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(40)
        }
        
        update()
    }
    
    private func update() {
        for (index, item) in config.items.enumerated() {
            let itemView = SpaceCommonListItemView()
            itemView.update(leadingItem: item.leadingItem, trailingItem: item.trailingItem)
            
            if index == config.items.count - 1 {
                itemView.indicatorLine.isHidden = true
            }
            
            stackView.addArrangedSubview(itemView)
            itemView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.left.right.equalToSuperview()
                make.height.equalTo(54)
            }
            itemView.setupLeadingSpacing(spacing: item.leadingItemSpacing)
            itemView.setupTrailingSpacing(spacing: item.trailingItemSpacing)
            itemView.clickHandler = { [weak self] in
                self?.dismiss(animated: true) {
                    item.clickHandler?()
                }
            }
            item.enableObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak itemView] enable in
                    itemView?.updateViewState(enable: enable)
                })
                .disposed(by: disposeBag)

        }
    }
    @objc
    private func clickResetButton() {
        config.resetHandler?()
        dismiss(animated: true)
    }
}


class SpaceCommonListItemView: UIView {
    
    class ItemViewControl: UIControl {
        var highlightHandler: ((Bool) -> Void)?
        
        override var isHighlighted: Bool {
            didSet {
                highlightHandler?(isHighlighted)
            }
        }
        
        init(highlightHandler: ((Bool) -> Void)?) {
            self.highlightHandler = highlightHandler
            super.init(frame: .zero)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    lazy var leadingItemView: SpaceCommonListItemSubView = {
        let view = SpaceCommonListItemSubView(titleCompressionResistancePriority: .required + 10)
        return view
    }()
    
    lazy var trailingItemView: SpaceCommonListItemSubView = {
        let view = SpaceCommonListItemSubView(titleCompressionResistancePriority: .required)
        return view
    }()
    
    lazy var centerSpacingView: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }()
    
    lazy var indicatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .center
        view.spacing = 12
        return view
    }()
    
    lazy var clickControl: ItemViewControl = {
        let view = ItemViewControl { [weak self] isHighlighted in
            if isHighlighted {
                self?.backgroundColor = UDColor.fillPressed
            } else {
                self?.backgroundColor = UDColor.bgFloat
            }
        }
        return view
    }()
    
    var clickHandler: (() -> Void)?
    
    let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
        addTapHandler()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(stackView)
        addSubview(indicatorLine)
        addSubview(clickControl)
        stackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
        }
        
        stackView.addArrangedSubview(leadingItemView)
        leadingItemView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        stackView.addArrangedSubview(centerSpacingView)
        
        stackView.addArrangedSubview(trailingItemView)
        trailingItemView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        indicatorLine.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        clickControl.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        leadingItemView.setContentCompressionResistancePriority(.required, for: .horizontal)
        trailingItemView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
    
    private func addTapHandler() {
        clickControl.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] _ in
                self?.clickHandler?()
            })
            .disposed(by: disposeBag)
    }
    
    @objc
    private func click() {
        clickHandler?()
    }
    
    func update(leadingItem: SpaceCommonListItemModel?, trailingItem: SpaceCommonListItemModel?) {
        leadingItemView.update(item: leadingItem)
        trailingItemView.update(item: trailingItem)
    }
    
    func setupLeadingSpacing(spacing: CGFloat?) {
        leadingItemView.setupSpaceDistance(spacing: spacing)
    }
    
    func setupTrailingSpacing(spacing: CGFloat?) {
        trailingItemView.setupSpaceDistance(spacing: spacing)
    }

    func updateViewState(enable: Bool) {
        stackView.alpha = enable ? 1.0 : 0.4
        clickControl.isUserInteractionEnabled = enable
    }
}

class SpaceCommonListItemSubView: UIView {
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 2
        view.alignment = .center
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 2
        label.isHidden = true
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    lazy var leftImageView: UIImageView = {
        let view = UIImageView()
        view.isHidden = true
        return view
    }()
    
    lazy var rightImageView: UIImageView = {
        let view = UIImageView()
        view.isHidden = true
        return view
    }()
    
    convenience init(titleCompressionResistancePriority: UILayoutPriority) {
        self.init(frame: .zero)
        titleLabel.setContentCompressionResistancePriority(titleCompressionResistancePriority, for: .horizontal)
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stackView.addArrangedSubview(leftImageView)
        leftImageView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        stackView.addArrangedSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        
        stackView.addArrangedSubview(rightImageView)
        rightImageView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        leftImageView.setContentCompressionResistancePriority(.required + 100, for: .horizontal)
        rightImageView.setContentCompressionResistancePriority(.required + 100, for: .horizontal)
    }
    
    func setupSpaceDistance(spacing: CGFloat?) {
        guard let spacing else { return }
        stackView.spacing = spacing
    }
    
    func update(item: SpaceCommonListItemModel?) {
        guard let item else { return }
        
        if let leftIconItem = item.leftIconItem {
            leftImageView.image = leftIconItem.image
            if let color = leftIconItem.color {
                leftImageView.image = leftIconItem.image.ud.withTintColor(color)
            }
            if let size = leftIconItem.size {
                leftImageView.snp.remakeConstraints { make in
                    make.width.equalTo(size.width)
                    make.height.equalTo(size.height)
                    make.centerY.equalToSuperview()
                }
            }
            leftImageView.isHidden = false
        }
        
        if let rightIconItem = item.rightIconItem {
            rightImageView.image = rightIconItem.image
            if let color = rightIconItem.color {
                rightImageView.image = rightIconItem.image.ud.withTintColor(color)
            }
            if let size = rightIconItem.size {
                rightImageView.snp.remakeConstraints { make in
                    make.width.equalTo(size.width)
                    make.height.equalTo(size.height)
                    make.centerY.equalToSuperview()
                }
            }
            rightImageView.isHidden = false
        }
        
        if let titleItem = item.titleItem {
            titleLabel.text = titleItem.title
            if let color = titleItem.color {
                titleLabel.textColor = color
            }
            if let font = titleItem.font {
                titleLabel.font = font
            }
            titleLabel.isHidden = false
        }
    }
    
}
