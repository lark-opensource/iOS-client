//
//  FilterTabViewController.swift
//  Todo
//
//  Created by baiyantao on 2022/8/19.
//

import Foundation
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignTabs
import UniverseDesignColor
import UniverseDesignShadow
import EENavigator
import RxSwift
import RxCocoa
import LarkContainer

final class FilterTabViewController: V3HomeModuleController, UIPopoverPresentationControllerDelegate {

    // dependencies
    private let viewModel: FilterTabViewModel
    private let disposeBag = DisposeBag()

    /// views
    ///  |- containerStackView --|
    ///     |- lineContainerView --|
    ///         |- activateDrawerBtn - switchTabsView/seletedTabView - buttonsStackView -|
    ///             buttonsStackView  -> |- expandFilterBtn - showMoreBtn -|
    ///     |- selectorView -------|
    ///     |- archivedNoticeView -|

    private lazy var containerStackView = initContainerStackView()

    private lazy var lineContainerView = UIView()
    private lazy var activateDrawerBtn = initActivateDrawerBtn()
    private lazy var switchTabsView = initSwitchTabsView()
    private lazy var seletedTabView = FilterTabSelectedTabView()

    private lazy var buttonsStackView = initButtonsStackView()
    private lazy var expandFilterBtn = initExpandFilterBtn()
    private lazy var showMoreBtn = initShowMoreBtn()

    private lazy var selectorView = FilterTabContaienrView()
    private lazy var archivedNoticeView = FilterTabArchivedNoticeView()

    required init(resolver: UserResolver, context: V3HomeModuleContext) {
        self.viewModel = FilterTabViewModel(resolver: resolver, context: context)
        super.init(resolver: resolver, context: context)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewData()
        bindViewAction()
    }

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgBody

        view.addSubview(containerStackView)
        containerStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(0)
        }
        setupLineContainerSubViews()
    }

    private func layoutContainerStackView(with items: Set<FilterTab.Item>) {
        self.containerStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if items.contains(.lineContainer) {
            containerStackView.addArrangedSubview(lineContainerView)
            lineContainerView.snp.remakeConstraints {
                $0.width.equalToSuperview()
                $0.height.equalTo(FilterTab.Item.lineContainer.height())
            }
        }
        if items.contains(.selector) {
            containerStackView.addArrangedSubview(selectorView)
            selectorView.snp.remakeConstraints {
                $0.width.equalToSuperview()
                $0.height.equalTo(FilterTab.Item.selector.height())
            }
        }
        if items.contains(.archivedNotice) {
            containerStackView.addArrangedSubview(archivedNoticeView)
            archivedNoticeView.snp.remakeConstraints {
                $0.width.equalToSuperview()
                $0.height.equalTo(FilterTab.Item.archivedNotice.height())
            }
        }
    }

    private func setupLineContainerSubViews() {
        lineContainerView.addSubview(activateDrawerBtn)
        activateDrawerBtn.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
            $0.width.height.equalTo(32)
        }

        lineContainerView.addSubview(buttonsStackView)
        buttonsStackView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().offset(-16)
        }

        buttonsStackView.addArrangedSubview(expandFilterBtn)
        expandFilterBtn.snp.makeConstraints { $0.width.height.equalTo(28) }
        expandFilterBtn.isHiddenInStackView = true

        buttonsStackView.addArrangedSubview(showMoreBtn)
        showMoreBtn.snp.makeConstraints { $0.width.height.equalTo(28) }
        showMoreBtn.isHiddenInStackView = true

        lineContainerView.addSubview(switchTabsView)
        switchTabsView.alpha = 1
        switchTabsView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(activateDrawerBtn.snp.right).offset(10)
            $0.right.lessThanOrEqualTo(buttonsStackView.snp.left).offset(-16)
            $0.height.equalTo(32)
        }

        lineContainerView.addSubview(seletedTabView)
        seletedTabView.alpha = 0
        seletedTabView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(activateDrawerBtn.snp.right).offset(10)
            $0.right.lessThanOrEqualTo(buttonsStackView.snp.left).offset(-16)
            $0.height.equalTo(32)
        }
    }

    private func bindViewData() {
        viewModel.rxVisableItems
            .distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] items in
                guard let self = self else { return }
                self.layoutContainerStackView(with: items)

                let hasSelector = items.contains(.selector)
                self.expandFilterBtn.isSelected = hasSelector
                self.expandFilterBtn.backgroundColor = hasSelector ? UIColor.ud.primaryFillSolid01 : .clear

                let height = items.reduce(0, { $0 + $1.height() })
                self.containerStackView.snp.updateConstraints {
                    $0.height.equalTo(height)
                }
            })
            .disposed(by: disposeBag)
        viewModel.rxCurrentContainer.skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] container in
                guard let self = self else { return }
                self.updateButtons(isHiddenMoreBtn: !container.isTaskList)
                self.archivedNoticeView.canEdit = container.canEdit
                let key = ContainerKey(rawValue: container.key)
                switch key {
                case .owned, .followed:
                    let index = key == .owned ? 0 : 1
                    self.updateTabView(switchTabIndex: index)
                default:
                    let text: String
                    if let key = key, let title = FilterTab.containerKey2Title(key) {
                        text = title
                    } else {
                        text = container.name
                    }
                    self.updateTabView(selectedTabTitle: text)
                }
            })
            .disposed(by: disposeBag)
        viewModel.rxCustomSideBar
            .distinctUntilChanged { $0 == $1 }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] key in
                guard let self = self, key.isValid, let title = key.title else { return }
                let hiddenBtn = !key.isTaskLists
                self.updateButtons(isHiddenExpandFilterBtn: hiddenBtn, isHiddenMoreBtn: hiddenBtn)
                self.updateTabView(selectedTabTitle: title)
            })
            .disposed(by: disposeBag)
        viewModel.rxSelectorData
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] data in
                self?.selectorView.viewData = data
            })
            .disposed(by: disposeBag)
    }

    private func updateTabView(switchTabIndex: Int? = nil, selectedTabTitle: String? = nil) {
        var switchTabAlpha = 0.0, selectedTabAlpha = 0.0
        if let switchTabIndex = switchTabIndex {
            switchTabAlpha = 1.0
            if switchTabsView.selectedIndex != switchTabIndex {
                switchTabsView.selectItemAt(index: switchTabIndex)
            }
        }
        if let selectedTabTitle = selectedTabTitle {
            selectedTabAlpha = 1.0
            seletedTabView.title = selectedTabTitle
        }
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.switchTabsView.alpha = switchTabAlpha
            self?.seletedTabView.alpha = selectedTabAlpha
        }
    }

    private func updateButtons(isHiddenExpandFilterBtn: Bool = false,   isHiddenMoreBtn: Bool = true) {
        expandFilterBtn.isHiddenInStackView = isHiddenExpandFilterBtn
        showMoreBtn.isHiddenInStackView = isHiddenMoreBtn
    }

    private func bindViewAction() {
        seletedTabView.exitHandler = { [weak self] in
            guard let self = self else { return }
            V3Home.Track.clickListCancelContainer(with: self.viewModel.rxCurrentContainer.value)
            self.viewModel.doSelectContainer(key: .owned)
        }
        selectorView.containerSelector.itemBtnHandler = { [weak self] (type, sourceView) in
            guard let self = self else { return }
            switch type {
            case .status:
                let input = self.viewModel.doExpandStatusPanel()
                self.jumpToFilterPanel(input: input, sourceView: sourceView)
            case .group:
                let input = self.viewModel.doExpandGroupPanel()
                self.jumpToFilterPanel(input: input, sourceView: sourceView)
            case .sorting:
                let input = self.viewModel.doExpandSortingPanel()
                self.jumpToFilterPanel(input: input, sourceView: sourceView)
            default: break
            }

        }
        selectorView.taskListsSelector.tabHandler = { [weak self] tab in
            self?.viewModel.doTaskListsSelectedTab(tab)
        }
        archivedNoticeView.unarchiveHandler = { [weak self] in
            guard let self = self else { return }
            let container = self.viewModel.rxCurrentContainer.value
            V3Home.Track.clickArchiveListInView(with: container)
            self.context.bus.post(.unarchivedTasklist(container: container))
        }
    }

    private func initContainerStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 0
        return stackView
    }

    private func initActivateDrawerBtn() -> UIButton {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.ud.N200
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        let image = UDIcon.slideBoldOutlined
            .ud.resized(to: CGSize(width: 18, height: 18))
            .ud.withTintColor(UIColor.ud.iconN1)
        button.setImage(image, for: .normal)
        button.setImage(image, for: .selected)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        button.addTarget(self, action: #selector(onDrawerBtnClick), for: .touchUpInside)
        return button
    }

    private func initSwitchTabsView() -> UDSegmentedControl {
        var config = UDSegmentedControl.Configuration()
        config.titleLineBreakMode = .byTruncatingTail
        config.preferredHeight = 32
        config.titleSelectedColor = FilterTab.imFeedTextPriSelected
        config.backgroundColor = UIColor.ud.N200
        config.indicatorColor = FilterTab.imFeedBgBody
        config.indicatorShadowColor = UDShadowColorTheme.s3DownColor
        config.itemDistributionStyle = .automatic
        config.itemMaxWidth = 130
        let view = UDSegmentedControl(configuration: config)
        view.delegate = self
        if let ownedTitle = FilterTab.containerKey2Title(.owned),
           let followedTitle = FilterTab.containerKey2Title(.followed) {
            view.titles = [ownedTitle, followedTitle]
        }
        return view
    }

    private func initButtonsStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        return stackView
    }

    private func initExpandFilterBtn() -> UIButton {
        let button = UIButton()
        let normalIcon = UDIcon.adminOutlined
            .ud.withTintColor(UIColor.ud.iconN2)
            .ud.resized(to: CGSize(width: 20, height: 20))
        button.setImage(normalIcon, for: .normal)
        button.setImage(normalIcon, for: [.normal, .highlighted])
        let selectedIcon = UDIcon.adminOutlined
            .ud.withTintColor(UIColor.ud.primaryContentDefault)
            .ud.resized(to: CGSize(width: 20, height: 20))
        button.setImage(selectedIcon, for: .selected)
        button.setImage(selectedIcon, for: [.selected, .highlighted])

        button.addTarget(self, action: #selector(onExpandBtnClick), for: .touchUpInside)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -6, left: -6, bottom: -6, right: -6)
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        return button
    }

    private func initShowMoreBtn() -> UIButton {
        let button = UIButton()
        let icon = UDIcon.moreOutlined
            .ud.withTintColor(UIColor.ud.iconN2)
            .ud.resized(to: CGSize(width: 20, height: 20))
        button.setImage(icon, for: .normal)
        button.addTarget(self, action: #selector(onShowMoreBtnClick), for: .touchUpInside)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -6, left: -6, bottom: -6, right: -6)
        return button
    }

    private func jumpToFilterPanel(input: FilterPanelViewModel.Input, sourceView: UIView) {
        guard let superView = sourceView.superview, let window = sourceView.window else {
            assertionFailure()
            return
        }
        let rectInWindow = superView.convert(sourceView.frame, to: window)
        let vm = FilterPanelViewModel(input: input)
        let vc = FilterPanelViewController(viewModel: vm, topOffset: rectInWindow.maxY)
        if Display.pad {
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.sourceView = sourceView
            let sourceRect = CGRect(x: sourceView.frame.width / 2, y: sourceView.frame.height, width: 0, height: 0)
            vc.popoverPresentationController?.sourceRect = sourceRect
            vc.popoverPresentationController?.delegate = self
            vc.popoverPresentationController?.permittedArrowDirections = .up
        } else {
            vc.modalPresentationStyle = .overFullScreen
        }
        vc.dismissHandler = { [weak self] field in
            if let field = field {
                self?.viewModel.doUpdateField(field: field)
            } else {
                self?.viewModel.doRestoreSeletedTab()
            }
        }
        present(vc, animated: true)
    }

    @objc
    private func onDrawerBtnClick() {
        V3Home.Track.clickListContainerMenu(with: viewModel.rxCurrentContainer.value)
        context.bus.post(.showFilterDrawer(sourceView: activateDrawerBtn))
    }

    @objc
    private func onExpandBtnClick() {
        viewModel.doToggleExpandFilterBtn()
    }

    @objc
    private func onShowMoreBtnClick() {
        if viewModel.rxCustomSideBar.value.isTaskLists {
            context.bus.post(.organizableTasklistMoreAction(sourceView: showMoreBtn))
        } else {
            context.bus.post(.tasklistMoreAction(
                data: .init(container: viewModel.rxCurrentContainer.value),
                sourceView: showMoreBtn,
                sourceVC: nil,
                scene: .listDetail
            ))
        }
    }

    // MARK: - UIPopoverPresentationControllerDelegate

    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        viewModel.doRestoreSeletedTab()
    }
}

// MARK: - UDTabsViewDelegate

extension FilterTabViewController: UniverseDesignTabs.UDTabsViewDelegate {
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        viewModel.doSelectContainer(key: index == 0 ? ContainerKey.owned : ContainerKey.followed)
    }

    func tabsView(_ tabsView: UDTabsView, didClickSelectedItemAt index: Int) { }
}

// 6 年了都不修。。 https://stackoverflow.com/questions/40001416/swift-disappearing-views-from-a-stackview
fileprivate extension UIView {
    var isHiddenInStackView: Bool {
        get {
            return isHidden
        }
        set {
            if isHidden != newValue {
                isHidden = newValue
            }
        }
    }
}
