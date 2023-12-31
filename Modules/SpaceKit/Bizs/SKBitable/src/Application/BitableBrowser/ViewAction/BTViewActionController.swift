//
//  BTViewActionController.swift
//  SKBitable
//
//  Created by X-MAN on 2023/8/28.
//

import Foundation
import UniverseDesignTabs
import UniverseDesignColor
import SKResource
import SKFoundation

protocol BTViewActionControllerDelegate: AnyObject {
    func sortView()
    func filterView()
    func layoutView()
}

final class BTViewActionController: BTDraggableViewController {
    
    private var filterController: BTFilterControllerV2
    private var sortController: BTSortControllerV2?
    private var layoutController: BTTableLayoutSettingViewControllerV2?
    
    private var selectedIndex: Int = 0
    private var composiType: CompositeType = .filterAndSort
    
    private let titleText = BundleI18n.SKResource.Bitable_Layer_ConfigureLayer_Title
    
    weak var delegate: BTViewActionControllerDelegate?
    
    private lazy var bottomLine = UIView().construct { it in
        it.backgroundColor = UDColor.lineBorderCard
    }
    
    private lazy var listContainerView: UDTabsListContainerView = {
        let listContainerView = UDTabsListContainerView(dataSource: self)
        return listContainerView
    }()
    
    var syncClick: (() -> Void)?
    
    override var customHeader: UIView {
        return actionHeader
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    private lazy var actionHeader: BTViewActionHeader = {
        let header = BTViewActionHeader(frame: .zero)
        header.setTitle(titleText)
        header.syncClick = { [weak self] in
            self?.syncClick?()
        }
        header.closeClick = { [weak self] in
            self?.didClickClose()
        }
        return header
    }()
        
    private lazy var tabs: UDTabsTitleView = {
        let tabs = UDTabsTitleView()
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2                   // 设置指示器高度
        tabs.indicators = [indicator]
        tabs.delegate = self
        // 外观配置
        let config = tabs.getConfig()
        config.layoutStyle = .average
        config.itemSpacing = 0
        tabs.setConfig(config: config)
        tabs.listContainer = listContainerView
        return tabs
    }()
    
    init(with composiType: CompositeType,
         filterController: BTFilterControllerV2,
         sortController: BTSortControllerV2?,
         layoutController: BTTableLayoutSettingViewControllerV2?,
         selectedIndex: Int = 0) {
        self.composiType = composiType
        self.filterController = filterController
        self.sortController = sortController
        self.layoutController = layoutController
        super.init(title: titleText, shouldShowDragBar: true)
        self.filterController.changeContainerHeightBlock = { [weak self] (mode, animated) in
            self?.changeViewHeightMode(mode, animateDuration: animated ? 0.3 : 0)
        }
        self.sortController?.changeContainerHeightBlock = { [weak self] (mode, animated) in
            self?.changeViewHeightMode(mode, animateDuration: animated ? 0.3 : 0)
        }
        self.layoutController?.changeContainerHeightBlock = { [weak self] (mode, animated) in
            self?.changeViewHeightMode(mode, animateDuration: animated ? 0.3 : 0)
        }
        self.selectedIndex = selectedIndex
    }
    
    override func setupUI() {
        super.setupUI()
        
        let setupBlock = { [weak self] in
            guard let self = self else {
                return
            }
            self.setHeaderBottomSeparator(isHidden: true)
            self.contentView.addSubview(self.tabs)
            self.contentView.addSubview(self.bottomLine)
            self.contentView.addSubview(self.listContainerView)
            self.tabs.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview()
                make.height.equalTo(40)
            }
            
            self.bottomLine.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(0.5)
                make.top.equalTo(self.tabs.snp.bottom)
            }
            
            self.listContainerView.snp.makeConstraints { make in
                make.top.equalTo(self.bottomLine.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }
        let filterTitle = BundleI18n.SKResource.Bitable_BTModule_FilterPageTitle
        let sortTitle = BundleI18n.SKResource.Bitable_BTModule_Sort
        switch self.composiType {
        case .onlyFilter:
            contentView.addSubview(filterController.view)
            filterController.view.snp.makeConstraints { make in
                make.leading.trailing.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            self.tabs.isHidden = true
            self.listContainerView.isHidden = true
            self.selectedIndex = 0
            // 这里需要手动调，去拿数据
            filterController.listWillAppear()
        case .filterAndSort:
            if self.selectedIndex > 1 {
                self.selectedIndex = 0
                DocsLogger.btError("[BTViewActionController] invalid selelct index \(self.selectedIndex)")
            }
            tabs.defaultSelectedIndex = self.selectedIndex
            tabs.titles = [filterTitle, sortTitle]
            setupBlock()
        case .all:
            if self.selectedIndex > 2 {
                DocsLogger.btError("[BTViewActionController] invalid selelct index \(self.selectedIndex)")
                self.selectedIndex = 0
            }
            let settingTitle = BundleI18n.SKResource.Bitable_Mobile_CardMode_Layout_Button
            tabs.defaultSelectedIndex = self.selectedIndex
            tabs.titles = [filterTitle, sortTitle, settingTitle]
            setupBlock()
        }
        remakeContentViewConstraints(isContainBottomSafeArea: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.composiType == .onlyFilter {
            filterController.superControllerDidAppear(safeInset: view.safeAreaInsets)
        }
    }
    
    func updateRegular(_ ragular: Bool) {
        actionHeader.updateRegular(ragular)
    }
    
    func updateSync(with model: BTViewActionSyncButtonModel) {
        actionHeader.setData(model: model)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override func changeViewHeightMode(_ viewHeightMode: BTDraggableViewController.ViewHeightMode, animateDuration: TimeInterval = 0) {
//        super.changeViewHeightMode(viewHeightMode, animateDuration: animateDuration)
//    }
    
}

extension BTViewActionController: UDTabsListContainerViewDataSource {
    func listContainerView(_ listContainerView: UniverseDesignTabs.UDTabsListContainerView, initListAt index: Int) -> UniverseDesignTabs.UDTabsListContainerViewDelegate {
        switch self.composiType {
        case .all:
            switch index {
            case 0:
                return self.filterController
            case 1:
                return self.sortController ?? self.filterController
            case 2:
                return layoutController ?? self.filterController
            default:
                DocsLogger.btError("[BTViewActionController] invalid selelct index \(index)")
                return self.filterController
            }
        case .filterAndSort:
            switch index {
            case 0:
                return self.filterController
            case 1:
                return self.sortController ?? self.filterController
            default:
                DocsLogger.btError("[BTViewActionController] invalid selelct index \(index)")
                return self.filterController
            }
        case .onlyFilter:
            return self.filterController
        }
    }
    
    func numberOfLists(in listContainerView: UniverseDesignTabs.UDTabsListContainerView) -> Int {
        if self.layoutController != nil, self.sortController != nil {
            return 3
        } else if self.sortController != nil, self.layoutController == nil {
            return 2
        }
        return 1
    }
}

extension BTViewActionController: UDTabsViewDelegate {
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        listContainerView.didClickSelectedItem(at: index)
        if let item = listContainerView.validListDict[index] as? BTFilterControllerV2 {
            delegate?.filterView()
        } else if let item = listContainerView.validListDict[index] as? BTSortControllerV2 {
            delegate?.sortView()
        } else if let item = listContainerView.validListDict[index] as? BTTableLayoutSettingViewControllerV2 {
            delegate?.layoutView()
        }
    }
}
