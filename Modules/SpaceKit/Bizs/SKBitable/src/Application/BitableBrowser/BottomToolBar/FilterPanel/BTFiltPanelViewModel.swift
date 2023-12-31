//
//  BTFilterPanelViewModel.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/19.
//  


import RxSwift
import HandyJSON
import SKFoundation

struct BTConjuctionSelectedModel: HandyJSON {
    var title: String = ""
    var description: String = ""
}

final class BTFilterPanelViewModel {
    
    enum UpdateFilterInfoAction {
        case updateConjuction(value: String)
        case addCondition(_ condition: BTFilterCondition)
        case updateCondition(_ condition: BTFilterCondition)
        case removeCondition(_ conditionId: String)
        case reloadCondition(_ conditionId: String)
        
        var setFilterType: BTSetFilterType {
            switch self {
            case .updateConjuction: return .SetConjunction
            case .updateCondition: return .UpdateCondition
            case .addCondition: return .AddCondition
            case .removeCondition: return .DeleteCondition
            case .reloadCondition: return .ReloadCondition
            }
        }
    }
    
    struct FilterPanelNeedJSData {
        var filterInfos: BTFilterInfos
        var filterOptions: BTFilterOptions
        var cellModes: [BTLinkFieldFilterCellModel] = []
        var notice: String?
        var schemaVersion: Int?
        var isRowLimit: Bool?
        init(filterInfos: BTFilterInfos, filterOptions: BTFilterOptions) {
            // filterInfos 的condition拿的时候无法改结构，所以同步filterOptions的信息
            var conditions = filterInfos.conditions.map({ condition in
                var infoConditon = condition
                for option in filterOptions.fieldOptions where option.id == condition.fieldId {
                    infoConditon.invalidType = option.invalidType
                }
                return infoConditon
            })
            var infos = filterInfos
            infos.conditions = conditions
            self.filterOptions = filterOptions
            self.filterInfos = infos
            self.notice = filterInfos.notice
            self.schemaVersion = filterInfos.schemaVersion
            self.isRowLimit = filterInfos.isRowLimit
        }
    }
    
    /// 缓存从 js 中获取的数据，第一次展示 js 时会更新，以及监听到有协同时才重新拉取。
    private(set) var cacheJSData: FilterPanelNeedJSData?
    
    private(set) var filterFlowService: BTFilterDataServiceType
    
    private var filterPanelService: BTFilterPanelDataServiceType
    
    private var cellViewDataManager: BTLinkFieldFilterCellViewDataManager?
    
    private var disposeBag = DisposeBag()
    
    private var callback: String
    
    init(filterPanelService: BTFilterPanelDataServiceType,
         filterFlowService: BTFilterDataServiceType,
         callback: String) {
        self.filterPanelService = filterPanelService
        self.filterFlowService = filterFlowService
        self.callback = callback
    }
    
    /// 全量刷新筛选面板数据
    func getFilterPanelModel(completion: ((BTFilterPanelModel?) -> Void)?) {
        updateCacheJSDataGetPanelModel(action: .refresh, completion: completion)
    }
    
    /// 更新条件
    func updateFilterInfo(action: UpdateFilterInfoAction, completion: ((BTFilterPanelModel?) -> Void)?) {
        let value: Any
        switch action {
        case .updateConjuction(let _value):
            value = _value
        case .addCondition(let condition):
            value = condition.toDict()
        case .updateCondition(let condition):
            value = condition.toDict()
        case .removeCondition(let conditionId):
            value = conditionId
        case .reloadCondition(let conditionId):
            //不需要通知前端
            reloadCondition(conditionId: conditionId, completion: completion)
            return
        }
        filterPanelService.updateFilterInfo(type: action.setFilterType, value: value, callback: callback)
            .subscribe { [weak self] event in
                switch event {
                case .success:
                    switch action {
                    case .updateConjuction(let value):
                        self?.updateCacheJSDataGetPanelModel(action: .updateConjuction(value: value), completion: completion)
                    case .updateCondition(let condition):
                        self?.updateCacheJSDataGetPanelModel(action: .updateCondition(condition), completion: completion)
                    case .addCondition(let condition):
                        self?.updateCacheJSDataGetPanelModel(action: .addCondition(condition), completion: completion)
                    case .removeCondition(let conditionId):
                        self?.updateCacheJSDataGetPanelModel(action: .removeCondition(conditionId), completion: completion)
                    default:
                        break
                    }
                default:
                    completion?(nil)
                }
            }.disposed(by: disposeBag)
    }
    
    /// 获取任一/所有选择数据
    func getConjuctionSelectedModels() -> (models: [BTConjuctionSelectedModel], selectedIndex: Int) {
        guard let jsData = cacheJSData else {
            return ([], 0)
        }
        return BTFilterHelper.getConjunctionModels(by: jsData.filterOptions,
                                                   conjuctionValue: jsData.filterInfos.conjunction)
    }
    
