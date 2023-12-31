//
// Created by duanxiaochen.7 on 2020/1/14.
// Affiliated with DocsSDK.
// swiftlint:disable file_length

import Foundation
import UIKit
import EENavigator
import UniverseDesignActionPanel
import SKCommon
import SKBrowser
import SKFoundation
import SKResource
import SKUIKit
import RxSwift
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignFont
import UniverseDesignShadow
import UniverseDesignLoading
import UniverseDesignNotice
import LarkSetting

final class BTRecord: UICollectionViewCell {
    enum Mode {
        case normal
        case indRecord // 独立记录
        case submit    // 记录提交模式
        case invisible
        case form // 表单
        case loading //数据加载中
        case timeOut //数据加载超时
        case stage
        case link // 关联卡片
        
        var isIndRecord: Bool {
            self == .indRecord
        }
        var isInStage: Bool {
            self == .stage
        }
    }
    // MARK: Subviews
    lazy var headerView = BTRecordHeaderView().construct { it in
        it.backgroundColor = UserScopeNoChangeFG.ZJ.btCardReform ? .clear : UDColor.bgBody
        it.delegate = self
    }
    
    // 即将废除的逻辑，请不要再使用
    private lazy var filterView = BTRecordFilterView().construct { it in
        it.backgroundColor = UDColor.functionWarningFillSolid02
        it.delegate = self
    }

    var context: BTContext? {
        didSet {
            fieldsView.context = context
        }
    }
    
    /// iOS 16.5 的 bug https://meego.feishu.cn/larksuite/issue/detail/12890438?#detail
    private var shouldFixScrollIndicatorBug: Bool {
        var settingsArray: [String]?
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "ccm_mobile_system_bugfix"))
            if let systemVersions = settings["scrollIndicatorBugFixSystemVersions"] {
                if let array = systemVersions as? [String] {
                    settingsArray = array
                } else {
                    DocsLogger.error("systemVersions is not string array")
                }
            } else {
                DocsLogger.error("settings has no systemVersions")
            }
        } catch {
            DocsLogger.error("scrollIndicatorBugFixSystemVersions get settings error", error: error)
            return false
        }
        guard let settingsArray = settingsArray else {
            DocsLogger.info("has no settings,not fix system bug")
            return false
        }
        let systemVersion = UIDevice.current.systemVersion
        let va = settingsArray.contains(systemVersion)
        return va
    }
    
    private var recordDetailViewMode: BTViewMode?
        
    private(set) lazy var fieldsView = BTFieldListView(frame: .zero).construct { it in
        it.delegate = self
        it.backgroundColor = UDColor.bgBody
        it.contentInsetAdjustmentBehavior = .never
        it.insetsLayoutMarginsFromSafeArea = false
        if shouldFixScrollIndicatorBug {
            it.showsVerticalScrollIndicator = false
        }
    }

    // Invisible Mode Subview
    private lazy var emptyView = UDEmptyView(config: UDEmptyConfig(titleText: BundleI18n.SKResource.Bitable_Core_RecordDeletedOrNoPerm,
                                                                   font: .systemFont(ofSize: 17),
                                                                   type: .noAuthority)).construct { it in
            it.useCenterConstraints = true
    }
    
    private lazy var timeOutEmptyView = UDEmptyView(config: timeOutEmptyConfig).construct { it in
        // 不用userCenterConstraints会非常不雅观
        it.useCenterConstraints = true
        it.backgroundColor = UDColor.bgFloat
    }
    
    private var timeOutEmptyConfig: UDEmptyConfig = UDEmptyConfig(title: .init(titleText: "",
                                                                               font: .systemFont(ofSize: 14, weight: .regular)),
                                                                  description: .init(descriptionText:
                                                                                        BundleI18n.SKResource.Bitable_SingleOption_ReloadTimeoutRetry(
                                                                                            BundleI18n.SKResource.Bitable_Common_ButtonRetry)
                                                                                    ),
                                                                  imageSize: 100,
                                                                  type: .searchFailed,
                                                                  labelHandler: nil,
                                                                  primaryButtonConfig: nil,
                                                                  secondaryButtonConfig: nil)
    
    private let loadingViewManager = BTLaodingViewManager()
    
    // MARK: - Configurations
    weak var delegate: BTRecordDelegate?
    
    var recordID: String { recordModel.recordID }

    var recordModel: BTRecordModel = BTRecordModel()
    
    private var uiModel: BTRecordModel = BTRecordModel() // 最终UI渲染的model，UI相关操作请用这个

    var topVisibleFieldID: String {
        let visibleIndexPaths = fieldsView.indexPathsForVisibleItems.sorted()
        for indexPath in visibleIndexPaths {
            if let field = fieldsView.cellForItem(at: indexPath) as? BTFieldCellProtocol {
                return field.fieldID
            }
        }
        return ""
    }

    var keyboardHeightInFieldsView: CGFloat = 0

    /// 处理数字字段这种没有 panel 反而用系统键盘的字段，进入编辑时自动滚动到可视区
    /// 如果 panel 内部还有输入框的话，这里的 keyboard 监听可能会引起错误表现，记得在对应的 edit agent 那里暂时 stop 一下
    var keyboard = Keyboard()

    var viewMode: BTRecord.Mode {
        if case .timeOut(_) = recordModel.dataStatus {
            return .timeOut
        } else if recordModel.dataStatus == .loading {
            return .loading
        }
        
        if recordModel.viewMode.isForm {
            return .form
        }
        if recordModel.viewMode == .submit {
            return .submit
        }
        if recordModel.viewMode == .addRecord {
            return .submit
        }
        if recordModel.viewMode.isIndRecord {
            return .indRecord
        }
        if recordModel.viewMode.isStage {
            return .stage
        }
        
        if !recordModel.visible {
            return .invisible
        }
        
        if recordModel.viewMode.isLinkedRecord, UserScopeNoChangeFG.ZJ.btCardReform {
            return .link
        }
        return .normal
    }

    var headerBarColor: UIColor {
        if recordModel.headerBarColor.isEmpty {
            return UDColor.primaryContentDefault
        }
        return UIColor.docs.rgb(recordModel.headerBarColor)
    }

    //卡片切换支持定位，保持跟上张卡片相同的滚动位置
    var currentTopFieldID: String = "" {
        didSet {
            syncTopField()
        }
    }
    
    //超时请求
    var timeOutRequest: BTGetCardListRequest?
    
    var fieldsViewVisible: Bool {
        return viewMode != .loading && viewMode != .timeOut && viewMode != .invisible && !fieldsView.visibleCells.isEmpty
    }
    
    var fieldsViewHasLoaded: Bool = false
    
    //记录滚动偏移量，用来处理多行文本和卡片的滚动冲突
    var latestContenOffset: CGPoint?
    var recordCanScroll: Bool = true
    private let bgView = UIView()
    private var userSelectedStageIndex: Int = -1
    private var isShowLoading: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        if UserScopeNoChangeFG.ZJ.btCardReform {
            self.docsListenToToSubViewResponder = true
            keyboard = Keyboard(listenTo: [self], trigger: "base-itemView")
        }
        keyboard.on(events: [.didShow, .willHide]) { [weak self] (options) in
            self?.handleKeyboard(didTrigger: options.event, options: options)
        }
        keyboard.start()
        if shouldFixScrollIndicatorBug {
            bgView.backgroundColor = UDColor.bgBase
            addSubview(bgView)
            sendSubviewToBack(bgView)
            var topBottomInset = BTCardLayout.Const.cardTopBottomMargin
            var leftRightInset = BTCardLayout.Const.cardLeftRightMargin
            if UserScopeNoChangeFG.ZJ.btCardReform {
                topBottomInset = BTCardLayout.Const.newCardTopBottomMargin
                leftRightInset = BTCardLayout.Const.newCardLeftRightMargin
            }
            
            let inset = UIEdgeInsets(top: topBottomInset,
                                    left: leftRightInset + 10,
                                    bottom: topBottomInset,
                                    right: leftRightInset + 10)
            bgView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(-(inset.top * 1.2 + 84))
                make.left.equalToSuperview().offset(-inset.left / 2.0)
                make.right.equalToSuperview().offset(inset.right / 2.0)
                make.bottom.equalToSuperview().offset(inset.bottom * 1.2 + 56)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        syncTopField()

    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()

        if UserScopeNoChangeFG.ZYS.recordHeaderSafeAreaFixRevertV2 {
            return
        }
        updateHeader()
    }
    
    func resetContentOffset() {
        guard fieldsViewVisible, delegate?.shouldResetContentOffsetForReuse == true else {
            return
        }
        
        fieldsView.contentOffset = .zero
    }

    deinit {
        keyboard.stop()
    }
}

