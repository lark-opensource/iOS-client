//
//  BTJSService+FieldEdit.swift
//  SKBitable
//
//  Created by zoujie on 2021/12/7.
//  swiftlint:disable file_length


import UIKit
import HandyJSON
import SKFoundation
import SKBrowser
import SKCommon
import EENavigator
import SKUIKit
import LarkUIKit
import RxSwift
import UniverseDesignColor

extension BTJSService {
    func handleFieldEditService(_ param: [String: Any]) {
        guard let browseVC = navigator?.currentBrowserVC as? BrowserViewController,
              let fieldEditModel = BTFieldEditModel.deserialize(from: param),
              let type = BTFieldActionType(rawValue: fieldEditModel.type ) else {
            DocsLogger.btError("字段增删改前端数据解析失败")
            return
        }
        DocsLogger.btInfo("前端调用显示字段编辑面板 type:\(fieldEditModel.type) position:\(fieldEditModel.position)")
        modifyFieldCallback = DocsJSCallBack(fieldEditModel.callback)

        //是否需要present编辑页面，当当前视图无编辑页面时需要present，避免前端短时间多次调用接口出现页面跳动的问题
        let shouldPresentEditVC = (editController == nil || editController?.view.window == nil)
        let permissionObj = BasePermissionObj.parse(param)
        switch type {
        case .modify:
            if SKDisplay.pad,
               !browseVC.view.frame.contains(CGPoint(x: max(fieldEditModel.position.x, 0),
                                                     y: max(fieldEditModel.position.y, 0))) {
                DocsLogger.btError("字段增删改前端传过来的position不合法 position:\(fieldEditModel.position)")
                return
            }
            let baseContext = BaseContextImpl(baseToken: fieldEditModel.baseId, service: self, permissionObj: permissionObj, from: "modifyField")
            presentBTFieldOperationController(fieldEditModel: fieldEditModel, baseContext: baseContext)
        case .add:
            //新增字段
            if shouldPresentEditVC {
                let baseContext = BaseContextImpl(baseToken: fieldEditModel.baseId, service: self, permissionObj: permissionObj, from: "addField")
                presentBTFieldEditController(fieldEditModel: fieldEditModel, currentMode: .add, sceneType: fieldEditModel.sceneType, baseContext: baseContext)
            }
        case .exit:
            editController?.dismiss(animated: true)
            operationController?.dismiss(animated: true)
            editController = nil
            operationController = nil
        case .updateData:
            //更新操作面板数据
            operationController?.updateUI(fieldEditModel: fieldEditModel)
            editController?.updateUI(fieldEditModel: fieldEditModel)
        case .openEditPage:
            //直接打开编辑面板
            if shouldPresentEditVC {
                let baseContext = BaseContextImpl(baseToken: fieldEditModel.baseId, service: self, permissionObj: permissionObj, from: "openEditField")
                presentBTFieldEditController(fieldEditModel: fieldEditModel, currentMode: .edit, sceneType: fieldEditModel.sceneType, baseContext: baseContext)
            }
        }
    }

