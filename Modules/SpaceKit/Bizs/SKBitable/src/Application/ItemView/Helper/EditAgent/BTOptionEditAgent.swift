// 
// Created by duanxiaochen.7 on 2020/3/25.
// Affiliated with DocsSDK.
// 
// Description:

import Foundation
import RxSwift
import RxCocoa
import SKBrowser
import SKFoundation
import SKResource
import SKCommon
import UIKit

final class BTOptionEditAgent: BTBaseEditAgent {

    private weak var gestureManager: BTPanGestureManager!

    private var isSingle: Bool = false

    private var panel: BTOptionPanel?

    override var editingPanelRect: CGRect {
        guard let panel = panel else {
            return .zero
        }
        return panel.convert(panel.bounds, to: inputSuperview)
    }

    private let disposeBag = DisposeBag()

    let updateOptionPanelSubject = PublishSubject<([BTOptionModel]?, String?)>()
    private var dynamicOptions: [BTOptionModel] = []

    private lazy var cancelBtn: UIButton = UIButton(type: .custom).construct { (it) in
        it.rx.tap.subscribe(onNext: { [weak self]_ in
            self?.stopEditing(immediately: false)
        })
        .disposed(by: disposeBag)
    }
    

    init(fieldID: String, recordID: String, gestureManager: BTPanGestureManager!, isSingle: Bool) {
        super.init(fieldID: fieldID, recordID: recordID)
        self.gestureManager = gestureManager
        self.isSingle = isSingle
    }

    override func updateInput(fieldModel: BTFieldModel) {
        super.updateInput(fieldModel: fieldModel)
        panel?.updatePanel(fieldModel: fieldModel, dynamicOptions: dynamicOptions)
        guard let editingField = relatedVisibleField else { return }
        let isDynamicOptions = editingField.fieldModel.property.optionsType == .dynamicOption
        if isDynamicOptions {
            //前端协同数据更新，需要重新拉取级联数据
            getDynamicOptions()
        }
        coordinator?.currentCard?.panelDidStartEditingField(editingField, scrollPosition: .bottom)
    }

    override var editType: BTFieldType { .multiSelect }

    override func startEditing(_ cell: BTFieldCellProtocol) {
        guard let coordinator = coordinator, let bindField = cell as? BTFieldOptionCellProtocol else { return }
        coordinator.currentCard?.keyboard.stop()
        //所有的选项颜色
        let colors = bindField.fieldModel.colors
        let selectedOptionIDs = bindField.fieldModel.optionIDs
        let allOptions = bindField.fieldModel.property.options

        panel = BTOptionPanel(
            delegate: self,
            gestureManager: gestureManager,
            isSingle: isSingle,
            isDynamicOptions: bindField.fieldModel.property.optionsType == .dynamicOption,
            hostVC: coordinator.attachedController,
            colors: colors,
            optionModel: BTUtil.getAllOptions(with: selectedOptionIDs, colors: colors, allOptionInfos: allOptions),
            selectedModel: BTUtil.getSelectedOptions(withIDs: selectedOptionIDs, colors: colors, allOptionInfos: allOptions),
            superViewBottomOffset: coordinator.inputSuperviewDistanceToWindowBottom
        )
        guard let panel = panel else { return }

        inputSuperview.addSubview(cancelBtn)
        inputSuperview.addSubview(panel)
        panel.snp.makeConstraints { it in
            it.top.equalTo(inputSuperview.bounds.height)
            it.bottom.equalTo(inputSuperview.snp.bottom)
            it.left.right.equalToSuperview()
        }
        cancelBtn.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(panel.snp.top)
        }
        
        inputSuperview.layoutIfNeeded()
        UIView.animate(withDuration: 0.25, animations: { [self] in
            panel.snp.updateConstraints { it in
                it.top.equalTo(inputSuperview.bounds.height - panel.initViewHeight)
            }
            inputSuperview.layoutIfNeeded()
        }, completion: { [weak self] (finish) in
            if finish {
                bindField.panelDidStartEditing()
                if bindField.fieldModel.property.optionsType == .dynamicOption {
                    panel.startLoadingTimer()
                    self?.startOptionModelUpdateObserver()
                    self?.getDynamicOptions()
                }
                //打开选项面板事件上报
                self?.editHandler?.trackEvent(eventType: DocsTracker.EventType.bitableOptionFieldPanelOpen.rawValue, params: [:])
            }
        })
    }

    override func stopEditing(immediately: Bool, sync: Bool = false) {
        panel?.stopEditing()
        let bindField = relatedVisibleField as? BTFieldOptionCellProtocol
        var needScroll = false
        if let bindField = bindField,
           let cellRect = coordinator?.currentCard?.getCellRect(cell: bindField) {
            needScroll = cellRect.minY < (coordinator?.currentCard?.getHeaderViewFrame().height ?? 0)
        }
        //选项面板过高导致选项field的字段名不可见，当下的选项面板时需要把选项字段名滚动到可视位置
        bindField?.stopEditing(scrollPosition: needScroll ? .top : nil)
        cancelBtn.removeFromSuperview()

        guard panel?.superview != nil else { return }
        if immediately {
            panel?.removeFromSuperview()
            panel = nil
        } else {
            UIView.animate(
                withDuration: 0.25,
                animations: {
                    self.panel?.snp.remakeConstraints { it in
                        it.top.equalTo(self.inputSuperview.snp.bottom)
                        it.left.right.equalToSuperview()
                    }
                    self.inputSuperview.layoutIfNeeded()
                },
                completion: { finish in
                    if finish {
                        self.panel?.removeFromSuperview()
                        self.panel = nil
                    }
                }
            )
        }
        baseDelegate?.didCloseEditPanel(self, payloadParams: nil)
        coordinator?.invalidateEditAgent()
        coordinator?.currentCard?.keyboard.start()
    }

    private func startOptionModelUpdateObserver() {
        updateOptionPanelSubject
            .observeOn(MainScheduler.instance)
            .throttle(DispatchQueueConst.MilliSeconds_250, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (models, errorMsg) in
                guard let self = self,
                      let bindField = self.relatedVisibleField as? BTFieldOptionCellProtocol else {
                    return
                }

                guard bindField.fieldModel.property.optionsType == .dynamicOption else { return }

                guard let models = models else {
                    DocsLogger.btError("field edit getOptions failed errorMessage:\(String(describing: errorMsg))")
                    self.panel?.showEmptyView(text: BundleI18n.SKResource.Bitable_Mobile_CannotEditOption, type: .noContent)
                    return
                }

                self.dynamicOptions = models

                self.panel?.updatePanel(fieldModel: bindField.fieldModel, dynamicOptions: models)
                if models.isEmpty {
                    self.panel?.showEmptyView(text: BundleI18n.SKResource.Bitable_Mobile_CannotEditOption, type: .noContent)
                }
            }).disposed(by: disposeBag)
    }
}


