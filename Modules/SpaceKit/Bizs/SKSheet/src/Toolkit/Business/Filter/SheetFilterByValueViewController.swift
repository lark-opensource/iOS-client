//
//  SheetFilterByValueViewController.swift
//  SpaceKit
//
//  Created by Webster on 2019/9/26.
//

import Foundation
import SKCommon
import SKBrowser
import SKUIKit
import SKResource
import UniverseDesignIcon
import SKFoundation

protocol SheetFilterByValueDelegate: AnyObject {
    func temporarilyDisableDraggability()
    func restoreDraggability()
    func didPressPanelSearchButton(_ controller: SheetFilterByValueViewController)
    func didPressKeyboardSearchButton(_ controller: SheetFilterByValueViewController)
}

class SheetFilterByValueViewController: SheetFilterDetailViewController {
    enum DisplayMode { case normal, spread, focus }
    weak var valueDelegate: SheetFilterByValueDelegate?
    private var displayMode: DisplayMode = .spread
    private let selectAllHeight: CGFloat = 48
    private let searchItemHeight: CGFloat = 52
    private let reuseIdentifier = "com.bytedance.ee.sheet.value"
    private var filterText: String?
    private var filteredValueItems: [SheetFilterInfo.FilterValueItem] = []
    private var optTotalValueItems: [SheetFilterInfo.FilterValueItem] = []
    private var kbListener: Keyboard?
    private var keyboardRect: CGRect?
    private var uiSelectedAllBeforeFocus = false

    override var resourceIdentifier: String {
        return BadgedItemIdentifier.filterValue.rawValue
    }