    func presentBTFieldOperationController(fieldEditModel: BTFieldEditModel, baseContext: BaseContext) {
        guard let browseVC = navigator?.currentBrowserVC as? BrowserViewController else { return }
        let traceOpenBlock = { [weak self] in
            guard let self = self else { return }
            let fieldTypeString = fieldEditModel.fieldTrackName
            self.trackBitableFieldEditEvent(eventType: .bitableFieldOperateView,
                                            params: ["field_type": fieldTypeString,
                                                     "has_description": fieldEditModel.fieldDesc?.content?.isEmpty ?? false,
                                                     "is_index_column": fieldEditModel.fieldIndex == 0],
                                            fieldEditModel: fieldEditModel)
        }

        //打开操作面板数据
        guard let containerView = ui?.editorView else { return }
        let operationVC = BTFieldOperationController(fieldEditModel: fieldEditModel,
                                                     hostDocsInfo: UserScopeNoChangeFG.YY.bitableReferPermission ? self.model?.hostBrowserInfo.docsInfo : browseVC.docsInfo,
                                                     hostVC: browseVC,
                                                     baseContext: baseContext)
        operationVC.spaceFollowAPIDelegate = (self.navigator?.currentBrowserVC as? BrowserViewController)?.spaceFollowAPIDelegate

        var extraDismissBlock = {}

        operationVC.delegate = self
        operationVC.viewDidDismissBlock = { [weak self] in
            guard let self = self else { return }
            extraDismissBlock()
            self.operationController = nil
            //退出操作面板通知前端，用来清除前端存储的数据
            self.model?.jsEngine.callFunction(self.modifyFieldCallback, params: nil, completion: nil)
        }

        let isRegularSize = containerView.isMyWindowRegularSize() && SKDisplay.pad
        if isRegularSize {
            // 由于是指向WebView中的元素，没有具体的sourceView，使用一个替代的View覆盖在其上面
            let targetRect = CGRect(x: fieldEditModel.position.x,
                                    y: fieldEditModel.position.y,
                                    width: fieldEditModel.position.width,
                                    height: fieldEditModel.position.height)

            let tempTargetView = UIView(frame: targetRect)
            tempTargetView.backgroundColor = .clear
            containerView.addSubview(tempTargetView)
            tempTargetView.snp.makeConstraints { (make) in
                make.left.equalTo(containerView.safeAreaLayoutGuide.snp.left).offset(targetRect.minX)
                make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top).offset(targetRect.minY)
                make.height.equalTo(targetRect.height)
                make.width.equalTo(targetRect.width)
            }
            operationVC.modalPresentationStyle = .popover
            operationVC.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            operationVC.popoverPresentationController?.sourceView = tempTargetView
            operationVC.popoverPresentationController?.sourceRect = tempTargetView.bounds
            operationVC.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            operationVC.popoverPresentationController?.delegate = operationVC
            operationVC.preferredContentSize = CGSize(width: 375, height: 466)
            extraDismissBlock = {
                tempTargetView.removeFromSuperview()
            }
            safePresent { [weak self] in
                Navigator.shared.present(operationVC, from: UIViewController.docs.topMost(of: browseVC) ?? browseVC, completion: {
                    self?.operationController = operationVC
                    traceOpenBlock()
                })
            }
        } else {
            operationVC.updateLayoutWhenSizeClassChanged = false
            let nav = SKNavigationController(rootViewController: operationVC)
            nav.modalPresentationStyle = .overFullScreen
            nav.update(style: .clear)
            nav.transitioningDelegate = operationVC.panelTransitioningDelegate
            safePresent { [weak self] in
                Navigator.shared.present(nav, from: UIViewController.docs.topMost(of: browseVC) ?? browseVC, completion: {
                    self?.operationController = operationVC
                    traceOpenBlock()
                })
            }
        }
    }

    func requestCommomData(fieldEditModel: BTFieldEditModel,
                           completion: (() -> Void)? = nil) {
        fieldEditBag = DisposeBag()
        //级联选项需要
        // linkTable和本表是否是同一张表
        let linkTableIsCurrentTable = fieldEditModel.tableId == fieldEditModel.fieldProperty.optionsRule.targetTable
        // 请求本表数据
        let fieldListObserver = rxGetBTCommonData(type: .getFieldList,
                                                  fieldEditModel: fieldEditModel,
                                                  tableID: fieldEditModel.tableId,
                                                  viewID: fieldEditModel.viewId)
        // 请求linkTable数据
        let linkTableFieldListObserver = rxGetBTCommonData(type: .getFieldList,
                                                           fieldEditModel: fieldEditModel,
                                                           tableID: fieldEditModel.fieldProperty.optionsRule.targetTable)
        
        
        let fieldMetaObserver = rxGetBTCommonData(type: .getFieldConfigMeta,
                                                  fieldEditModel: fieldEditModel,
                                                  tableID: fieldEditModel.tableId,
                                                  viewID: fieldEditModel.viewId,
                                                  fieldID: fieldEditModel.fieldId)
        let colorListObserver = rxGetBTCommonData(type: .colorList,
                                                  fieldEditModel: fieldEditModel,
                                                  tableID: fieldEditModel.tableId)
        let tableNameObserver = rxGetBTCommonData(type: .getTableNames,
                                                  fieldEditModel: fieldEditModel,
                                                  tableID: fieldEditModel.tableId)
        if linkTableIsCurrentTable {
            // 本表和linkTable是同一张表, 本表数据即linkTable数据，不用多发一次请求
            Observable.zip(colorListObserver,
                           fieldMetaObserver,
                           fieldListObserver,
                           tableNameObserver,
                           filterOptionsSubject)
                .bind { _, _, _, _, _ in
                    completion?()
                }
                .disposed(by: fieldEditBag)
        } else {
            Observable.zip(colorListObserver,
                           fieldMetaObserver,
                           fieldListObserver,
                           linkTableFieldListObserver,
                           tableNameObserver,
                           filterOptionsSubject)
                .bind { _, _, _, _, _, _ in
                    completion?()
                }
                .disposed(by: fieldEditBag)
        }
        getFilterOptionsIfNeed(fieldEditModel)
    }
    
    func getFilterOptionsIfNeed(_ fieldEditModel: BTFieldEditModel) {
        let isLinkNeed = fieldEditModel.compositeType.classifyType == .link
        if isLinkNeed {
            DocsLogger.btInfo("[LinkField] requestFilterOptions")
            let baseData = BTBaseData(baseId: fieldEditModel.fieldProperty.baseId,
                                      tableId: fieldEditModel.fieldProperty.tableId,
                                      viewId: fieldEditModel.viewId)
            requestFilterOptions(baseData: baseData)
        } else {
            filterOptionsSubject.onNext(true)
        }
    }
    
    private func rxGetBTCommonData(type: BTEventType,
                                   fieldEditModel: BTFieldEditModel,
                                   tableID: String?,
                                   viewID: String? = nil,
                                   fieldID: String? = nil,
                                   extraParams: [String: Any]? = [:]) -> Observable<Bool> {
        var requestParams: [String: Any] = [:]
        
        if let tableID = tableID {
            requestParams["tableID"] = tableID
        }
        
        if let viewID = viewID {
            requestParams["viewID"] = viewID
        }
        
        if let fieldID = fieldID {
            requestParams["fieldID"] = fieldID
        }
        
        if let extraParams = extraParams {
            requestParams["extraParams"] = extraParams
        }
        
        return Observable<Bool>.create({ [weak self] (ob) -> Disposable in
            guard let self = self else {
                ob.onNext(true)
                return Disposables.create()
            }
            
            guard self.shouldGetBTCommonData(type: type, fieldEditModel: fieldEditModel) else {
                ob.onNext(true)
                return Disposables.create()
            }
            let args = BTGetBitableCommonDataArgs(type: type, tableID: tableID, viewID: viewID, fieldID: fieldID, extraParams: extraParams)
            self.getBitableCommonData(args: args) { result, error in
                if let error = error {
                    ob.onNext(true)
                    DocsLogger.btError("fieldEdit getBTCommonData failed type:\(type.rawValue) error:\(error)")
                    return
                }
                
                DocsLogger.btInfo("fieldEdit getBTCommonData success type:\(type.rawValue)")
                self.handleBTCommonData(type: type,
                                        fieldEditModel: fieldEditModel,
                                        requestParams: requestParams,
                                        data: result)
                ob.onNext(true)
            }
            return Disposables.create()
        })
    }
    
    private func shouldGetBTCommonData(type: BTEventType, fieldEditModel: BTFieldEditModel) -> Bool {
        switch type {
        case .colorList:
            return btCommonData.colorList.isEmpty
        case .getFieldList:
            return fieldEditModel.compositeType.classifyType == .option && fieldEditModel.fieldProperty.optionsType == .dynamicOption
        default:
            return true
        }
    }
    
    private func handleBTCommonData(type: BTEventType,
                                    fieldEditModel: BTFieldEditModel,
                                    requestParams: [String: Any],
                                    data: Any?) {
        switch type {
        case .colorList:
            guard let dataDic = data as? [String: Any],
                  let resultData = dataDic["ColorList"] as? [[String: Any]],
                  let colorList = [BTColorModel].deserialize(from: resultData) else {
                DocsLogger.btError("fieldEdit getColorList decode error")
                return
            }
            
            self.btCommonData.colorList = colorList.compactMap({ $0 })
        case .getFieldConfigMeta:
            guard let dataDic = data as? [String: Any],
                  let fieldItems = BTFieldConfigItem.deserialize(from: dataDic) else {
                DocsLogger.btError("fieldEdit getFieldConfigMeta decode error")
                return
            }

            self.btCommonData.fieldConfigItem = fieldItems
        case .getTableNames:
            guard let dataDic = data as? [[String: Any]],
                  let tableNames = [BTFieldRelatedForm].deserialize(from: dataDic)?.compactMap({ $0 }) else {
                DocsLogger.btError("fieldEdit getTableNames decode error")
                return
            }
            
            self.btCommonData.tableNames = tableNames
        case .getFieldList:
            //区分是请求的是哪张表的字段列表
            guard let dataDic = data as? [[String: Any]],
                  var fieldOperators = [BTFieldOperatorModel].deserialize(from: dataDic)?.compactMap({ $0 }) else {
                DocsLogger.btError("fieldEdit currentTable getFieldList decode error")
                return
            }
            
            fieldOperators = fieldOperators.filter({ !$0.isRemoteCompute || $0.compositeType.classifyType != .link })
            
            if let tableId = requestParams["tableID"] as? String {
                if tableId == fieldEditModel.tableId {
                    self.btCommonData.currentTableFieldOperators = fieldOperators
                }
                
                if tableId == fieldEditModel.fieldProperty.optionsRule.targetTable {
                    self.btCommonData.linkTableFieldOperators = fieldOperators
                }
            }
        default:
            break
        }
    }
    
    private func requestFilterOptions(baseData: BTBaseData) {
        guard let jsService = self.model?.jsEngine else {
            self.filterOptionsSubject.onNext(true)
            return
        }
        let filterService = BTFilterDataService(baseData: baseData, jsService: jsService, dataService: self)
        filterService.getFieldFilterOptions().subscribe {[weak self]  event in
            guard let self = self else { return }
            switch event {
            case .success(let options):
                DocsLogger.btInfo("[LinkField] get filterOptions success")
                self.btCommonData.filterOptions = options
                self.filterOptionsSubject.onNext(true)
            case .error(let error):
                DocsLogger.btError("[LinkField] getFieldFilterOptions is nil, error: \(error)")
                self.filterOptionsSubject.onNext(true)
            @unknown default:
                return
            }
        }.disposed(by: self.bag)
    }

    func presentBTFieldEditController(fieldEditModel: BTFieldEditModel, currentMode: BTFieldEditMode, sceneType: String, baseContext: BaseContext) {
        let openEditViewBlock = {
            var fieldCommonData = self.btCommonData
            if !fieldEditModel.configurableFieldTypeList.isEmpty {
                let configurableCompositeTypeList = fieldEditModel.configurableFieldTypeList.map { $0.compositeType }
                fieldCommonData.fieldConfigItem.fieldItems = fieldCommonData.fieldConfigItem.fieldItems
                    .compactMap({ $0 })
                    .filter({ configurableCompositeTypeList.contains($0.compositeType) })
            }
            fieldCommonData.hostDocsInfos = self.model?.hostBrowserInfo.docsInfo
            let editVC = BTFieldEditController(fieldEditModel: fieldEditModel,
                                               commonData: fieldCommonData,
                                               currentMode: currentMode,
                                               sceneType: sceneType,
                                               baseContext: baseContext,
                                               dataService: self)

            guard let browseVC = self.navigator?.currentBrowserVC else { return }

            let nav = SKNavigationController(rootViewController: editVC)

            if SKDisplay.phone, UIApplication.shared.statusBarOrientation.isLandscape {
                //iOS12的机型，在横屏情况下使用formSheet模式，会自动转到竖屏
                //https://meego.feishu.cn/larksuite/issue/detail/4548430
                print("presentBTFieldEditController isLandscape")
                nav.modalPresentationStyle = .overFullScreen
            } else {
                nav.modalPresentationStyle = .formSheet
            }

            nav.presentationController?.delegate = editVC
            editVC.delegate = self
            
            let actionType = editVC.actionTypeStringForTracking

            self.safePresent { [weak self] in
                Navigator.shared.present(nav, from: UIViewController.docs.topMost(of: browseVC) ?? browseVC, completion: {
                    guard let self = self else { return }
                    let fieldTypeString = fieldEditModel.fieldTrackName
                    self.operationController?.dismiss(animated: true)
                    self.editController = editVC
                    var params: [String: Any] = [
                        "field_type": fieldTypeString,
                        "is_index_column": fieldEditModel.fieldIndex == 0 ? "true" : "false",
                        "action_type": actionType,
                        "scene_type": sceneType,
                        "is_extend": fieldEditModel.fieldExtendInfo != nil ? "true" : "false"
                    ]
                    if let extInfo = fieldEditModel.fieldExtendInfo {
                        params["extend_field_type"] = extInfo.extendInfo.extendFieldType
                        params["extend_from_field_type"] = extInfo.extendInfo.originFieldUIType.fieldTrackName
                    }
                    self.trackBitableFieldEditEvent(eventType: .bitableFieldModifyView,
                                                    params: params,
                                                    fieldEditModel: fieldEditModel)
                })
            }
        }

        requestCommomData(fieldEditModel: fieldEditModel, completion: openEditViewBlock)
    }

    func presentFieldGroupSetController(fieldEditModel: BTFieldEditModel) {
        guard let browseVC = self.navigator?.currentBrowserVC else { return }
        let groupVC = BTFieldGroupingSetAnimateViewController(fieldEditModel: fieldEditModel,
                                                              hostVC: browseVC,
                                                              reportCommonParams: getBitableFieldEditCommonTrackParams(fieldEditModel: fieldEditModel))
        groupVC.delegate = self
        groupVC.automaticallyAdjustsPreferredContentSize = false
        let nav = SKNavigationController(rootViewController: groupVC)


        let isRegularSize = browseVC.isMyWindowRegularSize() && SKDisplay.pad
        if isRegularSize {
            nav.modalPresentationStyle = .formSheet
            nav.preferredContentSize = CGSize(width: 540, height: 620)
        } else {
            groupVC.updateLayoutWhenSizeClassChanged = false
            nav.modalPresentationStyle = .overFullScreen
            nav.update(style: .clear)
            nav.transitioningDelegate = groupVC.panelTransitioningDelegate
        }

        safePresent {
            Navigator.shared.present(nav, from: UIViewController.docs.topMost(of: browseVC) ?? browseVC, completion: {})
        }
    }
}