extension BTRecord {

    func loadInitialModel(_ model: BTRecordModel, context: BTContext) {
        if !UserScopeNoChangeFG.ZJ.btItemViewContentOffsetFixDisable,
           recordModel.recordID != model.recordID {
            resetContentOffset()
        }
        
        handleSetRecord(model: model, context: context)

        recordModel = model
        updateRecordAndReload()
        fieldsViewHasLoaded = true

        self.handleSetRecord(model: model, context: context, isEnd: true, isInitial: true)
        DispatchQueue.main.async {
            self.handleRecordTTV(model: model, context: context, bitableReady: self.delegate?.isBitableReady() ?? false)
        }
    }
    
    private func updateRecordAndReload() {
        updateHeader()
        reloadViewMode()
        if viewMode.isInStage {
            let model = getStageUIModel()
            uiModel = model
            fieldsView.load(model, recordModel, fieldsDelegate: self)
        } else {
            updateFilterView()
            uiModel = recordModel
            fieldsView.load(recordModel, recordModel, fieldsDelegate: self)
        }
    }

    private func handleSetRecord(model: BTRecordModel, context: BTContext?, isEnd: Bool = false, isInitial: Bool = false) {
        guard delegate?.currentRecordId() == model.recordID else {
            return
        }
        if hasRecordTTUAndTTV() {
            return
        }
        if let openRecordTraceId = context?.openRecordTraceId, isInitial {
            BTOpenRecordReportHelper.reportTTVNotifyDataChanged(traceId: openRecordTraceId)
            BTOpenRecordReportHelper.reportTTUNotifyDataChanged(traceId: openRecordTraceId)

        }
        if let openBaseTraceId = context?.openBaseTraceId, isInitial {
            BTOpenRecordReportHelper.reportTTVNotifyDataChanged(traceId: openBaseTraceId)
            BTOpenRecordReportHelper.reportTTUNotifyDataChanged(traceId: openBaseTraceId)
        }
        if let traceId = context?.openRecordTraceId {
            BTOpenRecordReportHelper.reportSetRecord(traceId: traceId, end: isEnd)
        }
    }

