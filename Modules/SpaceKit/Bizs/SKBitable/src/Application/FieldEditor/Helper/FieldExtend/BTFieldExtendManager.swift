//
//  BTFieldExtendManager.swift
//  SKBitable
//
//  Created by zhysan on 2023/4/14.
//

import SKFoundation

struct BTFieldExtConst {
    static let logTag = "==BTEXT=="
}

protocol BTFieldExtendManagerDelegate: AnyObject {
    func managerDidUpdateExtendInfo(_ manager: BTFieldExtendManager)
    func managerDidUpdateExtendableFields(_ manager: BTFieldExtendManager)
    func managerDidFinishRefreshExtendData(_ manager: BTFieldExtendManager, error: Error?)
}

struct ExtraExtendDisableReason: OptionSet {
    let rawValue: Int
    
    static let notSupportMultiple = ExtraExtendDisableReason(rawValue: 1 << 0)
}

class BTFieldExtendManager {
    
    // MARK: - public
    
    weak var delegate: BTFieldExtendManagerDelegate?
    
    private(set) var extendConfigs: FieldExtendConfigs?
    
    private(set) var extendableFields: ExistExtendableFields?
    
    let editMode: BTFieldEditMode
    
    let allowEditModes: AllowedEditModes = {
        var modes = AllowedEditModes()
        modes.manual = false
        return modes
    }()
    
    // MARK: - life cycle
    
    init(editMode: BTFieldEditMode, service: BTDataService?, delegate: BTFieldExtendManagerDelegate? = nil) {
        self.editMode = editMode
        self.service = service
        self.delegate = delegate
    }
    
    // MARK: -
    
    func resetFieldExtendContext() {
        extendConfigs = nil
        clearOperations()
    }

    func asyncUpdateFieldExtendConfigs(editModel: BTFieldEditModel) {
        let tableId = editModel.tableId
        let fieldId = editModel.fieldId
        let baseId = editModel.baseId
        let fieldUIType = editModel.compositeType.uiType
        service?.asyncJsRequest(
            biz: .card,
            funcName: .asyncJsRequest,
            baseId: baseId,
            tableId: tableId,
            params: [
                "tableId": tableId,
                "router": BTAsyncRequestRouter.getFieldExtendInfo.rawValue,
                "data": [
                    "fieldUIType": fieldUIType.rawValue,
                    "fieldId": fieldId
                ]
            ],
            overTimeInterval: 10,
            responseHandler: { [weak self] ret in
                guard let self = self else { return }
                switch ret {
                case .success(let data):
                    DocsLogger.info("request success", component: BTFieldExtConst.logTag)
                    do {
                        let configs = try CodableUtility.decode(FieldExtendConfigs.self, withJSONObject: data.data)
                        self.extendConfigs = configs
                        self.delegate?.managerDidUpdateExtendInfo(self)
                    } catch(let error) {
                        DocsLogger.error("decode failed: \(error)", component: BTFieldExtConst.logTag)
                    }
                case .failure(let error):
                    DocsLogger.error("request failed: \(error)", component: BTFieldExtConst.logTag)
                }
            }, resultHandler: { ret in
                switch ret {
                case .success:
                    DocsLogger.info("call success", component: BTFieldExtConst.logTag)
                case .failure(let error):
                    DocsLogger.error("call failed: \(error)", component: BTFieldExtConst.logTag)
                }
        })
    }
    
    func asyncUpdateExtendableFields(editModel: BTFieldEditModel) {
        let tableId = editModel.tableId
        let fieldId = editModel.fieldId
        let baseId = editModel.baseId
        service?.asyncJsRequest(
            biz: .card,
            funcName: .asyncJsRequest,
            baseId: baseId,
            tableId: tableId,
            params: [
                "tableId": tableId,
                "router": BTAsyncRequestRouter.getExistExtendableFields.rawValue,
                "data": [
                    "excludeFieldId": fieldId,
                ]
            ],
            overTimeInterval: 10,
            responseHandler: { [weak self] ret in
                guard let self = self else { return }
                switch ret {
                case .success(let data):
                    DocsLogger.info("request success", component: BTFieldExtConst.logTag)
                    do {
                        let fields = try CodableUtility.decode(ExistExtendableFields.self, withJSONObject: data.data)
                        self.extendableFields = fields
                        self.delegate?.managerDidUpdateExtendableFields(self)
                    } catch(let error) {
                        DocsLogger.error("decode failed: \(error)", component: BTFieldExtConst.logTag)
                    }
                case .failure(let error):
                    DocsLogger.error("request failed: \(error)", component: BTFieldExtConst.logTag)
                }
            },
            resultHandler: { ret in
                switch ret {
                case .success:
                    DocsLogger.info("call success", component: BTFieldExtConst.logTag)
                case .failure(let error):
                    DocsLogger.error("call failed: \(error)", component: BTFieldExtConst.logTag)
                }
            }
        )
    }
    