extension BTJSService: BTFieldOperationDelegate {
    func didClickOperationButton(action: BTOperationType, fieldEditModel: BTFieldEditModel, baseContext: BaseContext) {
        let fieldTypeTracing = fieldEditModel.fieldTrackName
        var params: [String: Any] = ["click": action.trackingString,
                                     "target": "none"]
        if action == .modifyField {
            params["target"] = "ccm_bitable_field_modify_view"
            params["field_type"] = fieldTypeTracing
        } else if action == .copyField ||
                    action == .positiveSort ||
                    action == .reverseSort {
            params["field_type"] = fieldTypeTracing
            params["is_index_column"] = fieldEditModel.fieldIndex == 0
        } else if action == .deleteField {
            params["field_type"] = fieldTypeTracing
            params["is_index_column"] = fieldEditModel.fieldIndex == 0
            params["target"] = "ccm_bitable_field_delete_view"
        } else if action == .selectStatType {
            params["target"] = "ccm_bitable_statistics_method_modify_view"
            params["field_type"] = fieldTypeTracing
            params["statistics_type"] = fieldEditModel.statTypeId
        }

        trackBitableFieldEditEvent(eventType: .bitableFieldOperateViewClick,
                                   params: params,
                                   fieldEditModel: fieldEditModel)
        self.operationController?.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            switch action {
            case .modifyField:
                self.presentBTFieldEditController(fieldEditModel: fieldEditModel, currentMode: .edit, sceneType: "grid_board", baseContext: baseContext)
            case .selectStatType:
                self.presentFieldGroupSetController(fieldEditModel: fieldEditModel)
            case .unknown:
                break
            default:
                self.model?.jsEngine.callFunction(self.modifyFieldCallback,
                                                  params: ["fieldId": fieldEditModel.fieldId,
                                                           "action": action.rawValue], completion: nil)
            }
        }
    }

    func trackOperationViewEvent(eventType: DocsTracker.EventType,
                                 params: [String: Any],
                                 fieldEditModel: BTFieldEditModel) {
        trackBitableFieldEditEvent(eventType: eventType,
                                   params: params,
                                   fieldEditModel: fieldEditModel)
    }
}

