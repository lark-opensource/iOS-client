//
//  BTTableLayoutSettingViewControllerV2.swift
//  SKBitable
//
//  Created by X-MAN on 2023/8/28.
//

import UIKit
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignTabs

protocol BTTableLayoutSettingViewControllerDelegateV2: AnyObject {
    func settingsDidChange(_ vc: BTTableLayoutSettingViewControllerV2)
    func openCoverChooseVCV2(data: [BTFieldCommonData])
    func settingControllerWillShow(_ vc: BTTableLayoutSettingViewControllerV2)
}

final class BTTableLayoutSettingViewControllerV2: UIViewController {
    
    // MARK: - public
    
    private(set) var vm: BTTableLayoutSettingViewModel
    var dismissBlock: (() -> Void)?
    
    // 告知父容器需要变高
    var changeContainerHeightBlock: ((BTDraggableViewController.ViewHeightMode, Bool) -> Void)?
    
    weak var delegate: BTTableLayoutSettingViewControllerDelegateV2?
    
    func updateSettings(_ settings: BTTableLayoutSettings, fields: [BTFieldOperatorModel]) {
        vm = BTTableLayoutSettingViewModel(settings: settings, fields: fields)
        updateUI()
    }
    
    // MARK: - life cycle
    
    init(settings: BTTableLayoutSettings,
         fields: [BTFieldOperatorModel],
         delegate: BTTableLayoutSettingViewControllerDelegateV2? = nil) {
        self.vm = BTTableLayoutSettingViewModel(settings: settings, fields: fields)
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subviewsInit()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dismissBlock?()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    
    // MARK: - private
    
    private var isBarDragging = false
    
    private var isScollViewDragging = false
    
    private let scrollView = UIScrollView()
    
    private let stackView = UIStackView().construct { it in
        it.axis = .vertical
        it.spacing = 16.0
    }
    
    private let typeSTView = BTTableLayoutTypeSettingView()
    
    private let cardSTView = BTCardLayoutSettingView()
    
    /// 当前选中的视图模式对应的设置视图
    private var currentTypeSTView: UIView?
    
    private func updateUI() {
        updateSettingsList()
        updateSettingsListDetail()
    }
    
    /// 更新选中态及对应样式下的配置列表
    private func updateSettingsList() {
        // 更新选中样式
        typeSTView.currentType = vm.viewType
        // 更新选中样式对应的配置列表
        var actSTView: UIView?
        switch vm.viewType {
        case .classic:
            actSTView = nil
        case .card:
            actSTView = cardSTView
        }
        if let preSTView = currentTypeSTView {
            stackView.removeArrangedSubview(preSTView)
            preSTView.removeFromSuperview()
            currentTypeSTView = nil
        }
        if let addSTView = actSTView {
            stackView.addArrangedSubview(addSTView)
            currentTypeSTView = addSTView
        }
    }
    
    /// 更新对应选中项的具体配置数据
    private func updateSettingsListDetail() {
        switch typeSTView.currentType {
        case .classic:
            break
        case .card:
            cardSTView.update(vm.cardSettings)
        }
    }
    
    private func notifySettingsChange() {
        delegate?.settingsDidChange(self)
        updateUI()
    }
    
    private func subviewsInit() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        stackView.addArrangedSubview(typeSTView)
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.equalToSuperview().inset(16)
        }
        
        scrollView.delegate = self
        
        typeSTView.delegate = self
        
        cardSTView.styleSTView.delegate = self
        cardSTView.titleSTView.delegate = self
        cardSTView.displayFieldSTView.delegate = self
        cardSTView.moreFieldSTView.delegate = self
        
        updateUI()
    }
}

// MARK: - view delegate

extension BTTableLayoutSettingViewControllerV2: BTTableLayoutTypeSettingViewDelegate {
    func onViewTypeChanged(_ sender: BTTableLayoutTypeSettingView, viewType: BTTableLayoutSettings.ViewType) {
        DocsLogger.info("on view type changed: \(viewType)", component: BTTableLayoutLogTag)
        vm.updateViewType(viewType)
        notifySettingsChange()
    }
}