    func asyncRefreshFieldExtendData(editModel: BTFieldEditModel) {
        let tableId = editModel.tableId
        let fieldId = editModel.fieldId
        let viewId = editModel.viewId
        let baseId = editModel.baseId
        service?.asyncJsRequest(
            biz:.card,
            funcName: .asyncJsRequest,
            baseId: baseId,
            tableId: tableId,
            params: [
                "tableId": tableId,
                "router": BTAsyncRequestRouter.updateFieldExtendData.rawValue,
                "data": [
                    "fieldId": fieldId,
                    "viewId": viewId,
                ]
            ],
            overTimeInterval: 10,
            responseHandler: { [weak self] ret in
                guard let self = self else { return }
                switch ret {
                case .success:
//                    DocsLogger.info("request success", component: BTFieldExtConst.logTag)
//                    do {
                    self.delegate?.managerDidFinishRefreshExtendData(self, error: nil)
//                    } catch(let error) {
//                        DocsLogger.error("decode failed: \(error)", component: BTFieldExtConst.logTag)
//                    }
                case .failure(let error):
                    self.delegate?.managerDidFinishRefreshExtendData(self, error: error)
                    DocsLogger.error("request failed: \(error)", component: BTFieldExtConst.logTag)
                }
            },
            resultHandler: { ret in
                switch ret {
                case .success:
                    DocsLogger.info("call success", component: BTFieldExtConst.logTag)
                case .failure(let error):
                    DocsLogger.error("call failed: \(error)", component: BTFieldExtConst.logTag)
                }
            }
        )
    }
    
    // MARK: - private
    
    private weak var service: BTDataService?
    
    private var opStore = FieldExtendOperationStore()
}

// MARK: - operation

extension BTFieldExtendManager {
    
    var extendEditParams: [String: Any]? {
        guard !opStore.extendFieldOptions.addFieldOptions.isEmpty || !opStore.extendFieldOptions.deleteFieldOptions.isEmpty else {
            return nil
        }
        let result: [String: Any]?
        do {
            result = try opStore.toJson() as? [String: Any]
        } catch {
            DocsLogger.error("FieldExtendRootOperation parse failed", error: error, component: BTFieldExtConst.logTag)
            result = nil
        }
        return result
    }
    
    func appendExtendConfigItems(_ items: [FieldExtendConfigItem], currentFieldEditInfo: BTFieldEditModel) {
        let options = opStore.extendFieldOptions
        switch editMode {
        case .add:
            items.forEach { item in
                guard !options.addFieldOptions.contains(where: { $0.extendFieldType == item.extendFieldType }) else {
                    return
                }
                options.addFieldOptions.append(
                    FieldExtendOperationStore.AddOption(
                        extendFieldType: item.extendFieldType,
                        originFieldReportType: currentFieldEditInfo.compositeType.uiType.fieldTrackName
                    )
                )
            }
        case .edit:
            items.forEach { item in
                if let idx = options.deleteFieldOptions.firstIndex(where: { $0.extendFieldType == item.extendFieldType }) {
                    options.deleteFieldOptions.remove(at: idx)
                } else if !options.addFieldOptions.contains(where: { $0.extendFieldType == item.extendFieldType }) {
                    options.addFieldOptions.append(
                        FieldExtendOperationStore.AddOption(
                            extendFieldType: item.extendFieldType,
                            originFieldReportType: currentFieldEditInfo.compositeType.uiType.fieldTrackName
                        )
                    )
                } else {
                    DocsLogger.error("invalid operation, add: \(options.addFieldOptions), del: \(options.deleteFieldOptions), append: \(items)")
                    spaceAssertionFailure("invalid operation")
                }
            }
        }
    }
    
    func deleteExtendConfigItems(_ items: [FieldExtendConfigItem]) {
        let options = opStore.extendFieldOptions
        switch editMode {
        case .add:
            items.forEach { item in
                guard let idx = options.addFieldOptions.firstIndex(where: { $0.extendFieldType == item.extendFieldType }) else {
                    return
                }
                options.addFieldOptions.remove(at: idx)
            }
        case .edit:
            items.forEach { item in
                if let idx = options.addFieldOptions.firstIndex(where: { $0.extendFieldType == item.extendFieldType }) {
                    options.addFieldOptions.remove(at: idx)
                } else if !options.deleteFieldOptions.contains(where: { $0.extendFieldType == item.extendFieldType }), let fieldId = item.fieldId {
                    options.deleteFieldOptions.append(.init(extendFieldType: item.extendFieldType, extendFieldId: fieldId))
                } else {
                    DocsLogger.error("invalid operation, add: \(options.addFieldOptions), del: \(options.deleteFieldOptions), delete: \(items)")
                    spaceAssertionFailure("invalid operation")
                }
            }
        }
    }
    
    @discardableResult
    func clearOperations() -> Bool {
        guard !opStore.extendFieldOptions.addFieldOptions.isEmpty || !opStore.extendFieldOptions.addFieldOptions.isEmpty else {
            return false
        }
        opStore.extendFieldOptions.addFieldOptions.removeAll()
        opStore.extendFieldOptions.deleteFieldOptions.removeAll()
        return true
    }
}