extension BTJSService: BTFieldEditDelegate {
    func editViewDidDismiss() {
        self.editController = nil
        self.btCommonData.tableNames.removeAll()
        self.btCommonData.linkTableFieldOperators.removeAll()
        self.btCommonData.currentTableFieldOperators.removeAll()
        self.fieldEditBag = DisposeBag()
    }

    func trackEditViewEvent(eventType: DocsTracker.EventType,
                            params: [String: Any],
                            fieldEditModel: BTFieldEditModel) {
        trackBitableFieldEditEvent(eventType: eventType,
                                   params: params,
                                   fieldEditModel: fieldEditModel)
    }
    
    func startMontiorEditor() {
        guard let browseVC = navigator?.currentBrowserVC as? BitableBrowserViewController else {
            DocsLogger.btError("Error: can not get currentBrowserVC")
            return
        }
        
        guard let editor = browseVC.browerEditor, let editorSuperView = editor.superview  else {
            DocsLogger.btError("Error: can not get editor View or editor superview")
            return
        }
        
        self.editorObserver = editorSuperView.observe(\.bounds, options: [.new], changeHandler: { [weak self] _, _ in
            guard let self = self else { return }
            let height: CGFloat = editor.convert(editor.bounds, to: browseVC.view).minY
            self.maskView.snp.remakeConstraints { make in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(height)
            }
        })
    }
    
