//
//  BTJSService+GroupingStatistics.swift
//  SKBitable
//
//  Created by zoujie on 2022/3/15.
//  


import SKFoundation
import SKUIKit
import EENavigator
import HandyJSON
import SKCommon
import SKBrowser

enum BTGroupingStatisticsActionType: Int, HandyJSONEnum {
    case open = 1
    case update = 2
    case close = 3
    case destory = 4
    case notSupport = 5
}

enum BTGroupStatPanelType: Int, HandyJSONEnum {
    case group = 1
    case total = 3
}

struct BTGroupingStatisticsModel: HandyJSON, BTEventBaseDataType {
    var type: BTGroupingStatisticsActionType = .open // 1=打开浮层 2=更新浮层 3=关闭浮层 4=销毁native现有数据，使用当前数据
    var baseId: String = ""
    var viewId: String = ""
    var tableId: String = ""
    var panelType:BTGroupStatPanelType = .group
    var callback: String = ""
    
    var data: Any?
    
    mutating func mapping(mapper: HelpingMapper) {
        mapper >>> self.data
    }
}

struct BTStatGroupData: HandyJSON {
    var focusStatType: String = ""
    var groupData: [BTGroupingStatisticsData] = [] // 一级分组
    var focusId: [String] = [] // 默认展开的分组
    var hasMoreData: [Bool] = [] // [true, true], top，bottom
    var colorList: [BTColorModel] = []
    var maxRecordSize: Int = 2000 //支持显示的最大记录数
}

// 全局统计结果
struct BTStatGlobalData: HandyJSON {
  var fieldName: String = ""
  var result: String = ""
  var label: String = ""
}

struct BTGroupingStatisticsData: HandyJSON {
    var id: String = ""
    var name: [BTGroupingStatisticsName] = []
    var value: String = ""
    var isComputed: Bool = true // value值是否处于计算中
    var detailData: [BTGroupingStatisticsDetail] = [] // 一级分组数据
    var childrenGroupData: [BTGroupingStatisticsData] = [] // 二级分组
    var hasMoreData: [Bool] = [] // [true, true]
}

struct BTGroupingStatisticsName: HandyJSON {
    var name: String = ""
    var bgColor: String = ""
}

struct BTGroupingStatisticsDetail: HandyJSON {
    var name: String = ""
    var value: String = ""
    var isComputed: Bool = true
}

struct BTGroupingStatisticsObtainGroupData: HandyJSON {
    var hasMore: Bool = true
    var groupData: [BTGroupingStatisticsData] = []
    var params: [String: String] = [:]
}

extension BTJSService {
    func handleStatService(_ param: [String: Any]) {
        guard var groupingStatisticsModel = BTGroupingStatisticsModel.deserialize(from: param), let dataObj = param["data"] else {
            DocsLogger.btError("bt fieldGrouping handleGroupService deserialize failed")
            return
        }
        var data: Any? = nil
        switch groupingStatisticsModel.panelType {
        case .group:
            if let dict = dataObj as? [String: Any] {
                data = BTStatGroupData.deserialize(from: dict)
            }
        case .total:
            if let arr = dataObj as? [[String: Any]] {
                data = [BTStatGlobalData].deserialize(from: arr)
            }
        }
        guard let data = data else {
            DocsLogger.btError("data should not be nil!")
            return
        }
        groupingStatisticsModel.data = data
        
        var cardAction = BTGroupingActionTask()
        cardAction.groupingModel = groupingStatisticsModel
        
        let permissionObj = BasePermissionObj.parse(param)
        let baseContext = BaseContextImpl(baseToken: groupingStatisticsModel.baseId, service: self, permissionObj: permissionObj, from: "statistics")
        actionQueueManager.taskExecuteBlock = { [weak self] task in
            guard let actionTask = task as? BTGroupingActionTask else {
                return
            }
            self?.handleGroupingActionTask(actionTask: actionTask, baseContext: baseContext)
        }
        actionQueueManager.addTask(task: cardAction)
    }
    