    private func handleRecordTTV(model: BTRecordModel, context: BTContext, bitableReady: Bool) {
        guard UserScopeNoChangeFG.LYL.enableStatisticTrace else {
            return
        }
        if hasRecordTTUAndTTV() {
            return
        }
        guard delegate?.currentRecordId() == model.recordID else {
            return
        }
        if let traceId = context.openRecordTraceId {
            fieldsView.visibleCells.forEach { cell in
                guard let cell = cell as? BTStatisticRecordProtocol else {
                    return
                }

                BTOpenRecordReportHelper.reportCellDrawTime(
                    traceId: traceId,
                    uiType: cell.fieldModel.extendedType.mockFieldID,
                    drawTime: [cell.drawTime.layout, cell.drawTime.draw],
                    drawCount: [cell.drawCount.layout, cell.drawCount.draw],
                    costTime: cell.drawTime.draw
                )
            }
            BTOpenRecordReportHelper.reportCellListGroup(traceId: traceId)
            BTOpenRecordReportHelper.reportTTV(traceId: traceId)
            if bitableReady {
                BTOpenRecordReportHelper.reportTTU(traceId: traceId)
            }
        }
        if let traceId = context.openBaseTraceId {
            if model.viewMode == .indRecord {
                BTOpenFileReportMonitor.reportOpenShareRecordTTV(traceId: traceId)
                if bitableReady {
                    BTOpenFileReportMonitor.reportOpenShareRecordTTU(traceId: traceId)
                }
            } else if model.viewMode == .form {
                BTOpenFileReportMonitor.reportOpenFormTTV(traceId: traceId)
                if bitableReady {
                    BTOpenFileReportMonitor.reportOpenFormTTU(traceId: traceId)
                }
            }
        }
        delegate?.update(hasTTV: true)
        if bitableReady {
            delegate?.update(hasTTU: true)
        }
    }

    private func hasRecordTTUAndTTV() -> Bool {
        guard let delegate = delegate else {
            return true
        }
        return delegate.hasReportTTU() && delegate.hasReportTTV()
    }

    func updateModel(_ model: BTRecordModel) {
        handleSetRecord(model: model, context: context)

        recordModel = model
        updateHeader()
        reloadViewMode()
        if viewMode.isInStage {
            let model = getStageUIModel()
            uiModel = model
            fieldsView.update(model, recordModel)
        } else {
            uiModel = model
            updateFilterView()
            fieldsView.update(model, recordModel)
        }

        self.handleSetRecord(model: model, context: self.context, isEnd: true)
    }
    
    func updateRecordSubscribeState() {
        updateHeader()
    }
    
    // stage 模式下切换阶段
    func changeStageSelected(index: Int) {
        if UserScopeNoChangeFG.ZJ.btCardReform {
            userSelectedStageIndex = index
            guard let stageField = recordModel.wrappedFields.first(where: { $0.fieldID == recordModel.currentItemViewId }) else {
                return
            }
            
            guard let selectOptionId = getSelectStageOptionId(stageFieldId: stageField.fieldID, selectedStageIndex: index) else {
                return
            }
            
            didChangeStage(stageFieldId: stageField.fieldID, selectOptionId: selectOptionId)
            return
        }
        userSelectedStageIndex = index
        let newModel = getStageUIModel()
        uiModel = newModel
        fieldsView.update(newModel, recordModel)
    }
    
    private func getSelectStageOptionId(stageFieldId: String, selectedStageIndex: Int) -> String? {
        guard let stageField = recordModel.wrappedFields.first(where: { $0.fieldID == stageFieldId }) else {
            return nil
        }
        let filterStages = stageField.property.stages
        
        guard selectedStageIndex < filterStages.count, selectedStageIndex >= 0 else {
            return nil
        }
        
        return filterStages[selectedStageIndex].id
    }
    
    // 获取Stage模式下需要的model
    private func getStageUIModel() -> BTRecordModel {
        // 先处理meta
        var stageField: BTFieldModel?
        
        if UserScopeNoChangeFG.ZJ.btCardReform {
            var fields = recordModel.wrappedFields
            if !UserScopeNoChangeFG.ZJ.btItemViewStageTabsFixDisable {
                fields = recordModel.originalFields
            }
            
            stageField = fields.first(where: { $0.fieldID == recordModel.currentItemViewId })
        } else {
            stageField = recordModel.wrappedFields.first(where: { $0.compositeType.uiType == .stage })
        }

        if var stageField = stageField,
           var primaryField = recordModel.wrappedFields.first(where: { $0.fieldID == recordModel.primaryFieldID }),
           let currentOptionId = stageField.optionIDs.first ?? stageField.property.stages.first?.id,
           let currentOption = stageField.property.stages.first(where: { $0.id == currentOptionId }) ,
           var currentStageIndex = stageField.property.stages.firstIndex(where: { $0.id == currentOptionId }) {
            // 过滤default状态的stage
            let filterStages = stageField.property.stages.filter({ $0.type == .defualt })
            // 处理当前的stage index
            if currentOption.type == .endDone {
                currentStageIndex = filterStages.count - 1
            } else if currentOption.type == .endCancel {
                currentStageIndex = 0
            }
            // 用户选择的index
            if userSelectedStageIndex > filterStages.count - 1 {
                userSelectedStageIndex = filterStages.count - 1
            }
            let selectedIndex = userSelectedStageIndex < 0 ? currentStageIndex : userSelectedStageIndex
            // 用户选择的optionId
            guard selectedIndex >= 0, selectedIndex < filterStages.count else {
                DocsLogger.btError("[Stage Detail] deal record failded")
                return recordModel
            }
            let selectedOptionId = filterStages[selectedIndex].id

            // 处理后的stages
            var dealedStages: [BTStageModel] = []
          
            for (index, stage) in stageField.property.stages.enumerated() {
                var newStage = stage
                switch currentOption.type {
                case .endDone:
                    // 正常结束，所有的阶段都算finish
                    newStage.status = .finish
                case .endCancel:
                    // 取消流程所有的阶段都算pending
                    newStage.status = .pending
                case .defualt:
                    // 是普通状态，当前的必然在被过滤后的stage里
                    if index < currentStageIndex {
                        newStage.status = .finish
                    } else if index == currentStageIndex {
                        newStage.status = .progressing
                    } else {
                        newStage.status = .pending
                    }
                }
                newStage.isCurrent = index == selectedIndex
                dealedStages.append(newStage)
            }
            var dealedProperty = stageField.property
            dealedProperty.stages = dealedStages
            stageField.update(isStageCanceled: currentOption.type == .endCancel)
            stageField.update(property: dealedProperty)
            // 把stageField 修改成detail的类型,然后根据数据构造假的Field
            stageField.updateMockStageField(type: .stageDetail)
            // 更新当前的stage把当前选择的stage当做真实的stage
            stageField.update(optionIDs: [selectedOptionId])
            var fields: [BTFieldModel] = []
            if !UserScopeNoChangeFG.ZJ.btCardReform {
                // 添加PrimaryField, 顶部的字段永远不用error态
                primaryField.update(errorMsg: "")
                fields.append(primaryField)
            } else {
                // 添加 ItemView attachment cover Field
                if let itemViewHeader = recordModel.wrappedFields.first(where: { $0.extendedType == .attachmentCover }) {
                    fields.append(itemViewHeader)
                }
                // 添加ItemView heard Field
                if let itemViewHeader = recordModel.wrappedFields.first(where: { $0.extendedType == .itemViewHeader }) {
                    fields.append(itemViewHeader)
                }
                // 添加ItemView Catalogue Field
                if !UserScopeNoChangeFG.YY.bitableRecordShareCatalogueDisable, let itemViewCatalogue = recordModel.wrappedFields.first(where: { $0.extendedType == .itemViewCatalogue }) {
                    fields.append(itemViewCatalogue)
                }
                // 添加ItemView tabs
                if let itemViewTabs = recordModel.wrappedFields.first(where: { $0.extendedType == .itemViewTabs }) {
                    fields.append(itemViewTabs)
                }
            }
            // 添加stageDetail Field
            fields.append(stageField)
            // 处理关联字段
            let linkedFieldIds = stageField.property.stages.first(where: { $0.id == selectedOptionId })?.fieldsConfigInfo.map { $0.id } ?? []
            let stageRequireFields = recordModel.stageRequiredFields[stageField.fieldID]
            let linkFields = linkedFieldIds.compactMap { linkFieldId -> BTFieldModel? in
                // itemView改造不能过滤primaryFieldID
                guard var linkField = recordModel.originalFields.first(where: { $0.fieldID == linkFieldId }) else {
                    return nil
                }
                
                linkField.update(isStageLinkField: true)
                if UserScopeNoChangeFG.ZJ.btCardReform {
                    let isRequired = stageRequireFields?[selectedOptionId]?.contains(where: { $0 == linkField.fieldID }) ?? false
                    linkField.update(isRequired: isRequired)
                    if !isRequired {
                        // 非必填，不显示错误信息
                        linkField.update(errorMsg: "")
                    }
                    linkField.update(inStage: true)
                }
                linkField.update(currentStageOptionId: selectedOptionId)
                return linkField
            }
            // 添加关联的field
            fields.append(contentsOf: linkFields)
            var dealedRecordModel = recordModel
            dealedRecordModel.update(fields: fields)
            return dealedRecordModel
        } else {
            DocsLogger.btError("[Stage Detail] deal record falied fall back")
            return recordModel
        }
    }

