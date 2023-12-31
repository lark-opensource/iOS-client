//
//  ScopeSelectViewController.swift
//  SKCommon
//
//  Created by guoqp on 2021/10/15.
//

import UIKit
import SKUIKit
import SnapKit
import SKResource
import RxSwift
import EENavigator
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignCheckBox
import RxCocoa


public enum PermissionScopeType: Int {
    case container = 1  //容器
    case singlePage  //单页面
}

private enum Layout {
    static var headerHeight: CGFloat { 48 }
    static var itemHeight: CGFloat { 48 }
    static var itemHorizontalSpacing: CGFloat { 13 }
    static var buttonHeight = 48
}

class ScopeSelectItem {
    var selected: Bool = false
    let title: String
    let subTitle: String?
    let scopeType: PermissionScopeType
    init(title: String,
         subTitle: String?,
         selected: Bool, scopeType: PermissionScopeType) {
        self.title = title
        self.subTitle = subTitle
        self.selected = selected
        self.scopeType = scopeType
    }
}

private class ItemView: UIView {
    private(set) var item: ScopeSelectItem
    var tap: ((ScopeSelectItem) -> Void)?

    private(set) var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .single, config: .init(style: .circle)) { (_) in }
        checkBox.isUserInteractionEnabled = false
        return checkBox
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
        l.textColor = UDColor.textPlaceholder
        l.font = UIFont.systemFont(ofSize: 14)
        l.numberOfLines = 0
        return l
    }()

    init(item: ScopeSelectItem) {
        self.item = item
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(checkBox)
        addSubview(mainLabel)
        addSubview(subTitleLabel)

        mainLabel.text = item.title
        subTitleLabel.text = item.subTitle
        checkBox.isSelected = item.selected

        checkBox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.height.width.equalTo(20)
            make.top.equalToSuperview().inset(14)
        }
        updateLayout()

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    func showSubTitleLabelLayout() {
        mainLabel.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().inset(13)
            make.left.equalTo(checkBox.snp.right).offset(12)
            make.right.equalToSuperview().inset(8)
        }

        subTitleLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(mainLabel.snp.bottom).offset(4)
            make.left.equalTo(checkBox.snp.right).offset(12)
            make.right.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(13)
        }
    }

    func hideSubTitleLabelLayout() {
        mainLabel.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(13)
            make.left.equalTo(checkBox.snp.right).offset(12)
            make.right.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
    }

    public func updateLayout() {
        if item.subTitle?.isEmpty == false, item.selected {
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

class ScopeSelectViewController: SKPanelController {

    var confirmCompletion: ((UIViewController, PermissionScopeType) -> Void)?
    var cancelCompletion: ((UIViewController, PermissionScopeType) -> Void)?

    private var dataSource: [ScopeSelectItem]
    private let disposeBag: DisposeBag = DisposeBag()
    private var itemViews: [ItemView] = []

    private var selectedType: PermissionScopeType {
        dataSource.first { item in
            return item.selected
        }?.scopeType ?? .singlePage
    }

    private lazy var headerView: SKPanelHeaderView = {
        let view = SKPanelHeaderView()
        view.setTitle(BundleI18n.SKResource.CreationMobile_Wiki_PermChange_title)
        view.setCloseButtonAction(#selector(didClickMask), target: self)
        view.backgroundColor = .clear
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = UDColor.bgBodyOverlay
        view.layer.cornerRadius = 10
        view.clipsToBounds = true

        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 0

        return view
    }()


    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_List_Cancel, for: .normal)
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.setTitleColor(UDColor.textDisabled, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickReset), for: .touchUpInside)
        return button
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_List_Filter_Done, for: .normal)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = UDColor.primaryContentDefault
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickConfirm), for: .touchUpInside)
        return button
    }()

    public init(items: [ScopeSelectItem] = []) {
        self.dataSource = items
        super.init(nibName: nil, bundle: nil)
        dismissalStrategy = [.systemSizeClassChanged]
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        super.setupUI()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        containerView.addSubview(headerView)
        containerView.addSubview(stackView)
        containerView.addSubview(resetButton)
        containerView.addSubview(confirmButton)

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(Layout.headerHeight)
        }


        stackView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        dataSource.enumerated().forEach { (offset, sortItem) in

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

        resetButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(stackView.snp.bottom).offset(24)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(24)
            make.height.equalTo(Layout.buttonHeight)
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.left.equalTo(resetButton.snp.right).offset(Layout.itemHorizontalSpacing)
            make.width.height.top.bottom.equalTo(resetButton)
        }
    }

    private func itemView(for item: ScopeSelectItem, at index: Int) -> ItemView {
        let itemView = ItemView(item: item)
        itemView.tap = { [weak self] currentItem in
            guard let self = self else { return }
            guard !currentItem.selected else { return }
            self.didClick(index: index)
        }
        return itemView
    }

    private func didClick(index: Int) {
        dataSource.enumerated().forEach { (offset, item) in
            item.selected = (offset == index)
            let view = itemViews[offset]
            view.checkBox.isSelected = item.selected
            view.updateLayout()
        }
    }

    @objc
    private func didClickConfirm() {
        confirmCompletion?(self, selectedType)
        dismiss(animated: true)
    }

    @objc
    private func didClickReset() {
        cancelCompletion?(self, selectedType)
        self.dismiss(animated: true)
    }

    @objc
    public override func didClickMask() {
        super.didClickMask()
        cancelCompletion?(self, selectedType)
    }
}