    func handleGroupingActionTask(actionTask: BTGroupingActionTask, baseContext: BaseContext) {
        guard let browseVC = navigator?.currentBrowserVC as? BrowserViewController else {
            return
        }
        
        let groupingStatisticsModel = actionTask.groupingModel
        switch groupingStatisticsModel.type {
        case .open, .notSupport:
            let groupVC = BTFieldGroupingAnimateViewController(groupingStatisticsModel: groupingStatisticsModel,
                                                               reportCommonParams: getBitableGroupStatisticsCommonTrackParams(groupingStatisticsModel: groupingStatisticsModel),
                                                               openPanelAction: actionTask,
                                                               hostVC: browseVC,
                                                               baseContext: baseContext,
                                                               dataService: self)

            groupVC.dismissBlock = { [weak self] in
                self?.groupStatisticsVC = nil
                self?.actionQueueManager.reset()
            }
            groupVC.delegate = self
            let nav = SKNavigationController(rootViewController: groupVC)


            let isRegularSize = browseVC.isMyWindowRegularSize() && SKDisplay.pad
            if isRegularSize {
                nav.modalPresentationStyle = .formSheet
                nav.preferredContentSize = CGSize(width: 540, height: 620)
                nav.presentationController?.delegate = groupVC
            } else {
                nav.modalPresentationStyle = .overFullScreen
                nav.update(style: .clear)
                nav.transitioningDelegate = groupVC.panelTransitioningDelegate
            }
            if !UserScopeNoChangeFG.YY.bitableReferPermission {
                groupVC.setCaptureAllowed(hasCopyPermissionDeprecated)
            }
            self.groupStatisticsVC = groupVC
            safePresent {
                Navigator.shared.present(nav, from: UIViewController.docs.topMost(of: browseVC) ?? browseVC)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    //避免BTFieldGroupingAnimateViewController present失败导致后续task无法执行
                    groupVC.openPanelAction?.completedBlock()
                    groupVC.openPanelAction = nil
                }
            }

        case .update, .destory:
            groupStatisticsVC?.updateData(groupingStatisticsModel: groupingStatisticsModel)
            actionTask.completedBlock()
        case .close:
            groupStatisticsVC?.navigationController?.dismiss(animated: true)
            actionTask.completedBlock()
            actionQueueManager.reset()
        }
    }

    func handleGroupRequestData(_ param: [String: Any]) {
        guard let groupingStatisticsObtainData = BTGroupingStatisticsObtainGroupData.deserialize(from: param) else {
            DocsLogger.btError("bt fieldGrouping handleGroupRequestData deserialize failed")
            return
        }

        groupStatisticsVC?.updateGroupObtainData(groupingStatisticsObtainData: groupingStatisticsObtainData)
    }
}

extension BTJSService: BTFieldGroupingAnimateViewControllerDelegate {
    func didOpenFieldGroupingView(groupingStatisticsModel: BTGroupingStatisticsModel) {
        var params = getBitableGroupStatisticsCommonTrackParams(groupingStatisticsModel: groupingStatisticsModel)
        switch groupingStatisticsModel.panelType {
        case .group:
            var hasSecondGroup = false
            if let data = groupingStatisticsModel.data as? BTStatGroupData {
                hasSecondGroup = data.groupData.contains(where: { !$0.childrenGroupData.isEmpty })
            }
            params["group_num"] = hasSecondGroup ? 2 : 1
            DocsTracker.newLog(enumEvent: .bitableGroupStatisticsView, parameters: params)
        case .total:
            DocsTracker.newLog(enumEvent: .bitableGlobalStatisticsView, parameters: params)
        }
    }
}


extension BTJSService {
    // 字段分组统计埋点公参
    func getBitableGroupStatisticsCommonTrackParams(groupingStatisticsModel: BTGroupingStatisticsModel) -> [String: Any] {
        guard let browseVC = navigator?.currentBrowserVC as? BrowserViewController,
              let docsInfo = browseVC.docsInfo else { return [:] }
        var params = BTEventParamsGenerator.createCommonParams(by: docsInfo, baseData: groupingStatisticsModel)
        if let view = BTGlobalTableInfo.currentViewInfoForBase(groupingStatisticsModel.baseId),
           view.baseId == groupingStatisticsModel.baseId,
           view.tableId == groupingStatisticsModel.tableId,
           view.viewId == groupingStatisticsModel.viewId {
            params[BTTableLayoutSettings.ViewType.trackKey] = view.gridViewLayoutType?.trackValue
            if let type = view.gridViewLayoutType, type == .card, UserScopeNoChangeFG.XM.nativeCardViewEnable {
                params.merge(other: CardViewConstant.commonParams)
            }
        }
        return params
    }
}