    private func reloadViewMode() {
        func configurePanGesture() {
            headerView.addPanGesture()
            addEmptyPanGesture()
            addTimeOutPanGesture()
            let contentScrollGesture = UIPanGestureRecognizer()
            contentScrollGesture.addTarget(self, action: #selector(scrollViewPan))
            contentScrollGesture.delegate = self
            fieldsView.addGestureRecognizer(contentScrollGesture)
        }
        headerView.isHidden = false
        emptyView.isHidden = true
        timeOutEmptyView.isHidden = true
        fieldsView.isHidden = false
        fieldsView.bounces = false
        fieldsView.alwaysBounceVertical = false
        hideLoading()
        if UserScopeNoChangeFG.ZJ.btCardReform {
            self.clipsToBounds = true
        } else {
            contentView.layer.cornerRadius = 8
            contentView.clipsToBounds = true
        }
        
        // 添加侧滑手势
        if UserScopeNoChangeFG.ZJ.btCardReform && !viewMode.isIndRecord && viewMode != .submit {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
            addGestureRecognizer(panGesture)
        }
        
        switch viewMode {
        case .submit:
            if !shouldFixScrollIndicatorBug {
                layer.ud.setShadow(type: .s4Down)
            }
            
            if UserScopeNoChangeFG.ZJ.btCardReform {
                self.delegate?.hideSwitchCardBottomPanelView(hidden: true)
            }
        case .normal, .link:
            if !UserScopeNoChangeFG.ZJ.btCardReform {
                if !shouldFixScrollIndicatorBug {
                    layer.ud.setShadow(type: .s4Down)
                }
                configurePanGesture()
            }
            updateBounces()
        case .indRecord:
            if !UserScopeNoChangeFG.ZJ.btCardReform {
                layer.ud.setShadow(type: .s4Down)
            } else {
                self.delegate?.hideSwitchCardBottomPanelView(hidden: true)
            }
            updateBounces()
        case .invisible:
            emptyView.isHidden = false
            emptyView.superview?.bringSubviewToFront(emptyView)
            if !UserScopeNoChangeFG.ZJ.btCardReform {
                if !shouldFixScrollIndicatorBug {
                    layer.ud.setShadow(type: .s4Down)
                }
                configurePanGesture()
            } else {
                headerView.superview?.bringSubviewToFront(headerView)
                headerView.setHeaderAlpha(alpha: 1)
            }
        case .form:
            contentView.layer.cornerRadius = 0
            headerView.isHidden = true
            /*
             1. form 表单需要支持 header 的上滑隐藏和下滑到顶显示
             2. 下滑到顶显示是 native 根据 didScroll 的时候 y <= 0 判断是否到顶
             3. 如果 form 表单的内容高度不足，因为弹性的存在，上滑隐藏 header 后，会触发 didScroll 事件，这时候因为 y <= 0，会判断是滑动到顶从而立即又把 header 再显示出来
             4. 所有这里刻意把弹性禁用了
             */
            fieldsView.bounces = false
            fieldsView.alwaysBounceVertical = true
            if shouldFixScrollIndicatorBug {
                bgView.removeFromSuperview()
            }
        case .loading:
            showLoading()
            if !UserScopeNoChangeFG.ZJ.btCardReform {
                configurePanGesture()
            } else {
                headerView.setHeaderAlpha(alpha: 1)
            }
        case .timeOut:
            if case let .timeOut(request) = recordModel.dataStatus {
                timeOutRequest = request
            }
            showTimeoutView()
            if !UserScopeNoChangeFG.ZJ.btCardReform {
                configurePanGesture()
            } else {
                headerView.superview?.bringSubviewToFront(headerView)
                headerView.setHeaderAlpha(alpha: 1)
            }
        case .stage:
            fieldsView.alwaysBounceVertical = true
            guard !UserScopeNoChangeFG.ZJ.btCardReform else  {
                return
            }
            headerView.isHidden = true
            filterView.isHidden = true
            fieldsView.bounces = true
        }
        layoutIfNeeded()
    }

    private func updateBounces() {
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return
        }
        fieldsView.alwaysBounceVertical = true
        fieldsView.bounces = true
    }

