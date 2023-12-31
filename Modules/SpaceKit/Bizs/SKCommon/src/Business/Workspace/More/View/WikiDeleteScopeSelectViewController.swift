//
//  WikiNodeDletePickViewController.swift
//  SKCommon
//
//  Created by majie.7 on 2022/10/17.
//

import Foundation
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignCheckBox
import UniverseDesignToast

public enum DeleteNodeAction {
    case single
    case all
    case none
}

public final class WikiDeleteScopeSelectItem {
    var selected: Bool = false
    let title: String
    let subTitle: String?
    let scopeType: DeleteNodeAction
    let disableReason: String?
    public init(title: String,
                subTitle: String?,
                selected: Bool,
                scopeType: DeleteNodeAction,
                disableReason: String? = nil) {
        self.title = title
        self.subTitle = subTitle
        self.selected = selected
        self.scopeType = scopeType
        self.disableReason = disableReason
    }
}

public final class WikiDeleteScopItemView: UIView {
    private(set) var item: WikiDeleteScopeSelectItem
    var tap: ((WikiDeleteScopeSelectItem) -> Void)?

    // checkbox 本身不可直接点，而是整个 itemView 直接响应点击
    private(set) var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .single, config: .init(style: .circle)) { (_) in }
        checkBox.isUserInteractionEnabled = false
        return checkBox
    }()

    private var contentStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .fill
        view.spacing = 8
        view.distribution = .fill
        return view
    }()

    private var mainLabel: UILabel = {
        let l = UILabel()
        l.textColor = UDColor.textTitle
        l.font = UIFont.systemFont(ofSize: 16)
        l.numberOfLines = 0
        return l
    }()

    private var subTitleLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.textAlignment = .left
        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 2
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                          NSAttributedString.Key.paragraphStyle: paraph,
                          NSAttributedString.Key.foregroundColor: UDColor.textCaption]
        l.attributedText = NSAttributedString(string: BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_Description,
                                              attributes: attributes)
        return l
    }()

    public init(item: WikiDeleteScopeSelectItem) {
        self.item = item
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(checkBox)
        addSubview(contentStackView)
        contentStackView.addArrangedSubview(mainLabel)
        contentStackView.addArrangedSubview(subTitleLabel)

        let itemEnabled = item.disableReason == nil
        mainLabel.text = item.title
        subTitleLabel.text = item.subTitle
        checkBox.isSelected = item.selected && itemEnabled
        checkBox.isEnabled = itemEnabled

        checkBox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.height.width.equalTo(20)
            make.top.equalToSuperview().inset(16)
        }

        contentStackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(16)
            make.right.equalToSuperview().inset(8)
            make.left.equalTo(checkBox.snp.right).offset(12)
        }

        updateLayout()

        if !itemEnabled {
            mainLabel.textColor = UDColor.textDisabled
        }

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    func showSubTitleLabelLayout() {
        subTitleLabel.isHidden = false
    }

    func hideSubTitleLabelLayout() {
        subTitleLabel.isHidden = true
    }

    public func updateLayout() {
        let itemSelected = item.selected && item.disableReason == nil
        if item.subTitle?.isEmpty == false, itemSelected {
            showSubTitleLabelLayout()
        } else {
            hideSubTitleLabelLayout()
        }
    }

    @objc
    private func didTap() {
        tap?(item)
    }
}

public final class WikiDeleteScopeSelectViewController: SKBlurPanelController {
    
    private lazy var headerView: SKPanelHeaderView = {
        let view = SKPanelHeaderView()
        view.setTitle(BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_ConfirmScope)
        view.setCloseButtonAction(#selector(didClickMask), target: self)
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var descripteLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.textAlignment = .left
        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 2
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                          NSAttributedString.Key.paragraphStyle: paraph,
                          NSAttributedString.Key.foregroundColor: UDColor.textCaption]
        let string = BundleI18n.SKResource.LarkCCM_Workspace_Trash_DeleteIn30D_Popover_Text
        label.attributedText = NSAttributedString(string: string,
                                                  attributes: attributes)
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = UDColor.bgFloat
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 0
        return view
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_Cancel_Button, for: .normal)
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.setTitleColor(UDColor.textDisabled, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.backgroundColor = UDColor.udtokenComponentOutlinedBg
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didCancel), for: .touchUpInside)
        return button
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_Delete_Button, for: .normal)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = UDColor.fillDisabled
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickConfirm), for: .touchUpInside)
        return button
    }()
    
    public var confirmCompletion: ((DeleteNodeAction) -> Void)?
    private var itemViews: [WikiDeleteScopItemView] = []
    private var items: [WikiDeleteScopeSelectItem]
    private var currentSelect: DeleteNodeAction = .none
    
    public init(items: [WikiDeleteScopeSelectItem]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
        dismissalStrategy = [.systemSizeClassChanged]
        transitioningDelegate = panelTransitioningDelegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func setupUI() {
        super.setupUI()
        containerView.addSubview(headerView)
        containerView.addSubview(descripteLabel)
        containerView.addSubview(stackView)
        containerView.addSubview(cancelButton)
        containerView.addSubview(confirmButton)
        
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
        
        descripteLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        items.enumerated().forEach { (offset, sortItem) in
            if offset > 0 {
                let seperatorView = UIView()
                seperatorView.backgroundColor = UDColor.lineDividerDefault
                stackView.addArrangedSubview(seperatorView)
                seperatorView.snp.makeConstraints { make in
                    make.height.equalTo(0.5)
                    make.left.equalToSuperview().offset(16)
                    make.right.equalToSuperview()
                }
            }
            let nextItemView = itemView(for: sortItem, at: offset)
            itemViews.append(nextItemView)
            stackView.addArrangedSubview(nextItemView)
            nextItemView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
            }
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(descripteLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.equalTo(stackView.snp.bottom).offset(16)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(16)
            make.height.equalTo(40)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.left.equalTo(cancelButton.snp.right).offset(12)
            make.width.height.top.bottom.equalTo(cancelButton)
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.layoutIfNeeded()
    }
    
    private func itemView(for item: WikiDeleteScopeSelectItem, at index: Int) -> WikiDeleteScopItemView {
        let itemView = WikiDeleteScopItemView(item: item)
        itemView.tap = { [weak self] currentItem in
            guard let self = self else { return }
            guard !currentItem.selected else { return }
            if let disableReason = currentItem.disableReason {
                UDToast.showTips(with: disableReason, on: self.view.window ?? self.view)
                return
            }
            self.didClick(index: index)
        }
        return itemView
    }
    
    private func didClick(index: Int) {
        items.enumerated().forEach { (offset, item) in
            if offset == index {
                item.selected = true
                currentSelect = item.scopeType
            }
            item.selected = (offset == index)
            let view = itemViews[offset]
            view.checkBox.isSelected = item.selected
            view.updateLayout()
        }

        confirmButton.backgroundColor = UDColor.functionDangerContentDefault

        UIView.performWithoutAnimation {
            adjustsPreferredContentSize()
        }
    }
    
    @objc
    private func didCancel() {
        dismiss(animated: true)
    }
    
    @objc
    private func didClickConfirm() {
        guard currentSelect != .none else {
            return
        }
        self.dismiss(animated: true) { [weak self] in
            guard let self = self, let confirmCompletion = self.confirmCompletion else {
                return
            }
            confirmCompletion(self.currentSelect)
        }
    }
}