    private lazy var exitSeachButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didRequestExitSearch), for: .touchUpInside)
        button.setImage(UDIcon.closeSmallOutlined.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        button.docs.addStandardHighlight()
        return button
    }()

    private lazy var totalCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.register(SheetFilterNormalValueCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    private lazy var searchView: SheetFilterSearchView = {
        let view = SheetFilterSearchView()
        view.delegate = self
        return view
    }()

    private lazy var selectAllView: SheetFilterSelectAllView = {
        let view = SheetFilterSelectAllView()
        view.delegate = self
        return view
    }()
   
    var superWidth: CGFloat = SKDisplay.activeWindowBounds.width
    
    required convenience init(_ filterInfo: SheetFilterInfo, _ superWidth: CGFloat) {
        self.init(filterInfo)
        self.superWidth = superWidth
    }
    
    override init(_ filterInfo: SheetFilterInfo) {
        super.init(filterInfo)
        scrollView.isHidden = true
        kbListener = Keyboard(listenTo: [searchView.textField], trigger: DocsKeyboardTrigger.sheetFilterSearch.rawValue)
        optTotalValueItems = filterInfo.valueFilter?.valueList ?? []
        prepareFilteredValue()
        view.addSubview(searchView)
        view.addSubview(totalCollectionView)
        view.addSubview(selectAllView)
        navigationBar.addSubview(exitSeachButton)

        exitSeachButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
        }

        searchView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(switchView.snp.bottom)
            make.height.equalTo(searchItemHeight)
            make.width.equalToSuperview()
        }

        selectAllView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(searchView.snp.bottom)
            make.height.equalTo(selectAllHeight)
            make.width.equalToSuperview()
        }
        
        let enabled = UserScopeNoChangeFG.LJW.sheetInputViewFix
        totalCollectionView.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.left.equalToSuperview()
            make.top.equalTo(selectAllView.snp.bottom)
            if enabled {
               make.bottom.equalTo(view.skKeyboardLayoutGuide.snp.top)
            } else {
               make.bottom.equalToSuperview()
            }
        }

        selectAllView.searchButton.isHidden = true
        exitSeachButton.isHidden = true

        switchDisplayMode(.normal)
        update(filterInfo)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(_ info: SheetFilterInfo) {
        let hasChangeFilter = info.filterId != self.filterInfo.filterId
        super.update(info)
        
        if displayMode == .focus, hasChangeFilter {
            DocsLogger.info("end edit when search panel focus")
            self.textFieldWillEndEdit(searchView)
        }
        
        refreshSelectedAllView(info)
        optTotalValueItems = filterInfo.valueFilter?.valueList ?? []
        prepareFilteredValue()
        reloadCollectionView(filterTxt: filterText ?? "")
    }

    private func prepareFilteredValue() {
        if let realFilterText = filterText, !realFilterText.isEmpty {
            let result = optTotalValueItems.filter({ return $0.value.range(of: realFilterText, options: .caseInsensitive) != nil })
            filteredValueItems = result
        } else {
            filteredValueItems = optTotalValueItems
        }
    }

    func switchDisplayMode(_ mode: DisplayMode) {
        guard mode != displayMode else { return }
        var switchItemHeight = switchHeight
        var searchViewHeight = searchItemHeight
        var searchButtonHidden = false
        var navigationBackHidden = false
        var panBarHidden = false
        var exitSearchButtonHidden = true
        var changeNavigationTitle = false

        switch mode {
        case .normal:
            searchViewHeight = 0
            exitSearch()
        case .focus:
            switchItemHeight = 0
            searchButtonHidden = true
            navigationBackHidden = true
            panBarHidden = true
            exitSearchButtonHidden = false
            changeNavigationTitle = true
        case .spread:
            searchButtonHidden = true
            exitSearch()
        }
        switchView.snp.updateConstraints { (make) in
            make.height.equalTo(switchItemHeight)
        }
        searchView.snp.updateConstraints { (make) in
            make.height.equalTo(searchViewHeight)
        }

        selectAllView.searchButton.isHidden = searchButtonHidden
        navigationBar.setBackButton(isHidden: navigationBackHidden)
        exitSeachButton.isHidden = exitSearchButtonHidden
        navigationBar.setTitleText(changeNavigationTitle ? BundleI18n.SKResource.Doc_Facade_Search : filterInfo.navigatorTitle)

        if let navigationController = self.navigationController as? SheetToolkitNavigationController {
            navigationController.setDraggableHandle(isHidden: panBarHidden)
            panBarHidden ? valueDelegate?.temporarilyDisableDraggability() : valueDelegate?.restoreDraggability()
        }

        displayMode = mode
    }

    func exitSearch() {
        searchView.textField.resignFirstResponder()
        refreshSelectedAllView(filterInfo)
        scrollToTop()
    }

    @objc
    func didRequestExitSearch() {
        switchDisplayMode(.spread)
        if shouldDoSpeacialReload() {
            reloadSpecialCollectionView()
        } else {
            reloadCollectionView(filterTxt: "")
        }
        searchView.cleanInput()
        refreshSelectedAllView(filterInfo)
        callToFrontSelectedInfo()
        scrollToTop()
        valueDelegate?.didPressPanelSearchButton(self)
    }

    func reloadCollectionView(filterTxt: String) {
        filterText = filterTxt
        prepareFilteredValue()
        totalCollectionView.reloadData()
    }

    func reloadSpecialCollectionView() {
        for i in 0..<optTotalValueItems.count {
            optTotalValueItems[i].selected = false
        }

        let filterSelectdItem = filteredValueItems.filter { $0.selected == true }
        for j in 0..<filterSelectdItem.count {
            if let matchIndex = optTotalValueItems.firstIndex(where: { $0.index == filterSelectdItem[j].index }) {
                optTotalValueItems[matchIndex].selected = true
            }
        }
        filteredValueItems = optTotalValueItems
        filterText = ""
        totalCollectionView.reloadData()
    }

    private func scrollToTop() {
        totalCollectionView.setContentOffset(CGPoint.zero, animated: false)
    }
}

extension SheetFilterByValueViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: superWidth, height: itemHeight)
    }
}

extension SheetFilterByValueViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredValueItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let normalCell = cell as? SheetFilterNormalValueCell {
            let info = filteredValueItems[indexPath.row]
            normalCell.configure(by: info)
        }
        return cell
    }
}