extension BTTableLayoutSettingViewControllerV2: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isBarDragging {
            return
        }
        if scrollView.panGestureRecognizer.translation(in: scrollView.superview).y > 0 {
            // 下拉降低面板
            if isScollViewDragging, scrollView.contentOffset.y <= -20 {
                changeContainerHeightBlock?(.initHeight, true)
            }
        } else {
            // 上滑展开面板
            changeContainerHeightBlock?(.maxHeight, true)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScollViewDragging = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isScollViewDragging = false
    }
}

// MARK: - card mode settings

extension BTTableLayoutSettingViewControllerV2: BTCardLayoutColumnViewDelegate {
    var hasCover: Bool {
        return vm.cardSettings.titleAndCover?.coverField != nil
    }
    
    func onColumnTypeChanged(_ view: BTCardLayoutColumnView, columnType: BTTableLayoutSettings.ColumnType) {
        DocsLogger.info("on column type changed: \(columnType)", component: BTTableLayoutLogTag)
        vm.cardSettings.update(columnType: columnType)
        notifySettingsChange()
    }
}

extension BTTableLayoutSettingViewControllerV2: BTCardLayoutTitleViewDelegate {
    enum FieldChooseAction: String {
        case title
        case subTitle
        case cover
    }
    
    enum FieldGroupID: String {
        case deselect
        case field
    }
    
    func onTitleChangeRequest(_ view: BTCardLayoutTitleView) {
        chooseField(action: .title)
    }
    
    func onSubTitleChangeRequest(_ view: BTCardLayoutTitleView) {
        chooseField(action: .subTitle)
    }
    
    func onCoverChangeRequest(_ view: BTCardLayoutTitleView) {
        chooseField(action: .cover)
    }
    
    private func chooseField(action: FieldChooseAction) {
        DocsLogger.info("on chooseField, action: \(action)", component: BTTableLayoutLogTag)
        var data = vm.allFields.filter({ !$0.isHidden && !$0.isDeniedField }).map { item in
            BTFieldCommonData(
                id: item.id,
                name: item.name,
                groupId: FieldGroupID.field.rawValue,
                icon: item.compositeType.icon(color: UDColor.iconN2),
                showLighting: item.isSync,
                selectedType: .textHighlight
            )
        }
        let currentIndex: IndexPath?
        let currentField: BTFieldOperatorModel?
        switch action {
        case .title:
            currentField = self.vm.cardSettings.titleAndCover?.titleField
            if let index = data.firstIndex(where: { $0.id == currentField?.id }) {
                currentIndex = IndexPath(row: index, section: 0)
            } else {
                // 目前 title 字段一定有
                spaceAssertionFailure("title field not found!")
                currentIndex = nil
            }
        case .subTitle:
            // 副标题设计稿单独在顶部搞一个 section cell，点击取消选择
            let deselectItem = BTFieldCommonData(
                id: "",
                name: BundleI18n.SKResource.Bitable_Mobile_DoNotDisplaySubheading,
                groupId: FieldGroupID.deselect.rawValue,
                selectedType: .textHighlight
            )
            data.insert(deselectItem, at: 0)
            currentField = self.vm.cardSettings.titleAndCover?.subTitleField
            if let index = data.firstIndex(where: { $0.id == currentField?.id }) {
                currentIndex = IndexPath(row: index - 1, section: 1)
            } else {
                currentIndex = IndexPath(row: 0, section: 0)
            }
        case .cover:
            // 附件字段
            let noCoverItem = BTFieldCommonData(
                id: "",
                name: BundleI18n.SKResource.Bitable_Mobile_Configuration_Cover_DontShow_Option,
                groupId: FieldGroupID.deselect.rawValue,
                selectedType: .textHighlight
            )
            
            // 隐藏的字段也要显示
            data = vm.allFields.filter({ !$0.isDeniedField && $0.compositeType.type == .attachment }).map { item in
                BTFieldCommonData(
                    id: item.id,
                    name: item.name,
                    groupId: FieldGroupID.field.rawValue,
                    icon: item.compositeType.icon(color: UDColor.iconN2),
                    showLighting: item.isSync,
                    selectedType: .textHighlight
                )
            }
            
            delegate?.openCoverChooseVCV2(data: data)
            if data.isEmpty {
                // 无附件字段，弹toast提示
                UDToast.showTips(with: BundleI18n.SKResource.Bitable_Mobile_Configuration_Cover_AddBeforeSetting_Desc, on: self.view)
                return
            }
            
            data.insert(noCoverItem, at: 0)
            currentField = self.vm.cardSettings.titleAndCover?.coverField
            if let index = data.firstIndex(where: { $0.id == currentField?.id }) {
                currentIndex = IndexPath(row: index - 1, section: 1)
            } else {
                currentIndex = IndexPath(row: 0, section: 0)
            }
        }
        let vc = BTFieldCommonDataListController(
            data: data,
            title: BundleI18n.SKResource.Bitable_Relation_SelectField_Mobile,
            action: action.rawValue,
            shouldShowDragBar: true,
            shouldShowDoneButton: false,
            shouldShowGroupTitleById: false,
            relatedView: nil,
            disableItemClickBlock: nil,
            lastSelectedIndexPath: currentIndex
        )
        vc.delegate = self
        BTNavigator.presentDraggableVCEmbedInNav(vc, from: self)
    }
}