    func highlightFieldIfNeeded(at indexPath: IndexPath, mode: BTFieldHighlightMode) {
        switch mode {
        case .none: break
        case .temporary:
            guard let field = fieldsView.cellForItem(at: indexPath) as? BTFieldCellProtocol else { return }
            UIView.animate(withDuration: 0.5) {
                field.updateBorderMode(.editing)
                field.updateContainerHighlight(true)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) { [weak field] in
                UIView.animate(withDuration: 0.5) { [weak field] in
                    field?.updateBorderMode(.normal)
                    field?.updateContainerHighlight(false)
                }
            }
        }
    }
    
    /// 是否需要再键盘弹起时自动调整 contentInset
    private var isNeedAjustContentInsetWhenKeyBoardShowAutomatically: Bool {
        /// 当前编辑的 Field 自己设置了编辑面板高度，这种情况下就自己处理键盘事件。
        if let editPanelRectInRecord = delegate?.currentEditPanelRect(in: self),
           editPanelRectInRecord.size != .zero {
            return false
        } else {
            return true
        }
    }
    /// 弹起键盘时自动调整 contentInset，让当前编辑的 Field 滚动到可见的位置。
    private func handleKeyboard(didTrigger event: Keyboard.KeyboardEvent, options: Keyboard.KeyboardOptions) {
        switch event {
        case .willHide:
            fieldsView.contentInset = .zero
            keyboardHeightInFieldsView = 0
            if UserScopeNoChangeFG.ZJ.btCardReform {
                fieldsView.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(-keyboardHeightInFieldsView)
                }
            }
        case .didShow:
            // 这里使用 didShow，而不用 willShow 的原因是,使用 willShow 时，触发编辑时弹起键盘的表现会不一致。有时有动画，有时没有动画。
            // 可以使用 scrollViewDidEndScrollingAnimation 来进行观察。
            guard isNeedAjustContentInsetWhenKeyBoardShowAutomatically else {
                return
            }
            
            let keyboardFrameInFieldsView = fieldsView.convert(options.endFrame, from: nil)
            
            guard keyboardHeightInFieldsView != keyboardFrameInFieldsView.height else {
                return
            }
            
            let currentContentOffsetY = fieldsView.contentOffset.y
            
            if UserScopeNoChangeFG.ZJ.btCardReform {
                fieldsView.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(-keyboardFrameInFieldsView.height)
                }
                // 键盘高度变化时，也需要刷新fieldsView的偏移量
                let targetOffsetY = max(keyboardFrameInFieldsView.height - keyboardHeightInFieldsView, 0) + currentContentOffsetY
                fieldsView.setContentOffset(CGPoint(x: 0, y: targetOffsetY), animated: true)
                keyboardHeightInFieldsView = keyboardFrameInFieldsView.height
            } else {
                keyboardHeightInFieldsView = keyboardFrameInFieldsView.height
                fieldsView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeightInFieldsView, right: 0)
            }
            
            debugPrint("BTRecord handleKeyboard didShow \(options)")
        default: ()
        }
    }
    /// 非人为拖动滚动停止会调用。
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        debugPrint("BTURLField scrollViewDidEndScrollingAnimation")
        self.delegate?.didEndScrollingAnimation(in: self)
    }

    private func setupLayout() {
        contentView.addSubview(emptyView)
        contentView.addSubview(timeOutEmptyView)
        if !UserScopeNoChangeFG.ZJ.btCardReform {
            let stackView = UIStackView()
            stackView.axis = .vertical
            contentView.addSubview(stackView)
            stackView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            stackView.addArrangedSubview(headerView)
            if !UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
                stackView.addArrangedSubview(filterView)
            }
            stackView.addArrangedSubview(fieldsView)
        } else {
            contentView.addSubview(fieldsView)
            if !UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
                contentView.addSubview(filterView)
            }
            contentView.addSubview(headerView)
            fieldsView.snp.makeConstraints { make in
                make.top.left.right.bottom.equalToSuperview()
            }
            
            headerView.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview()
            }
            if !UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
                filterView.snp.makeConstraints { make in
                    make.top.equalTo(headerView.snp.bottom)
                    make.left.right.equalToSuperview()
                }
            }
        }

        filterView.isHidden = true

        if UserScopeNoChangeFG.ZJ.btCardReform {
            emptyView.snp.makeConstraints { (make) in
                make.top.equalTo(self.safeAreaLayoutGuide.snp.top)
                make.left.right.bottom.equalToSuperview()
            }
            
            timeOutEmptyView.snp.makeConstraints { (make) in
                make.top.equalTo(self.safeAreaLayoutGuide.snp.top)
                make.left.right.bottom.equalToSuperview()
            }
        } else {
            emptyView.snp.makeConstraints { (make) in
                make.top.equalTo(headerView.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
            
            timeOutEmptyView.snp.makeConstraints { (make) in
                make.top.equalTo(headerView.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
        }
    }
    
    private var shouldShowFilterView: Bool {
        guard viewMode == .normal else {
            return false
        }
        return recordModel.isFiltered && !recordModel.filterTipClosed
    }

    private func updateFilterView() {
        guard viewMode == .normal else {
            if UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
                filterView.isHidden = true
            }
            return
        }
        filterView.isHidden = !recordModel.isFiltered || recordModel.filterTipClosed
        // 如果记录被过滤了不可见，就不显示翻页按钮，免得用户划走回不来
        delegate?.hideSwitchCardBottomPanelView(hidden: recordModel.isFiltered)
    }

    private func getHeaderTitle() -> String {
        var headerTitle = recordModel.recordTitle
        if UserScopeNoChangeFG.ZJ.btCardReform {
            if viewMode == .link {
                // 特化逻辑，当前是关联卡片时，标题显示关联表名
                headerTitle = recordModel.tableName
            }
        }
        return headerTitle
    }
    
    public func updateHeader() {
        let shouldShowAttachmentCover = recordModel.shouldShowAttachmentCoverField()
        headerView.dataSource = BTRecordHeaderView.DataSource(
            mode: viewMode,
            topColor: headerBarColor,
            title: BTUtil.getTitleAttrString(title: getHeaderTitle()),
            canDelete: recordModel.deletable,
            canAddRecord: recordModel.canAddRecord,
            shouldShowSubmitTopTip: recordModel.shouldShowSubmitTopTip,
            canShare: recordModel.shareable,
            btViewMode: recordModel.viewMode,
            viewMode: shouldShowAttachmentCover ? .transparent : .normal,
            closeIconType: self.delegate?.getRecordHeaderCloseIconType() ?? .leftOutlined,
            coverChangeAble: delegate?.canEditAttachmentCover() ?? false,
            subscribeStatue: currentSubscribeStatus(),
            isArchived: recordModel.isArchvied,
            shouldShowFilteredTips: shouldShowFilterView
        )
        
        let headerViewHeight = headerView.getViewHeight(safeAreaInsetTop: self.safeAreaInsets.top)
        fieldsView.setHearderViewHeight(height: headerViewHeight)
        if recordModel.shouldShowSubmitTopTip, UserScopeNoChangeFG.ZJ.btCardReform {
            // 有tips时隐藏滚动条
            fieldsView.showsVerticalScrollIndicator = false
        } else {
            fieldsView.showsVerticalScrollIndicator = !shouldFixScrollIndicatorBug
        }
    }

    func getHeaderViewFrame() -> CGRect {
        return headerView.convert(headerView.frame, to: headerView.window)
    }
    
    private func addEmptyPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(emptyViewPan(_:)))
        panGesture.delegate = self
        emptyView.addGestureRecognizer(panGesture)
    }
    
    private func currentSubscribeStatus() -> BTRecordSubscribeStatus {
        guard let dele = delegate else {
            DocsLogger.btError(" record's delegate is nil")
            return .unknown
        }
        guard dele.recordEnableSubscribe(record: recordModel) else {
            DocsLogger.btError("record subscribe disable")
            return .unknown
        }
        return dele.fetchLocalRecordSubscribeStatus(recordId: recordModel.recordID)
    }
    
    private func addTimeOutPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(timeOutViewPan(_:)))
        panGesture.delegate = self
        emptyView.addGestureRecognizer(panGesture)
    }

    func getCellRect(cell: BTFieldCellProtocol) -> CGRect? {
        guard let indexPath = fieldsView.indexPath(for: cell),
              let layoutAttributes = fieldsView.attributesForItem(at: indexPath)
        else { return nil }
        return fieldsView.convert(layoutAttributes.frame, to: self)
    }
    
    func calculateFieldsViewVisibleHeight() -> CGFloat {
        var inputViewHeight = fieldsView.bounds.height - keyboardHeightInFieldsView
        if let editPanelRectInRecord = delegate?.currentEditPanelRect(in: self),
           editPanelRectInRecord != .zero {
            inputViewHeight = editPanelRectInRecord.minY - headerView.bounds.height
        }
        return inputViewHeight
    }

    //同步滚动到当前卡片最上方可视的field
    func syncTopField() {
        guard !UserScopeNoChangeFG.ZJ.btCardReform else {
            // 新版itemView不支持联动滚动
            return
        }
        
        guard fieldsViewVisible,
              false == delegate?.isCurrentCard(id: recordID),
              !currentTopFieldID.isEmpty,
              !currentFieldIsAllVisibleInTop(fieldId: currentTopFieldID),
              let index = getFieldIndex(forFieldID: currentTopFieldID) else { return }
        DocsLogger.btInfo("[ACTION] btrecord syncTopField currentTopFieldId: \(currentTopFieldID) topVisibleFieldID: \(topVisibleFieldID) recordID: \(recordID)")
        fieldsView.docs.safeScrollToItem(at: IndexPath(row: index, section: 0), at: [.top, .centeredHorizontally], animated: false)
    }

    //当前最上方的字段是否全部可见
    func currentFieldIsAllVisibleInTop(fieldId: String) -> Bool {
        let visibleIndexPaths = fieldsView.indexPathsForVisibleItems.sorted()
        var currentField: BTFieldCellProtocol?
        for indexPath in visibleIndexPaths {
            if let field = fieldsView.cellForItem(at: indexPath) as? BTFieldCellProtocol,
                field.fieldID == fieldId {
                currentField = field
                break
            }
        }
        if let currentField = currentField {
            let fieldFrameInFieldsView = currentField.convert(currentField.bounds, to: fieldsView)
            return fieldFrameInFieldsView.origin.y == 0
        }
        return false
    }

    func notifyFirstVisibleFieldID() {
        guard fieldsViewVisible else {
            return
        }
        
        let visibleIndexPaths = fieldsView.indexPathsForVisibleItems.sorted()
        for indexPath in visibleIndexPaths {
            if let field = fieldsView.cellForItem(at: indexPath) as? BTFieldCellProtocol {
                delegate?.didScrollToField(id: field.fieldID, recordID: recordID)
                break
            }
        }
    }
    
    private func showLoading() {
        fieldsView.isHidden = true
        emptyView.isHidden = true
        timeOutEmptyView.isHidden = true
        
        var centeryOffset: CGFloat = 0
        if UserScopeNoChangeFG.ZJ.btCardReform {
            fieldsView.isHidden = true
            centeryOffset = self.safeAreaInsets.top
        }
        isShowLoading = true
        loadingViewManager.showLoading(superView: self, centeryOffset: centeryOffset)
    }
    
    private func hideLoading() {
        guard isShowLoading else {
            return
        }
        if UserScopeNoChangeFG.ZJ.btCardReform {
            fieldsView.isHidden = false
            headerView.setHeaderAlpha(alpha: 0)
        }
        loadingViewManager.hideLoading()
        isShowLoading = false
    }
    
    private func showTimeoutView() {
        timeOutEmptyConfig.primaryButtonConfig = (BundleI18n.SKResource.Bitable_Common_ButtonRetry, { [weak self] _ in
            guard let self = self else { return }
            //重新请求数据
            self.didClickRetry(request: self.timeOutRequest)
        })
        timeOutEmptyView.update(config: self.timeOutEmptyConfig)
        timeOutEmptyView.isHidden = false
        timeOutEmptyView.superview?.bringSubviewToFront(timeOutEmptyView)
    }
    
    private func didClickRetry(request: BTGetCardListRequest?) {
        guard let request = request else {
            return
        }
        
        delegate?.didClickRetry(request: request)
    }
    
}