    // 为AI 配置面板上方添加一个 maskView
    func addMaskViewForAiForm(animate: Bool = true) {
        
        guard let browseVC = navigator?.currentBrowserVC as? BitableBrowserViewController else {
            DocsLogger.btError("Error: can not get currentBrowserVC")
            return
        }
        
        guard let editor = browseVC.browerEditor else {
            DocsLogger.btError("Error: can not get editor View or editor superview")
            return
        }
        
        // AI 打开时隐藏 BlockCatalogue
        browseVC.container.setBlockCatalogueHidden(blockCatalogueHidden: true)
        browseVC.view.addSubview(maskView)
        
        if UserScopeNoChangeFG.QYK.btAIMaskViewFixDisable {
            // 默认不再监控editor的bounds
            startMontiorEditor()
        }
        
        let height: CGFloat = editor.convert(editor.bounds, to: browseVC.view).minY
        maskView.snp.remakeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(height)
        }
        
        maskView.backgroundColor = .clear
        browseVC.statusBar.isHidden = true
        
        if animate {
            UIView.animate(withDuration: 0.25, animations: {
                self.maskView.backgroundColor = UDColor.bgMask
            })
        } else {
            self.maskView.backgroundColor = UDColor.bgMask
        }
        
    }
    
    // 将AI 配置面板上方的 maskView 移除
    func removeMaskViewForAiForm() {
        guard let browseVC = navigator?.currentBrowserVC as? BrowserViewController else {
            DocsLogger.btError("Error: can not get currentBrowserVC")
            return
        }
        browseVC.statusBar.isHidden = false
        
        if maskView.superview != nil {
            maskView.removeFromSuperview()
        }
        self.editorObserver = nil
    }
    
}

