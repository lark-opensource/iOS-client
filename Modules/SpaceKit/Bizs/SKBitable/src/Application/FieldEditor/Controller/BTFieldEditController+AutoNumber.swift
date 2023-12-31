//
//  BTFieldEditController+AutoNumber.swift
//  SKBitable
//
//  Created by zoujie on 2022/9/28.
//  


import Foundation
import SKResource
import SKUIKit
import EENavigator
import UniverseDesignIcon
import UniverseDesignColor

private let maxAutoNumRuleCount: Int = 9

extension BTFieldEditController {
    
    ///配置自动编号数字字段UI
    func configAutoNumberUI(view: UIView, viewManager: BTFieldEditViewManager) {
        currentTableView.tableHeaderView?.frame.size.height = 334

        specialSetView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(154)
        }

        let isAdvancedRules = viewModel.fieldEditModel.fieldProperty.isAdvancedRules

        if isAdvancedRules {
            setAutoNumberPreView(view: view)
            if auotNumberRuleList.isEmpty {
                guard let ruleList = viewModel.commonData.fieldConfigItem.commonAutoNumberRuleTypeList.first(where: { $0.isAdvancedRules })?.ruleFieldOptions else { return }
                let fixedRuleList = ruleList.filter({ $0.fixed })

                for fixedRule in fixedRuleList {
                    //默认自增数字规则
                    var newAutoNumberRuleModel = BTAutoNumberRuleOption()
                    newAutoNumberRuleModel.title = fixedRule.title
                    newAutoNumberRuleModel.type = fixedRule.type
                    newAutoNumberRuleModel.value = fixedRule.value
                    newAutoNumberRuleModel.description = fixedRule.description
                    newAutoNumberRuleModel.id = String(auotNumberRuleList.count)

                    auotNumberRuleList.append(newAutoNumberRuleModel)
                }
            }
        }
        
        configAutoNumFooter()