// MARK: - HeaderDelegate
extension BTRecord: BTRecordHeaderViewDelegate {
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {

        if UserScopeNoChangeFG.ZJ.btCardReform {
            let startPoint = gesture.location(in: gesture.view)
            if startPoint.x >= 25 {
                return
            }
        }
        delegate?.handlePanGesture(gesture, setViewScrollable: { scrollable in
            fieldsView.isScrollEnabled = scrollable
        })
    }
    
    func didClickHeaderButton(action: BTActionFromUser) {
        delegate?.didClickHeaderButton(action: action)
    }

    func didTapTitle(withAttributes attributes: [NSAttributedString.Key: Any]) {
        guard let primaryFieldModel = recordModel.getFieldModel(id: recordModel.primaryFieldID) else { return }
        _ = delegate?.didTapView(withAttributes: attributes, inFieldModel: primaryFieldModel)
    }
    
    func didClickMoreButton(sourceView: UIView) {
        guard let dele = delegate else {
            DocsLogger.error("click card more button failed, BTRecord's delegate is nil")
            return
        }
        
        dele.didClickMoreButton(record: recordModel, sourceView: sourceView)
    }
    
    func didClickShareButton(sourceView: UIView) {
        guard let dele = delegate else {
            DocsLogger.warning("click card share button failed, BTRecord's delegate is nil")
            return
        }
        dele.didClickShareButton(recordID: recordID, recordTitle: recordModel.recordTitle, sourceView: sourceView)
    }
    