extension BTTableLayoutSettingViewControllerV2: BTFieldCommonDataListDelegate {
    func didSelectedItem(_ item: BTFieldCommonData,
                         relatedItemId: String,
                         relatedView: UIView?,
                         action: String,
                         viewController: UIViewController,
                         sourceView: UIView?) {
        DocsLogger.info("on title section change: \(item.name), action: \(action)", component: BTTableLayoutLogTag)
        guard let act = FieldChooseAction(rawValue: action) else {
            spaceAssertionFailure("unknown action")
            return
        }
        viewController.dismiss(animated: true)
        switch act {
        case .title:
            if let chooseField = vm.allFields.first(where: { $0.id == item.id }) {
                vm.cardSettings.update(titleField: chooseField)
            } else {
                spaceAssertionFailure("choose field not found!")
            }
        case .subTitle:
            if item.groupId == FieldGroupID.deselect.rawValue {
                vm.cardSettings.update(subTitleField: nil)
            } else if item.groupId == FieldGroupID.field.rawValue {
                if let chooseField = vm.allFields.first(where: { $0.id == item.id }) {
                    vm.cardSettings.update(subTitleField: chooseField)
                } else {
                    spaceAssertionFailure("choose field not found!")
                }
            } else {
                spaceAssertionFailure("unknown group id!")
            }
        case .cover:
            if item.groupId == FieldGroupID.deselect.rawValue {
                vm.cardSettings.update(coverField: nil)
            } else if item.groupId == FieldGroupID.field.rawValue {
                if let chooseField = vm.allFields.first(where: { $0.id == item.id }) {
                    vm.cardSettings.update(coverField: chooseField)
                } else {
                    spaceAssertionFailure("choose field not found!")
                }
            } else {
                spaceAssertionFailure("unknown group id!")
            }
        }
        notifySettingsChange()
    }
}

extension BTTableLayoutSettingViewControllerV2: BTCardLayoutDisplayFieldViewDelegate {
    func onSortField(_ view: BTCardLayoutDisplayFieldView, fields: [BTFieldOperatorModel]) {
        DocsLogger.info("on sort field", component: BTTableLayoutLogTag)
        vm.cardSettings.update(sortVisiable: fields)
        notifySettingsChange()
    }
    
    func onDeleteField(_ view: BTCardLayoutDisplayFieldView, field: BTFieldOperatorModel) {
        DocsLogger.info("on delete field: \(field.name)", component: BTTableLayoutLogTag)
        vm.cardSettings.update(deleteFromVisiable: field)
        notifySettingsChange()
    }
}

extension BTTableLayoutSettingViewControllerV2: BTCardLayoutMoreFieldViewDelegate {
    func onAddField(_ view: BTCardLayoutMoreFieldView, field: BTFieldOperatorModel) {
        DocsLogger.info("on add field: \(field.name)", component: BTTableLayoutLogTag)
        vm.cardSettings.update(addToVisiable: field)
        notifySettingsChange()
    }
}

extension BTTableLayoutSettingViewControllerV2: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        self.view
    }
    /// 可选实现，列表将要显示的时候调用
    func listWillAppear() {
        delegate?.settingControllerWillShow(self)
    }
}