class IpadScopeSelectViewController: BaseViewController {

    var confirmCompletion: ((UIViewController, PermissionScopeType) -> Void)?
    var cancelCompletion: ((UIViewController, PermissionScopeType) -> Void)?

    private var dataSource: [ScopeSelectItem]
    private let disposeBag: DisposeBag = DisposeBag()
    private var itemViews: [ItemView] = []

    private var selectedType: PermissionScopeType {
        dataSource.first { item in
            return item.selected
        }?.scopeType ?? .singlePage
    }

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = UDColor.bgBodyOverlay
        view.layer.cornerRadius = 10
        view.clipsToBounds = true

        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 0

        return view
    }()


    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_List_Cancel, for: .normal)
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.setTitleColor(UDColor.textDisabled, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickReset), for: .touchUpInside)
        return button
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_List_Filter_Done, for: .normal)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = UDColor.primaryContentDefault
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickConfirm), for: .touchUpInside)
        return button
    }()

    public init(items: [ScopeSelectItem] = []) {
        self.dataSource = items
        super.init(nibName: nil, bundle: nil)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        dismiss(animated: false, completion: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupDefaultValue()
        setupView()
    }

    func setupDefaultValue() {
        view.backgroundColor = UDColor.bgBody
        navigationBar.title = BundleI18n.SKResource.CreationMobile_Wiki_PermChange_title
        let image = UDIcon.closeSmallOutlined
        let item = SKBarButtonItem(image: image,
                                   style: .plain,
                                   target: self,
                                   action: #selector(backBarButtonItemAction))
        item.id = .back
        navigationBar.leadingBarButtonItem = item
    }
    func setupView() {
        view.addSubview(stackView)
        view.addSubview(resetButton)
        view.addSubview(confirmButton)

        stackView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        dataSource.enumerated().forEach { (offset, sortItem) in

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

        resetButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(24)
            make.height.equalTo(Layout.buttonHeight)
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.left.equalTo(resetButton.snp.right).offset(Layout.itemHorizontalSpacing)
            make.width.height.top.bottom.equalTo(resetButton)
        }
    }

    override public var canShowBackItem: Bool {
        return false
    }

    override public func backBarButtonItemAction() {
        self.dismiss(animated: true, completion: nil)
    }


    private func itemView(for item: ScopeSelectItem, at index: Int) -> ItemView {
        let itemView = ItemView(item: item)
        itemView.tap = { [weak self] currentItem in
            guard let self = self else { return }
            guard !currentItem.selected else { return }
            self.didClick(index: index)
        }
        return itemView
    }

    private func didClick(index: Int) {
        dataSource.enumerated().forEach { (offset, item) in
            item.selected = (offset == index)
            let view = itemViews[offset]
            view.checkBox.isSelected = item.selected
            view.updateLayout()
        }
    }

    @objc
    private func didClickConfirm() {
        confirmCompletion?(self, selectedType)
        dismiss(animated: true)
    }

    @objc
    private func didClickReset() {
        cancelCompletion?(self, selectedType)
        self.dismiss(animated: true)
    }
}