    func didClickCloseNoticeButton() {
        if UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
            recordModel.update(shouldShowSubmitTopTip: false)
            if headerView.dataSource?.shouldShowFilteredTips == true {
                delegate?.didCloseBanner()
            }
        }
        // 通知前端点击关闭了提示
        let shouldShowAttachmentCover = recordModel.shouldShowAttachmentCoverField()
        headerView.dataSource = BTRecordHeaderView.DataSource(
            mode: viewMode,
            topColor: headerBarColor,
            title: BTUtil.getTitleAttrString(title: getHeaderTitle()),
            canDelete: recordModel.deletable,
            canAddRecord: recordModel.canAddRecord,
            shouldShowSubmitTopTip: false,
            canShare: recordModel.shareable,
            btViewMode: recordModel.viewMode,
            subscribeStatue: currentSubscribeStatus(),
            isArchived: recordModel.isArchvied,
            shouldShowFilteredTips: shouldShowFilterView
        )
        headerView.invalidateIntrinsicContentSize()
        fieldsView.showsVerticalScrollIndicator = !shouldFixScrollIndicatorBug
        delegate?.didClicksubmitTopTips()
        if UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
            updateRecordAndReload()
        }
    }

    func recordHeaderViewDidClickAddCover(view: BTRecordHeaderView, sourceView: UIView) {
        guard let delegate = delegate else {
            DocsLogger.warning("click add cover button failed, BTRecord's delegate is nil")
            return
        }
        delegate.recordViewOperateCover(view: self, sourceView: sourceView)
    }
    
    func recordSubscribeViewDidClick(isSubscribe: Bool, completion: @escaping (BTRecordSubscribeCode) -> Void) {
        guard let delegate = delegate else {
            DocsLogger.warning("click subscribe button failed, BTRecord's delegate is nil")
            completion(.unknownError)
            return
        }
        let recordId = self.recordID
        delegate.recordSubscribe(recordId: recordId, isSubscribe: isSubscribe, isPassive: false, scene: .normal) { [weak self] code in
            guard let self = self else {
                return
            }
            //若异步检测结果已经不是最初的record，直接return
            if self.recordID != recordId {
               DocsLogger.warning("subscribe button click result consuming time too long")
               return
            }
            completion(code)
        }
    }
}

// MARK: - 下拉关闭相关
extension BTRecord: UIGestureRecognizerDelegate {
    
    func handleViewPan(_ pan: UIPanGestureRecognizer, view: UIView) {
        let velocity = pan.velocity(in: view)
        if (velocity.y > 0 && velocity.y > abs(velocity.x))
            || pan.state == .cancelled || pan.state == .ended {
            handlePanGesture(pan)
        }
    }