        //埋点上报
        delegate?.trackEditViewEvent(eventType: .bitableAutoNumberFieldModifyView,
                                     params: [:],
                                     fieldEditModel: self.viewModel.fieldEditModel)
    }

    ///自动编号字段设置预览view高度
    func setAutoNumberPreView(view: UIView) {
        //自定义规则才需要展示预览view
        guard viewModel.fieldEditModel.fieldProperty.isAdvancedRules, let viewManager = viewManager else { return }
        let preViewText = BTFieldEditUtil.generateAutoNumberPreString(auotNumberRuleList: auotNumberRuleList)

        //计算编号预览view的高度
        let preViewHeight = ceil(viewManager.setautoNumberPreviewView(text: preViewText, viewWidth: self.view.bounds.width))

        guard let headerView = currentTableView.tableHeaderView,
              headerView.frame.size.height != 336 + preViewHeight else { return }

        view.snp.updateConstraints { make in
            make.height.equalTo(preViewHeight + 158)
        }

        currentTableView.tableHeaderView?.frame.size.height = 336 + preViewHeight
        currentTableView.tableHeaderView = containerView
        if let editingFieldCellIndex = editingFieldCellIndex, editingFieldCellIndex < currentTableView.numberOfRows(inSection: 0) {
            currentTableView.scrollToRow(at: IndexPath(row: editingFieldCellIndex, section: 0), at: .bottom, animated: false)
        }
    }
    
    ///自动编号字段新增规则面板
    func presentAutoNumberRuleSelecteController() {
        guard let ruleList = viewModel.commonData.fieldConfigItem.commonAutoNumberRuleTypeList.first(where: { $0.isAdvancedRules })?.ruleFieldOptions else { return }
        
        var ruleSelectVC: BTPanelController?
        
        let selectCallback: ((_ cell: BTCommonCell, _ id: String?, _ userInfo: Any?) -> Void)? = { [weak self] (_, id, useInfo) in
            guard let self = self, let itemId = id else { return }
            let index = Int(itemId) ?? 0
            self.didClickItem(viewIdentify: BTFieldEditPageAction.autoNumberRuleSelect.rawValue, index: index)
            // 关闭当前选择面板
            ruleSelectVC?.dismiss(animated: true)
        }
        
        var index = -1
        let dataList = ruleList.filter({ !$0.fixed }).compactMap { rule -> BTCommonDataItem in
            index =  index + 1
            return BTCommonDataItem(id: String(index),
                                    selectable: false,
                                    selectCallback: selectCallback,
                                    mainTitle: .init(text: rule.title),
                                    subTitle: .init(text: rule.description, lineNumber: 0),
                                    rightIcon: .init(image: UDIcon.addOutlined.ud.withTintColor(UDColor.iconN2),
                                                     size: CGSize(width: 20, height: 20)))
        }

        ruleSelectVC = BTPanelController(title: BundleI18n.SKResource.Bitable_Field_AddNewAutoIdRule,
                                         data: BTCommonDataModel(groups: [BTCommonDataGroup(groupName: "autoNumberRule",
                                                                                            items: dataList)]),
                                         delegate: nil,
                                         hostVC: self,
                                         baseContext: baseContext)
        ruleSelectVC?.setCaptureAllowed(true)
        ruleSelectVC?.automaticallyAdjustsPreferredContentSize = false
        
        guard let ruleSelectVC = ruleSelectVC else { return }

        safePresent { [weak self] in
            guard let self = self else { return }
            BTNavigator.presentSKPanelVCEmbedInNav(ruleSelectVC, from: UIViewController.docs.topMost(of: self) ?? self)
        }
    }
    
    ///新增自动编号规则
    func didClickAddRuleType(index: Int) {
        guard let ruleList = viewModel.commonData.fieldConfigItem.commonAutoNumberRuleTypeList.first(where: { $0.isAdvancedRules })?.ruleFieldOptions.filter({ !$0.fixed }),
              index < ruleList.count else { return }
        let newRule = ruleList[index]

        var newAutoNumberRuleModel = BTAutoNumberRuleOption()
        newAutoNumberRuleModel.type = newRule.type
        newAutoNumberRuleModel.title = newRule.title
        newAutoNumberRuleModel.value = newRule.value
        //要获取当前所有cell的最大id，然后+1赋给新cell
        var maxID = 0
        auotNumberRuleList.forEach { rule in
            maxID = max(maxID, Int(rule.id) ?? auotNumberRuleList.count)
        }
        newAutoNumberRuleModel.id = String(maxID + 1)

        if newRule.type == .createdTime {
            let defaultValue = viewModel.commonData.fieldConfigItem.commonAutoNumberRuleTypeList.last?.ruleFieldOptions.first(where: { $0.type == .createdTime })?.optionList.first?.text
            newAutoNumberRuleModel.value = defaultValue ?? ""
        }

        if newRule.type == .fixedText {
            //只有固定字符在新增后需要进入编辑态
            newItemID = newAutoNumberRuleModel.id
        }
        auotNumberRuleList.append(newAutoNumberRuleModel)
        
        configAutoNumFooter()
        
        currentTableView.reloadData()
        currentTableView.layoutIfNeeded()
        currentTableView.scrollToRow(at: IndexPath(row: max(auotNumberRuleList.count - 1, 0), section: 0), at: .bottom, animated: false)
    }
    
    func configAutoNumFooter() {
        if viewModel.fieldEditModel.fieldProperty.isAdvancedRules {
            let isLimit = auotNumberRuleList.count == maxAutoNumRuleCount
            let limitTip = BundleI18n.SKResource.Bitable_Field_MaxAutoIdRuleMobileVer(maxAutoNumRuleCount)
            let addTip = BundleI18n.SKResource.Bitable_Field_AddAutoIdRuleMobileVer
            let tip = isLimit ? limitTip : addTip
            footerView.activeAutoNumFooter { [weak self] footer in
                guard let self = self else { return }
                let margin = BTFieldEditAutoNumFooter.Const.noHeaderTopSuggestMargin
                footer.updateAddButton(hidden: false, enable: !isLimit, text: tip, topMargin: margin)
                footer.addAction = { [weak self] sender in
                    self?.didClickAdd(sender: sender)
                }
            }
        } else {
            footerView.deactiveSpeFooter()
        }
    }
}