    /// 创建新的条件
    func makeNewCondtion(completion: @escaping (BTFilterCondition?) -> Void) {
        guard let fieldOption = cacheJSData?.filterOptions.fieldOptions.first else {
            DocsLogger.btError("BTFilterPanelViewModel makeNewCondtion Error cacheJSData: \(String(describing: cacheJSData))")
            completion(nil)
            return
        }
        
        let conditionIds = cacheJSData?.filterInfos.conditions.compactMap({ $0.conditionId }) ?? []
        
        filterFlowService.getNewConditionIds(ids: conditionIds, total: 1).subscribe { event in
            switch event {
            case .success(let conditionIds):
                guard let conditionId = conditionIds.first else {
                    completion(nil)
                    return
                }
                // 移动端创建新条件不可能创建无权限访问字段相关的条件
                let condition = BTFilterCondition(conditionId: conditionId,
                                                  fieldId: fieldOption.id,
                                                  fieldType: fieldOption.compositeType.type.rawValue,
                                                  operator: fieldOption.operators.first?.value ?? BTFilterOperator.defaultValue,
                                                  value: BTFilterValueType(valueType: fieldOption.valueType).defaultValue)
                completion(condition)
            default:
                completion(nil)
            }
           
        }.disposed(by: self.disposeBag)
    }
    
    func reloadCondition(conditionId: String, completion: ((BTFilterPanelModel?) -> Void)?) {
        guard let cacheJSData = cacheJSData,
              let condition = cacheJSData.filterInfos.conditions.first(where: { $0.conditionId == conditionId }) else {
            return
        }
        
        if let cellViewDataManager = cellViewDataManager {
            cellViewDataManager.update(timeZoneId: cacheJSData.filterOptions.timeZone, filterOptions: cacheJSData.filterOptions)
            cellViewDataManager.restCache()
            self.cellViewDataManager = cellViewDataManager
        } else {
            cellViewDataManager = BTLinkFieldFilterCellViewDataManager(dataService: filterFlowService,
                                                                       timeZoneId: cacheJSData.filterOptions.timeZone,
                                                                       filterOptions: cacheJSData.filterOptions)
        }
        
        let disposeCellDatas: ([BTLinkFieldFilterCellModel]) -> Void = { [weak self] cellDatas in
            guard let self = self else { return }
            //只更新了一个model，所以这里的cellDatas也只有一个
            self.cacheJSData?.cellModes = cacheJSData.cellModes.compactMap({ mode -> BTLinkFieldFilterCellModel in
                return cellDatas.first(where: { $0.conditionId == mode.conditionId }) ?? mode
            })
            
            guard let cellModes = self.cacheJSData?.cellModes else {
                return
            }
            
            let cellModels = self.convertCellDatasToCellModels(cellModes)

            let conjuctionData = cacheJSData.filterOptions.conjunctionOptions.first(where: { $0.value == cacheJSData.filterInfos.conjunction })
            let conjuction = BTConditionConjuctionModel(id: conjuctionData?.value ?? "", text: conjuctionData?.text ?? "")
            
            completion?(BTFilterPanelModel(conjuction: conjuction, conditions: cellModels, notice: cacheJSData.notice))
        }
        
        cellViewDataManager?.convert(conditions: [condition]) { cellDatas in
            disposeCellDatas(cellDatas)
        } complete: { cellDatas in
            disposeCellDatas(cellDatas)
        }
    }
    
    func converJSDataToPanelMdoel(with jsData: FilterPanelNeedJSData, completion: ((BTFilterPanelModel?) -> Void)?) {
        let cellViewDataManager = BTLinkFieldFilterCellViewDataManager(dataService: filterFlowService,
                                                                       timeZoneId: jsData.filterOptions.timeZone,
                                                                       filterOptions: jsData.filterOptions)
        self.cellViewDataManager = cellViewDataManager
        
        let disposeCellDatas: ([BTLinkFieldFilterCellModel]) -> Void = { [weak self] cellDatas in
            guard let self = self else { return }
            let cellModels = self.convertCellDatasToCellModels(cellDatas)
            let conjuctionData = jsData.filterOptions.conjunctionOptions.first(where: { $0.value == jsData.filterInfos.conjunction })
            let conjuction = BTConditionConjuctionModel(id: conjuctionData?.value ?? "", text: conjuctionData?.text ?? "")
            self.cacheJSData?.cellModes = cellDatas
            completion?(BTFilterPanelModel(conjuction: conjuction, conditions: cellModels, notice: jsData.notice))
        }
        
        cellViewDataManager.convert(conditions: jsData.filterInfos.conditions) { cellDatas in
            disposeCellDatas(cellDatas)
        } complete: { cellDatas in
            disposeCellDatas(cellDatas)
        }
    }
    