    @objc
    func emptyViewPan(_ pan: UIPanGestureRecognizer) {
        handleViewPan(pan, view: emptyView)
    }
    
    @objc
    func timeOutViewPan(_ pan: UIPanGestureRecognizer) {
        handleViewPan(pan, view: timeOutEmptyView)
    }

    @objc
    func scrollViewPan(_ pan: UIPanGestureRecognizer) {
        let velocity = fieldsView.panGestureRecognizer.velocity(in: fieldsView)
        if (recordCanScroll &&
            fieldsView.contentOffset.y == 0
                && velocity.y > 0
                && velocity.y > abs(velocity.x))
            || pan.state == .cancelled || pan.state == .ended {
            handlePanGesture(pan)
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Scrolling to Fields
extension BTRecord {
    
    @available(*, deprecated, message: "scrollToField(with fieldId:scrollPosition:animated:) instead")
    func scrollToField(at indexPath: IndexPath, scrollPosition: UICollectionView.ScrollPosition, animated: Bool = true) {
        guard fieldsViewVisible && indexPath.item < recordModel.wrappedFields.count && indexPath.item >= 0 else { return }
        fieldsView.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
    }
    
    func scrollToField(with fieldId: String, scrollPosition: UICollectionView.ScrollPosition, needAddHeaderOffset: Bool = false, animated: Bool = true) {
        let index = uiModel.getFieldIndex(id: fieldId)
        let total = uiModel.wrappedFields.count
        guard let index, fieldsViewVisible && index < total && index >= 0 else {
            DocsLogger.btError("scrollToField failed, index: \(index ?? -1), total: \(total), mode: \(viewMode)")
            return
        }
        
        DocsLogger.btInfo("scrollToField start, idx: \(index), needAddHeaderOffset: \(needAddHeaderOffset)")

        fieldsView.scrollToItem(at: IndexPath(row: index, section: 0), at: scrollPosition, animated: animated)

        if needAddHeaderOffset, let cellAttributes = fieldsView.attributesForItem(at: IndexPath(row: index, section: 0)) {
            let cellRect = cellAttributes.frame
            let cellRectInRecordMinY = fieldsView.convert(cellRect, to: self).minY
            
            // 滚动距离需要加上header的高度和tabs的高度
            var offsetY = headerView.bounds.height
            if context?.shouldShowItemViewTabs == true {
                offsetY += BTFieldLayout.Const.itemViewTabsHeight
            }
            
            let targetOffset = offsetY - cellRectInRecordMinY
            guard targetOffset > 0 else {
                DocsLogger.btInfo("scrollToField addOffset targetOffset is \(targetOffset)")
                return
            }
            
            let offset = CGPoint(x: fieldsView.contentOffset.x, y: max(fieldsView.contentOffset.y - offsetY, 0))

            DocsLogger.btInfo("scrollToField suc, offset: \(offset), headerH: \(offsetY), showTab: \(context?.shouldShowItemViewTabs ?? false)")
            
            fieldsView.setContentOffset(offset, animated: false)
        }
    }
    
    func getHeaderViewAlpha() -> CGFloat {
        guard fieldsViewVisible else {
            return 0
        }

        return fieldsView.contentOffset.y / 48
    }

    /// 将 Field 滚动到可见
    /// - Parameters:
    ///   - field: 要滚动的字段
    ///   - animated: 是否有动画
    public func scrollTillFieldBottomIsVisible(_ field: BTFieldCellProtocol, animated: Bool = true) {
        guard fieldsViewVisible else {
            return
        }
        let headerMaxYInRecord = headerView.convert(headerView.bounds, to: self).maxY
        let fieldsVisibleHeight = calculateFieldsViewVisibleHeight()
        let panelMinYInRecord = headerMaxYInRecord + fieldsVisibleHeight
        let panelMinYInFieldsView = fieldsVisibleHeight
        if let indexPath = fieldsView.indexPath(for: field),
           let cellAttributes = fieldsView.attributesForItem(at: indexPath) {
            let cellRect = cellAttributes.frame
            let cellRectInRecord = fieldsView.convert(cellRect, to: self)
            let currentOffset = fieldsView.contentOffset
            // field 底部与 panel 顶部齐平
            // field 的底部被底部弹起的视图被住或者顶部被头视图遮住
            if cellRectInRecord.maxY >= panelMinYInRecord || cellRectInRecord.minY < headerMaxYInRecord {
                fieldsView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: fieldsView.bounds.height - panelMinYInFieldsView, right: 0)
                let fixY: CGFloat = panelMinYInRecord - cellRectInRecord.maxY
                let targetOffset = CGPoint(x: currentOffset.x, y: max(0, currentOffset.y - fixY))
                
                if animated {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.fieldsView.setContentOffset(targetOffset, animated: false)
                    })
                } else {
                    self.fieldsView.setContentOffset(targetOffset, animated: false)
                }
                DocsLogger.btInfo("scrollTillFieldBottomIsVisible offset: \(targetOffset) contenInset bottom: \(fieldsView.bounds.height - panelMinYInFieldsView)")
            }
        }
    }

    public func getFieldIndex(forFieldID fieldID: String) -> Int? {
        return uiModel.wrappedFields.firstIndex {
            /// 这里判空是为了规避文章有脏数据。
            return !$0.fieldID.isEmpty && $0.fieldID == fieldID
        }
    }

    func resetContentInset() {
        fieldsView.contentInset = .zero
    }
    
    func switchItemViewTab(to id: String) {
        // 获取index
        guard let itemViewIndex = recordModel.itemViewTabs.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        didClickTab(index: itemViewIndex)
    }
}

extension BTRecord {
    /// 前端异步请求回调
    /// - Parameters:
    ///   - router: 请求路由
    ///   - data: 请求结果
    func didAsyncRequestCallBack(router: BTAsyncRequestRouter, data: Any?) {}
}