extension SheetFilterByValueViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? SheetFilterNormalValueCell else {
            return
        }
        let nextStatus = !cell.isItemSelected
        filteredValueItems[indexPath.row].selected = nextStatus
        if let matchIndex = optTotalValueItems.firstIndex(where: { $0.index == filteredValueItems[indexPath.row].index }) {
            optTotalValueItems[matchIndex].selected = nextStatus
        }
        refreshSelectedAllView(filterInfo)
        callToFrontSelectedInfo()
        collectionView.reloadData()
    }

    private func callToFrontSelectedInfo(_ inSearch: Bool = false) {
        let selectedItems = optTotalValueItems.filter { $0.selected == true }
        let unSelectedItems = optTotalValueItems.filter { $0.selected == false }
        var callBackList: [Int] = []
        if selectedItems.count <= 0 {
            callBackList = []
        } else if unSelectedItems.count <= 0 {
            //跟前端的约定，全部选中传的是["-1"]
            callBackList = [-1]
        } else {
            callBackList = selectedItems.map({ (item) -> Int in
                return item.index
            })
        }
        delegate?.requestJsCallBack(identifier: BarButtonIdentifier.cellFilterByValue.rawValue, range: callBackList, controller: self, bySearch: inSearch)
    }

}

extension SheetFilterByValueViewController: SheetFilterSearchViewDelegate {

    func textFieldWillBeginEdit(_ view: SheetFilterSearchView) {
        switchDisplayMode(.focus)
        delegate?.willBeginTextInput(controller: self)
        uiSelectedAllBeforeFocus = (optTotalValueItems.filter { $0.selected == false }.count <= 0)
        scrollToTop()
    }

    func textFieldWillEndEdit(_ view: SheetFilterSearchView) {
        delegate?.willEndTextInput(controller: self)
        switchDisplayMode(.normal)
        if filteredValueItems.isEmpty {
            if shouldDoSpeacialReload() {
                reloadSpecialCollectionView()
            } else {
                reloadCollectionView(filterTxt: "")
            }
            searchView.cleanInput()
            refreshSelectedAllView(filterInfo)
            callToFrontSelectedInfo(true)
        }
        scrollToTop()
        valueDelegate?.didPressKeyboardSearchButton(self)
    }

    func textFieldChangeText(_ text: String, view: SheetFilterSearchView) {
        reloadCollectionView(filterTxt: text)
        refreshSelectedAllView(filterInfo)
        if text.isEmpty {
            callToFrontSelectedInfo(true)
        }
    }
}

// select all mananger
extension SheetFilterByValueViewController: SheetFilterSelectAllViewDelegate {

    func hasAllSelect(selected: Bool, view: SheetFilterSelectAllView) {
        for j in 0..<filteredValueItems.count {
            filteredValueItems[j].selected = selected
            if let matchIndex = optTotalValueItems.firstIndex(where: { $0.index == filteredValueItems[j].index }) {
                optTotalValueItems[matchIndex].selected = selected
            }
        }
        reloadCollectionView(filterTxt: filterText ?? "")
        callToFrontSelectedInfo()
    }

    func requestFocusSearch(view: SheetFilterSelectAllView) {
        searchView.textField.becomeFirstResponder()
        valueDelegate?.didPressPanelSearchButton(self)
    }

    private func refreshSelectedAllView(_ info: SheetFilterInfo, mode: DisplayMode? = nil) {

        func updateView(selectedAll: Bool, total: Int) {
            var shouldSelectedAll = selectedAll
            if total <= 0 {
                selectAllView.isUserInteractionEnabled = false
                shouldSelectedAll = false
            }
            let index = shouldSelectedAll ? -1 : 0
            let valueItem = SheetFilterInfo.FilterValueItem(index: index,
                                                            value: BundleI18n.SKResource.Doc_Sheet_SelectAll,
                                                            count: total,
                                                            selected: shouldSelectedAll)
            selectAllView.configure(by: valueItem)
        }

        let currentMode = mode ?? displayMode
        selectAllView.isUserInteractionEnabled = true
        switch currentMode {
        case .normal, .spread:
            let unSelectedItems = optTotalValueItems.filter { $0.selected == false }
            let selectedAll = unSelectedItems.count == 0
            let total = info.valueFilter?.total ?? 0
            updateView(selectedAll: selectedAll, total: total)
        case .focus:
            let unSelectedItems = filteredValueItems.filter { $0.selected == false }
            let totalFilter = filteredValueItems.map({ $0.count }).reduce(0, +)
            let selectedAll = unSelectedItems.count == 0
            updateView(selectedAll: selectedAll, total: totalFilter)
        }
    }

    private func shouldDoSpeacialReload() -> Bool {
        let items = filteredValueItems.filter { $0.selected == true }
        return items.count > 0 && uiSelectedAllBeforeFocus
    }

}
