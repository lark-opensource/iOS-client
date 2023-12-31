//
//  BTSortPanelViewModel.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/22.
//  



import SKFoundation
import RxSwift
import UniverseDesignIcon
import UniverseDesignColor


final class BTSortPanelViewModel {
    
    enum UpdateSortInfoAction {
        case updateAutoSort(_ isAutoSort: Bool)
        case updateSortInfo(original: BTSortData.SortFieldInfo, new: BTSortData.SortFieldInfo)
        case addSortInfo(_ sortInfo: BTSortData.SortFieldInfo)
        case removeSortInfo(_ sortInfoId: String)
        case apply
    }
    
    typealias CompletionHandler = (BTSortPanelModel?) -> Void
    
    var dataService: BTSortPanelDataServiceType
    
    private(set) var cacheJSData: BTSortData?
    
    private var callback: String
    
    private var disposeBag = DisposeBag()
    
    init(dataService: BTSortPanelDataServiceType, callback: String) {
        self.dataService = dataService
        self.callback = callback
    }
    
    func getSortModel(completion: CompletionHandler?) {
        dataService.getSortData().subscribe { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .success(let data):
                self.cacheJSData = data
                self.covertJSDataToSortPanelModel(with: data, completion: completion)
            case .error:
                completion?(nil)
            }
        }.disposed(by: self.disposeBag)
    }
    
    func updateSortInfos(action: UpdateSortInfoAction, completion: CompletionHandler?) {
        guard var sortData = cacheJSData  else {
            DocsLogger.btError("updateSortInfos without cacheJSData")
            completion?(nil)
            return
        }
        
        var isNeedSync = false
        switch action {
        case let .updateAutoSort(autoSort):
            sortData.autoSort = autoSort
            isNeedSync = true
        case let .updateSortInfo(original, new):
            guard let index = sortData.sortInfo.firstIndex(where: { $0.fieldId == original.fieldId }) else {
                DocsLogger.btError("updateSortInfos cannot find \(original) index of \(sortData.sortInfo)")
                completion?(nil)
                return
            }
            sortData.sortInfo[index] = new
        case let .addSortInfo(sortInfo):
            sortData.sortInfo.append(sortInfo)
        case let .removeSortInfo(fieldId):
            sortData.sortInfo.removeAll(where: { $0.fieldId == fieldId })
        case .apply:
            isNeedSync = true
        }
        
        guard sortData.autoSort || isNeedSync else {
            self.cacheJSData = sortData
            self.covertJSDataToSortPanelModel(with: sortData, completion: completion)
            return
        }
        // 如果 sortData 的排序条件为空，需要将自动排序置为 false
        if sortData.sortInfo.isEmpty {
            sortData.autoSort = false
        }
        
        dataService.updateSortData(newSortData: sortData, callback: callback).subscribe { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .success:
                self.cacheJSData = sortData
                self.covertJSDataToSortPanelModel(with: sortData, completion: completion)
            case .error:
                completion?(nil)
            }
        }.disposed(by: self.disposeBag)
    }
    
    func getAddNewInfo() -> BTSortData.SortFieldInfo? {
        
        guard let field = sortOptionsForSelect().first else {
            return nil
        }
        return  BTSortData.SortFieldInfo(fieldId: field.id, desc: false)
    }
    
    func getSortOption(by id: String) -> BTSortData.SortFieldOption? {
        return cacheJSData?.fieldOptions.first(where: { $0.id == id })
    }
    
    func getSortInfo(by id: String) -> BTSortData.SortFieldInfo? {
        return cacheJSData?.sortInfo.first(where: { $0.fieldId == id })
    }
    
    func getSortInfo(at index: Int) -> BTSortData.SortFieldInfo? {
        if cacheJSData?.sortInfo.count ?? 0 > 0 {
            return cacheJSData?.sortInfo[index]
        } else {
            return nil
        }
    }
    
    func getFieldCommonListData(with sortInfoIndex: Int) -> (datas: [BTFieldCommonData], selectedIndex: Int) {
        guard let sortData = cacheJSData else {
            return ([], 0)
        }
        var selectedFieldId = ""
        if sortData.sortInfo.count > sortInfoIndex {
            selectedFieldId = sortData.sortInfo[sortInfoIndex].fieldId
        }
        func getIcon(compositeType: BTFieldCompositeType) -> UIImage? {
            return compositeType.icon(size: CGSize(width: 20, height: 20))
        }
        let sortOptions = sortOptionsForSelect(keepFieldId: selectedFieldId)
        let selectedIndex = sortOptions.firstIndex(where: { $0.id == selectedFieldId }) ?? 0
        let datas: [BTFieldCommonData] = sortOptions.map {
            var data = BTFieldCommonData(id: $0.id,
                                         name: $0.name,
                                         icon: getIcon(compositeType: $0.compositeType),
                                         showLighting: $0.isSync ?? false,
                                         rightIocnType: .none,
                                         selectedType: .textHighlight)
            return data
        }
        return (datas, selectedIndex)
    }
    
    /// 可用于选择的 option
    private func sortOptionsForSelect(keepFieldId: String = "") -> [BTSortData.SortFieldOption] {
        guard let sortData = cacheJSData else {
            return []
        }
        let filterSet = Set(sortData.sortInfo.map { $0.fieldId })
        return sortData.fieldOptions.filter { (!filterSet.contains($0.id) || $0.id == keepFieldId) && $0.invalidType != .fieldUnreadable }
    }
    
    func covertJSDataToSortPanelModel(with sortData: BTSortData, completion: CompletionHandler?) {
        var index = 0
        let conditions: [BTConditionSelectCellModel] = sortData.sortInfo.compactMap { info in
            if let options = sortData.fieldOptions.first(where: { $0.id == info.fieldId }) {
                let icon = options.compositeType.icon()
                let fieldModel = BTConditionSelectButtonModel(text: options.name, icon: icon, showIconLighting: options.isSync ?? false, textColor: UDColor.textTitle)
                let descModel = BTConditionSelectButtonModel(text: sortData.getOrderText(by: info), textColor: UDColor.textTitle)
                index += 1
                return BTConditionSelectCellModel(conditionId: info.fieldId,
                                                  title: BTConditionSelectCellModel.titleWithIndex(index),
                                                  buttonModels: [fieldModel, descModel],
                                                  isShowDelete: true,
                                                  isWarningVisible: false,
                                                  warningText: "",
                                                  invalidType: options.invalidType)
            } else {
                return nil
            }
        }
        let sortPanelModel = BTSortPanelModel(
            isAddable: !sortOptionsForSelect().isEmpty,
            autoSort: sortData.autoSort,
            conditions: conditions,
            isPartial: sortData.isPartial,
            notice: sortData.notice
        )
        completion?(sortPanelModel)
    }
    
    func notifyClose() {
        self.dataService.notifyCloseSortPanel(callback: callback)
    }
}