extension BTJSService: BTFieldGroupingSetAnimateViewControllerDelegate {
    func didOpenSetView(fieldEditModel: BTFieldEditModel) {
        //页面打开埋点上报
        let fieldTypeString = fieldEditModel.fieldTrackName
        trackBitableFieldEditEvent(eventType: .bitableStatisticsMethodModifyView,
                                   params: ["field_type": fieldTypeString,
                                            "is_index_column": fieldEditModel.fieldIndex == 0,
                                            "statstics_type": fieldEditModel.statTypeId],
                                   fieldEditModel: fieldEditModel)
    }
}


extension BTJSService {
    // 字段编辑埋点公参
    func getBitableFieldEditCommonTrackParams(fieldEditModel: BTFieldEditModel) -> [String: Any] {
        guard let browseVC = navigator?.currentBrowserVC as? BrowserViewController,
              let docsInfo = browseVC.docsInfo else { return [:] }
        return BTEventParamsGenerator.createCommonParams(by: docsInfo, baseData: fieldEditModel)
    }

    func trackBitableFieldEditEvent(eventType: DocsTracker.EventType,
                                    params: [String: Any],
                                    fieldEditModel: BTFieldEditModel) {
        var parameters = getBitableFieldEditCommonTrackParams(fieldEditModel: fieldEditModel)
        parameters.merge(other: params)
        DocsTracker.newLog(enumEvent: eventType, parameters: parameters)
    }
}