extension BTOptionEditAgent: BTOptionPanelDelegate {
    func optionSelectionChanged(to models: [BTCapsuleModel], isSingleSelect: Bool, trackInfo: BTTrackInfo) {
        editHandler?.optionSelectionChanged(fieldID: fieldID,
                                            options: models,
                                            isSingleSelect: isSingleSelect,
                                            trackInfo: trackInfo)
        if isSingle {
            stopEditing(immediately: false)
        }
    }

    func scrollTillFieldVisible() {
        guard let field = relatedVisibleField else { return }
        coordinator?.currentCard?.scrollTillFieldBottomIsVisible(field)
    }

    func trackOptionFieldEvent(event: String, params: [String: Any]) {
        editHandler?.trackEvent(eventType: event, params: params)
    }

    func hideView() {
        stopEditing(immediately: false)
    }

    func executeCommands(command: BTCommands,
                         property: Any?,
                         extraParams: Any?,
                         resultHandler: @escaping (BTExecuteFailReson?, Error?) -> Void) {
        guard let field = relatedVisibleField else { return }
        editHandler?.executeCommands(command: command,
                                     field: field,
                                     property: property,
                                     extraParams: extraParams,
                                     resultHandler: resultHandler)
    }

    func getBitableCommonData(type: BTEventType, resultHandler: @escaping (Any?, Error?) -> Void) {
        editHandler?.getBitableCommonData(type: type,
                                          fieldID: fieldID,
                                          extraParams: ["total": 1],
                                          resultHandler: resultHandler)
    }

    func getFieldPermission(entity: String,
                            operation: OperationType,
                            resultHandler: @escaping (Any?, Error?) -> Void) {
        editHandler?.getPermissionData(entity: entity,
                                       operation: operation,
                                       recordID: nil,
                                       fieldIDs: [fieldID],
                                       resultHandler: resultHandler)
    }

    func getDynamicOptions() {
        guard let bindField = relatedVisibleField as? BTFieldOptionCellProtocol else { return }
        editHandler?.asyncJsRequest(router: .getBitableFieldOptions,
                                    data: ["fieldId": fieldID,
                                           "senceType": bindField.fieldModel.isInForm ? "form" : "record"],
                                    overTimeInterval: nil,
                                    responseHandler: responseHandler,
                                    resultHandler: nil)
    }

    private func responseHandler(result: Result<BTAsyncResponseModel, BTAsyncRequestError>) {
        guard let bindField = self.relatedVisibleField as? BTFieldOptionCellProtocol else {
            DocsLogger.btError("[BTAsyncRequest] BTOptionEditAgent bindField is not BTOptionField")
            return
        }

        guard bindField.fieldModel.property.optionsType == .dynamicOption else {
            DocsLogger.btError("[BTAsyncRequest] BTOptionEditAgent currentField is not dynamicOption")
            return
        }

        guard let panel = panel else {
            DocsLogger.btError("[BTAsyncRequest] BTOptionEditAgent failed panel is closed")
            return
        }

        //前端异步请求回调
        switch result {
        case .success(let data):
            handleAsyncResponse(data: data)
        case .failure(let error):
            if error.code == .requestTimeOut {
                panel.hideLoading()
                panel.showTryAgainEmptyView(text: BundleI18n.SKResource.Bitable_SingleOption_ReloadTimeoutRetry(BundleI18n.SKResource.Bitable_Common_ButtonRetry),
                                                   type: .searchFailed,
                                                   tryAgainBlock: { [weak self] in
                    panel.showLoading()
                    self?.getDynamicOptions()
                })
            } else {
                updateOptionPanelSubject.onNext((nil, error.description))
            }
            DocsLogger.btError("[BTAsyncRequest] BTOptionEditAgent failed error:\(error.description))")
        }
    }

    private func handleAsyncResponse(data: BTAsyncResponseModel) {
        panel?.hideLoading()
        guard data.result == 0 else {
            DocsLogger.btError("[BTAsyncRequest] BTOptionEditAgent failed data:\(data.toJSONString() ?? "")")
            updateOptionPanelSubject.onNext((nil, data.errorResult))
            return
        }

        guard let optionData = data.data["options"] as? [[String: Any]],
              let options = [BTOptionModel].deserialize(from: optionData)?.compactMap({ $0 }) else {
            DocsLogger.btError("[BTAsyncRequest] BTOptionEditAgent failed optionData isEmpty data:\(data.toJSONString() ?? "")")
            updateOptionPanelSubject.onNext((nil, nil))
            return
        }

        updateOptionPanelSubject.onNext((options, nil))
    }
}