    func convertCacheJSDatasToPanleModel(with jsData: FilterPanelNeedJSData, completion: ((BTFilterPanelModel?) -> Void)?) {
        let conjuctionData = jsData.filterOptions.conjunctionOptions.first(where: { $0.value == jsData.filterInfos.conjunction })
        let conjuction = BTConditionConjuctionModel(id: conjuctionData?.value ?? "", text: conjuctionData?.text ?? "")
        
        let cellModels = convertCellDatasToCellModels(cacheJSData?.cellModes ?? [])
        completion?(BTFilterPanelModel(conjuction: conjuction, conditions: cellModels, notice: jsData.notice))
    }
    
    func convertCellDatasToCellModels(_ cellDatas: [BTLinkFieldFilterCellModel]) -> [BTConditionSelectCellModel] {
        var cellModels = [BTConditionSelectCellModel]()
        for (index, data) in cellDatas.enumerated() {
            let cellModel = BTConditionSelectCellModel(conditionId: data.conditionId,
                                                       title: BTConditionSelectCellModel.titleWithIndex(index + 1),
                                                       buttonModels: data.conditionButtonModels,
                                                       isShowDelete: data.fieldErrorType != .fieldNotSupport,
                                                       isWarningVisible: (data.fieldErrorType != nil),
                                                       warningText: data.fieldErrorType?.warnMessage ?? "",
                                                       invalidType: data.invalidType)
            cellModels.append(cellModel)
        }
        
        return cellModels
    }
    
    
    private enum CacheJSDataChangeAction {
        case refresh
        case updateConjuction(value: String)
        case updateCondition(_ condition: BTFilterCondition)
        case addCondition(_ condition: BTFilterCondition)
        case removeCondition(_ conditionId: String)
    }
    
    private func updateCacheJSDataGetPanelModel(action: CacheJSDataChangeAction, completion: ((BTFilterPanelModel?) -> Void)?) {
        guard var jsData = cacheJSData else {
            refreshAllJSData(completion: completion)
            return
        }
        switch action {
        case .refresh:
            refreshAllJSData(completion: completion)
            return
        case .updateConjuction(let conjuctionValue):
            jsData.filterInfos.conjunction = conjuctionValue
        case .updateCondition(let condition):
            guard let index = jsData.filterInfos.conditions.firstIndex(where: { $0.conditionId == condition.conditionId }) else {
                completion?(nil)
                return
            }
            
            let oldCondition = jsData.filterInfos.conditions[index]
            if oldCondition.fieldId != condition.fieldId {
                //条件引用的字段发生变更， 取消异步回调
                cellViewDataManager?.cancelAsyncResponse(conditionId: condition.conditionId)
            }
            
            jsData.filterInfos.conditions[index] = condition
            self.cacheJSData = jsData
            self.reloadCondition(conditionId: condition.conditionId, completion: completion)
            return
        case .addCondition(let condition):
            jsData.filterInfos.conditions.append(condition)
            
            let addCondition: ([BTLinkFieldFilterCellModel]) -> Void = { [weak self] cellDatas in
                guard let self = self, let jsData = self.cacheJSData else { return }
                self.cacheJSData?.cellModes += cellDatas
                self.convertCacheJSDatasToPanleModel(with: jsData, completion: completion)
            }
            self.cellViewDataManager?.convert(conditions: [condition], responseHandler: { cellDatas in
                addCondition(cellDatas)
            }, complete: { cellDatas in
                addCondition(cellDatas)
            })
            return
        case .removeCondition(let conditionId):
            jsData.filterInfos.conditions.removeAll(where: { $0.conditionId == conditionId })
            jsData.cellModes.removeAll(where: { $0.conditionId == conditionId })
            //条件被删除， 取消异步回调
            cellViewDataManager?.cancelAsyncResponse(conditionId: conditionId)
        }
        self.cacheJSData = jsData
        self.convertCacheJSDatasToPanleModel(with: jsData, completion: completion)
    }
    
    private func refreshAllJSData(completion: ((BTFilterPanelModel?) -> Void)?) {
        // 获取当前筛选信息，获取筛选流程信息。
        Single.zip(filterFlowService.getFilterInfo(),
                   filterFlowService.getFieldFilterOptions()).subscribe { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .success(let data):
                let jsData = FilterPanelNeedJSData(filterInfos: data.0, filterOptions: data.1)
                self.cacheJSData = jsData
                self.converJSDataToPanelMdoel(with: jsData, completion: completion)
            default:
                completion?(nil)
            }
        }.disposed(by: disposeBag)
    }
}
