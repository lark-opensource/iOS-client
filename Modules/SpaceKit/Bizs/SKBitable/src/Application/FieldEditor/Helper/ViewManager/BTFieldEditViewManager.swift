//
//  BTFieldEditController+FieldViews.swift
//  SKBitable
//
//  Created by zoujie on 2022/5/9.
//  description: 字段增删改面板配置
//  swiftlint:disable file_length type_body_length cyclomatic_complexity

import SKFoundation
import UIKit
import SnapKit
import SKResource
import SKCommon
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignSwitch

protocol BTFieldEditViewManagerDelegate: AnyObject {
    func didClickChooseDateType(button: BTFieldCustomButton)
    func didClickChooseNumberType(button: BTFieldCustomButton)
    func didClickChooseCurrencyType(button: BTFieldCustomButton)
    func didClickChooseProgressType(button: BTFieldCustomButton)
    func didClickChooseProgressNumberType(button: BTFieldCustomButton)
    func didClickChooseProgressColor(button: BTFieldCustomButton)
    func didClickChooseRelatedTable(button: BTFieldCustomButton)
    func didClickChooseRelatedTableRange(button: BTFieldCustomButton)
    func didClickAddLinkTableFilterOption(button: BTAddButton)
    func didClickLinkFieldFilterConjunctionButton(button: UIButton)
    func didClickChooseAutoNumberType()
    func didClickCheckBox(isSelected: Bool)
    func didClickChooseLocationInputType()
    func didClickOptionTypeChooseButton(button: BTFieldCustomButton)
    func didClickAiExtensionButton(button: BTFieldCustomButton)
    func didClickDynamicOptionTableChooseButton(button: BTFieldCustomButton)
    func didClickDynamicOptionFieldChooseButton(button: BTFieldCustomButton)
    func didClickDynamicOptionLinkRelationButton(button: UIButton)
    func didFieldInputEditBegin(fieldInputView: BTFieldInputView)
    func didFieldInputEditEnd(fieldInputView: BTFieldInputView)
    func setTableHeaderViewHeight(height: CGFloat)
    var baseContext: BaseContext { get }
    
}

final class BTFieldEditViewManager {

    private weak var delegate: BTFieldEditViewManagerDelegate?

    private(set) var fieldEditModel: BTFieldEditModel

    private(set) var commonData: BTCommonData
    // 级联是否部分无权限(只有scheme4文档下才会为true，老文档isPartialDenied是nil)
    var isDynamicPartNoPerimission: Bool {
        commonData.isDynamicPartNoPerimission(targetTable: fieldEditModel.fieldProperty.optionsRule.targetTable, targetField: fieldEditModel.fieldProperty.optionsRule.targetField)
    }
    // 级联引用表是否有权限
    var dynamicTableReadPerimission: Bool {
        commonData.dynamicTableReadPerimission(targetTable: fieldEditModel.fieldProperty.optionsRule.targetTable)
    }
    // 级联引用字段是否无权限
    var isDynamicFieldDenied: Bool {
        commonData.isDynamicFieldDenied(targetField: fieldEditModel.fieldProperty.optionsRule.targetField)
    }
    // 关联表部分无权限
    var isLinkTablePartialDenied: Bool {
        commonData.isLinkTablePartialDenied(tableID: fieldEditModel.fieldProperty.tableId)
    }
    
    var canShowAIConfig: Bool {
        return UserScopeNoChangeFG.QYK.btChatAIExtension && self.fieldEditModel.canShowAIConfig
    }
    
    var isCurrentExtendChildType: Bool {
        fieldEditModel.fieldExtendInfo != nil
    }
    
    lazy var aiExtensionButton = BTFieldCustomButton().construct { it in
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickAiExtensionButton), for: .touchUpInside)
        it.setTitleString(text: BundleI18n.SKResource.Bitable_BaseAI_AIField_GenerateWithAI_Option)
        it.setLeftIcon(image: UDIcon.intelligentAssistantFilled, showLighting: isCurrentExtendChildType)
    }
    
    ///日期字段设置view
    private lazy var dateTypeChooseButton = BTFieldCustomButton().construct { it in
        it.setLeftIconVisible(isVisible: false)
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickChooseDateType), for: .touchUpInside)
    }

    private lazy var dateAutoFillView: UIView = {
        let config = BTFieldWithSwitchItemConfig(topTitleLabel: nil,
                                                 content: BundleI18n.SKResource.Bitable_BTModule_AutoCreateTime,
                                                 isSelected: fieldEditModel.fieldProperty.autoFill)
        let view = BTFieldWithSwitchItemView(uiConfig: config)
        view.switchValueChanged = { [weak self] on in
            guard let self = self else { return }
            self.fieldEditModel.fieldProperty.autoFill = on
            self.delegate?.didClickCheckBox(isSelected: on)
        }
        return view
    }()

    private lazy var dateView = UIView().construct { it in
        let dateTypeLabel = UILabel()
        dateTypeLabel.textColor = UDColor.textPlaceholder
        dateTypeLabel.font = .systemFont(ofSize: 14)
        dateTypeLabel.text = BundleI18n.SKResource.Bitable_BTModule_DateTimeFormat

        it.backgroundColor = .clear
        it.addSubview(dateTypeLabel)
        it.addSubview(dateTypeChooseButton)
        it.addSubview(dateAutoFillView)

        dateTypeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(20)
            make.left.equalToSuperview()
            make.bottom.equalTo(dateTypeChooseButton.snp.top).offset(-2)
        }

        dateTypeChooseButton.snp.makeConstraints { make in
            make.trailing.leading.equalToSuperview()
            make.top.equalTo(dateTypeLabel.snp.bottom).offset(2)
            make.height.equalTo(52)
        }

        dateAutoFillView.snp.makeConstraints { make in
            make.trailing.leading.equalToSuperview()
            make.top.equalTo(dateTypeChooseButton.snp.bottom)
            make.height.equalTo(78)
        }
    }

    ///数字段设置view
    private lazy var numberTypeChooseButton = BTFieldCustomButton().construct { it in
        it.setLeftIconVisible(isVisible: false)
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickChooseNumberType), for: .touchUpInside)
    }
    
    ///货币字段类型设置view
    private lazy var currencyTypeChooseButton = BTFieldCustomButton().construct { it in
        it.setLeftIconVisible(isVisible: false)
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickChooseCurrencyType), for: .touchUpInside)
    }
    
    private lazy var numberTypeLabel = UILabel().construct { it in
        it.textColor = UDColor.textPlaceholder
        it.font = .systemFont(ofSize: 14)
        it.text = BundleI18n.SKResource.Bitable_Field_NumberFormat
    }
    
    private lazy var numberView = UIView().construct { it in
        it.backgroundColor = .clear
        it.addSubview(numberTypeLabel)
        it.addSubview(numberTypeChooseButton)

        numberTypeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(20)
            make.left.equalToSuperview()
            make.bottom.equalTo(numberTypeChooseButton.snp.top).offset(-2)
        }

        numberTypeChooseButton.snp.makeConstraints { make in
            make.trailing.leading.bottom.equalToSuperview()
            make.top.equalTo(numberTypeLabel.snp.bottom).offset(2)
            make.height.equalTo(52)
        }
    }
    
    private lazy var currencyView = UIView().construct { it in
        let currencyTypeLabel = UILabel()
        currencyTypeLabel.textColor = UDColor.textPlaceholder
        currencyTypeLabel.font = .systemFont(ofSize: 14)
        currencyTypeLabel.text = BundleI18n.SKResource.Bitable_Currency_Title
        
        it.backgroundColor = .clear
        it.addSubview(currencyTypeLabel)
        it.addSubview(currencyTypeChooseButton)
        
        currencyTypeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(20)
            make.left.equalToSuperview()
            make.bottom.equalTo(currencyTypeChooseButton.snp.top).offset(-2)
        }
        
        currencyTypeChooseButton.snp.makeConstraints { make in
            make.trailing.leading.equalToSuperview()
            make.top.equalTo(currencyTypeLabel.snp.bottom).offset(2)
            make.height.equalTo(52)
        }
    }

    ///数字段设置view
    private lazy var progressNumberTypeChooseButton = BTFieldCustomButton().construct { it in
        it.setLeftIconVisible(isVisible: false)
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickChooseProgressNumberType), for: .touchUpInside)
    }
    
    ///进度条段设置view
    private lazy var progressTypeChooseButton = BTFieldCustomButton().construct { it in
        it.setLeftIconVisible(isVisible: false)
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickChooseProgressType), for: .touchUpInside)
    }
    
    ///进度条段设置view
    private lazy var progressColorChooseButton = BTFieldColorButton().construct { it in
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickChooseProgressColor), for: .touchUpInside)
    }
    
    ///进度条段设置view
    private lazy var progressCustomNumberView: BTFieldWithSwitchItemView = {
        let config = BTFieldWithSwitchItemConfig(topTitleLabel: nil,
                                                 content: BundleI18n.SKResource.Bitable_Progress_CustomProgressBar,
                                                 isSelected: false)
        let view = BTFieldWithSwitchItemView(uiConfig: config)
        view.switchValueChanged = { [weak self] on in
            guard let self = self else { return }
            self.delegate?.didClickCheckBox(isSelected: on)
        }
        return view
    }()
    
    private lazy var progressCustomMinValueView: BTFieldInputView = {
        let view = BTFieldInputView(type: .min, baseContext: self.delegate?.baseContext)
        view.headLabel.text = BundleI18n.SKResource.Bitable_Progress_Minimum
        view.inputTextField.keyboardType = .decimalPad
        let kbView = BTNumberKeyboardView(target: view.inputTextField)
        view.inputTextField.inputView = kbView
        view.inputTextField.inputAccessoryView = nil
        view.didFieldInputEditBegin = { [weak self] (fieldInputView) in
            self?.delegate?.didFieldInputEditBegin(fieldInputView: fieldInputView)
        }
        view.didFieldInputEditEnd = { [weak self] (fieldInputView) in
            self?.delegate?.didFieldInputEditEnd(fieldInputView: fieldInputView)
        }
        return view
    }()
    
    private lazy var progressCustomMaxValueView: BTFieldInputView = {
        let view = BTFieldInputView(type: .max, baseContext: self.delegate?.baseContext)
        view.headLabel.text = BundleI18n.SKResource.Bitable_Progress_Maximum
        view.inputTextField.keyboardType = .decimalPad
        let kbView = BTNumberKeyboardView(target: view.inputTextField)
        view.inputTextField.inputView = kbView
        view.inputTextField.inputAccessoryView = nil
        view.didFieldInputEditBegin = { [weak self] (fieldInputView) in
            self?.delegate?.didFieldInputEditBegin(fieldInputView: fieldInputView)
        }
        view.didFieldInputEditEnd = { [weak self] (fieldInputView) in
            self?.delegate?.didFieldInputEditEnd(fieldInputView: fieldInputView)
        }
        return view
    }()
    
    private lazy var progressCustomNumberInputView: UIView = {
        let view = UIStackView()
        view.backgroundColor = UDColor.bgFloat
        view.layer.cornerRadius = 10
        view.axis = .vertical
        view.alignment = .trailing
        
        let lineView = UIView()
        lineView.backgroundColor = UDColor.lineDividerDefault
        
        view.addArrangedSubview(progressCustomMinValueView)
        view.addArrangedSubview(lineView)
        view.addArrangedSubview(progressCustomMaxValueView)
        
        progressCustomMinValueView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(52)
        }
        
        lineView.snp.makeConstraints { make in
            make.width.equalToSuperview().offset(-16)
            make.height.equalTo(0.5)
        }
        
        progressCustomMaxValueView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(52)
        }
        
        return view
    }()
    
    private lazy var progressCustomNumberInputTipsView: UILabel = {
        let view = UILabel()
        view.textColor = UDColor.functionDangerContentDefault
        view.font = UIFont.systemFont(ofSize: 12)
        return view
    }()
    
    private lazy var progressView = UIView().construct { it in
        let progressTypeLabel = UILabel()
        progressTypeLabel.textColor = UDColor.textPlaceholder
        progressTypeLabel.font = .systemFont(ofSize: 14)
        progressTypeLabel.text = BundleI18n.SKResource.Bitable_Progress_NumberFormat_Title
        
        let numberTypeLabel = UILabel()
        numberTypeLabel.textColor = UDColor.textPlaceholder
        numberTypeLabel.font = .systemFont(ofSize: 14)
        numberTypeLabel.text = BundleI18n.SKResource.Bitable_Progress_DecimalPlaces_Title
        
        let progressColorLabel = UILabel()
        progressColorLabel.textColor = UDColor.textPlaceholder
        progressColorLabel.font = .systemFont(ofSize: 14)
        progressColorLabel.text = BundleI18n.SKResource.Bitable_Progress_ProgressBarColor_Title
        

        it.backgroundColor = .clear
        it.addSubview(progressTypeLabel)
        it.addSubview(progressTypeChooseButton)
        it.addSubview(numberTypeLabel)
        it.addSubview(progressNumberTypeChooseButton)
        it.addSubview(progressColorLabel)
        it.addSubview(progressColorChooseButton)
        it.addSubview(progressCustomNumberView)
        it.addSubview(progressCustomNumberInputView)
        it.addSubview(progressCustomNumberInputTipsView)

        
        var viewHeight: CGFloat = 0
        
        progressTypeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.height.equalTo(20)
            make.left.equalToSuperview()
        }

        viewHeight += (14 + 20)
        
        progressTypeChooseButton.snp.makeConstraints { make in
            make.trailing.leading.equalToSuperview()
            make.top.equalTo(progressTypeLabel.snp.bottom).offset(2)
            make.height.equalTo(52)
        }
        
        viewHeight += (2 + 52)
        
        numberTypeLabel.snp.makeConstraints { make in
            make.top.equalTo(progressTypeChooseButton.snp.bottom).offset(14)
            make.height.equalTo(20)
            make.left.equalToSuperview()
        }
        
        viewHeight += (14 + 20)

        progressNumberTypeChooseButton.snp.makeConstraints { make in
            make.top.equalTo(numberTypeLabel.snp.bottom).offset(2)
            make.trailing.leading.equalToSuperview()
            make.height.equalTo(52)
        }
        
        viewHeight += (2 + 52)
        
        progressColorLabel.snp.makeConstraints { make in
            make.top.equalTo(progressNumberTypeChooseButton.snp.bottom).offset(14)
            make.height.equalTo(20)
            make.left.equalToSuperview()
        }
        
        viewHeight += (14 + 20)
        
        progressColorChooseButton.snp.makeConstraints { make in
            make.top.equalTo(progressColorLabel.snp.bottom).offset(2)
            make.trailing.leading.equalToSuperview()
            make.height.equalTo(52)
        }
        
        viewHeight += (2 + 52)
        
        progressCustomNumberView.snp.makeConstraints { make in
            make.trailing.leading.equalToSuperview()
            make.top.equalTo(progressColorChooseButton.snp.bottom)
            make.height.equalTo(68)
        }
        
        viewHeight += (68)
        
        progressCustomNumberInputView.snp.makeConstraints { make in
            make.trailing.leading.equalToSuperview()
            make.top.equalTo(progressCustomNumberView.snp.bottom).offset(16)
            make.height.equalTo(52 + 0.5 + 52)
        }
        
        viewHeight += (16 + 52 + 0.5 + 52)
        
        progressCustomNumberInputTipsView.snp.makeConstraints { make in
            make.trailing.leading.equalToSuperview()
            make.top.equalTo(progressCustomNumberInputView.snp.bottom).offset(4)
            make.height.equalTo(20)
        }
        
        viewHeight += (4 + 20)

        it.frame = CGRect(x: it.frame.origin.x, y: it.frame.origin.y, width: it.frame.size.width, height: viewHeight)
    }

    ///附件字段设置view
    private lazy var attachmentView: BTFieldWithSwitchItemView = {
        let config = BTFieldWithSwitchItemConfig(topTitleLabel: BundleI18n.SKResource.Bitable_Field_AttachmentUploadControl,
                                                 content: BundleI18n.SKResource.Bitable_Field_UploadViaMobileOnly,
                                                 isSelected: fieldEditModel.fieldProperty.capture.count > 0)
        let view = BTFieldWithSwitchItemView(uiConfig: config)
        view.switchValueChanged = { [weak self] on in
            guard let self = self else { return }
            self.delegate?.didClickCheckBox(isSelected: on)
        }
        return view
    }()
    
    ///扫码手动输入设置view
    private lazy var scanManulView: BTFieldWithSwitchItemView = {
        let config = BTFieldWithSwitchItemConfig(topTitleLabel: nil,
                                                 content: BundleI18n.SKResource.Bitable_Barcode_UploadOnlyViaMobile_Checkbox,
                                                 isSelected: !(fieldEditModel.allowedEditModes?.manual ?? false))
        let view = BTFieldWithSwitchItemView(uiConfig: config)
        view.switchValueChanged = { [weak self] on in
            guard let self = self else { return }
            self.delegate?.didClickCheckBox(isSelected: on)
        }
        return view
    }()
    
    ///用户字段设置view
    private lazy var userView: BTFieldWithSwitchItemView = {
        let config = BTFieldWithSwitchItemConfig(topTitleLabel: nil,
                                                 content: BundleI18n.SKResource.Bitable_Field_AddMultipleMember,
                                                 isSelected: fieldEditModel.fieldProperty.multiple)
        let view = BTFieldWithSwitchItemView(uiConfig: config)
        view.udSwitch.tapCallBack = { [weak self] sender in
            guard let self = self else { return }
            guard sender.isEnabled else {
                self.delegate?.didClickCheckBox(isSelected: sender.isOn)
                return
            }
            // UDSwitch 先 tapCallBack 之后， 才会切换按钮状态
            // 这个 callback 里面如果 updateUI 更新了 switch 状态，可能会被 UD 再次修改成错误值
            // 所以这里 async 到 UDSwitch update 按钮状态之后，再执行 callback，避免时序错误
            DispatchQueue.main.async {
                self.delegate?.didClickCheckBox(isSelected: sender.isOn)
            }
        }
        return view
    }()
    
    /// 群字段设置view
    private lazy var groupView: BTFieldWithSwitchItemView = {
        let config = BTFieldWithSwitchItemConfig(topTitleLabel: nil,
                                                 content: BundleI18n.SKResource.Bitable_Group_AllowAddingMultipleGroups_Checkbox,
                                                 isSelected: fieldEditModel.fieldProperty.multiple)
        let view = BTFieldWithSwitchItemView(uiConfig: config)
        view.switchValueChanged = { [weak self] on in
            guard let self = self else { return }
            self.delegate?.didClickCheckBox(isSelected: on)
        }
        return view
    }()
    
    lazy var linkTableChooseTableButton = constructLinkTableChooseTableButton()
    
    ///关联字段设置view
    lazy var linkTableChooseButton = BTFieldCustomButton().construct { it in
        it.setLeftIconVisible(isVisible: false)
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickChooseRelatedTable), for: .touchUpInside)
        it.setTitleString(text: BundleI18n.SKResource.Bitable_Field_SelectATable)
        it.setSubTitleString(text: BundleI18n.SKResource.Bitable_Field_Select)
    }
    
    /// 关联字段设置关联范围
    lazy var linkTableChooseRangeButton = BTFieldCustomButton().construct { it in
        it.setLeftIconVisible(isVisible: false)
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickChooseRelatedTableRange), for: .touchUpInside)
        it.setTitleString(text: BundleI18n.SKResource.Bitable_Relation_AllRecord)
    }

    /// 关联字段符合所有/任一条件view
    lazy var linkTableMeetConditionView: BTConditionConjunctionView = {
        let view = BTConditionConjunctionView()
        view.didTapConjuctionButton = {[weak self] btn in
            self?.delegate?.didClickLinkFieldFilterConjunctionButton(button: btn)
        }
        return view
    }()
    
    /// 关联字段添加过滤条件按钮
    lazy var linkTableAddFilterOptionButton = BTAddButton().construct { it in
        it.icon.image = UDIcon.addOutlined.ud.withTintColor(UDColor.primaryContentDefault)
        it.setText(text: BundleI18n.SKResource.Bitable_Relation_AddCondition)
        it.buttonIsEnabled = true
        it.addTarget(self, action: #selector(didClickAddLinkTableFilterOption), for: .touchUpInside)
    }
    
    lazy var linkCanAddMultiRecordView: BTFieldWithSwitchItemView = {
        let config = BTFieldWithSwitchItemConfig(topTitleLabel: BundleI18n.SKResource.Bitable_Relation_RecordNumSettings_Mobile,
                                                 content: BundleI18n.SKResource.Bitable_Field_AddMultipleRecord,
                                                 isSelected: fieldEditModel.fieldProperty.multiple)
        let view = BTFieldWithSwitchItemView(uiConfig: config)
        view.switchValueChanged = { [weak self] on in
            guard let self = self else { return }
            self.delegate?.didClickCheckBox(isSelected: on)
        }
        return view
    }()

    // 关联字段(支持筛选)的 HeaderView
    private lazy var linkViewWithFilter = constructLinkHeaderView()

    ///自动编号字段设置view
    private lazy var autoNumberTableListLabel = UILabel().construct { it in
        it.textColor = UDColor.textPlaceholder
        it.font = .systemFont(ofSize: 14)
        it.text = BundleI18n.SKResource.Bitable_Field_AddAutoIdRuleMobileVer
    }

    private lazy var autoNumberTypeChooseButton = BTFieldCustomButton().construct { it in
        it.setLeftIconVisible(isVisible: false)
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickChooseAutoNumberType), for: .touchUpInside)
    }

    private lazy var autoNumberPreviewView = BTAutoNumberPreviewView()

    private lazy var autoNumberView = UIView().construct { it in
        let autoNumberTypeLabel = UILabel()
        autoNumberTypeLabel.textColor = UDColor.textPlaceholder
        autoNumberTypeLabel.font = .systemFont(ofSize: 14)
        autoNumberTypeLabel.text = BundleI18n.SKResource.Bitable_Field_AutoIdTypeMobileVer

        it.backgroundColor = .clear
        it.addSubview(autoNumberTypeLabel)
        it.addSubview(autoNumberTypeChooseButton)
        it.addSubview(autoNumberPreviewView)
        it.addSubview(autoNumberTableListLabel)

        autoNumberTypeLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview()
            make.bottom.equalTo(autoNumberTypeChooseButton.snp.top).offset(-2)
        }

        autoNumberTypeChooseButton.snp.makeConstraints { make in
            make.trailing.leading.equalToSuperview()
            make.top.equalTo(autoNumberTypeLabel.snp.bottom).offset(2)
            make.height.equalTo(70)
        }

        autoNumberPreviewView.snp.makeConstraints { make in
            make.top.equalTo(autoNumberTypeChooseButton.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(autoNumberTableListLabel.snp.top).offset(-14)
        }

        autoNumberTableListLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.top.equalTo(autoNumberPreviewView.snp.bottom).offset(14)
            make.left.bottom.equalToSuperview()
        }
    }

    ///选项字段
    private lazy var staticOptionView = UIView().construct { it in
        let tableListLabel = UILabel()
        tableListLabel.textColor = UDColor.textPlaceholder
        tableListLabel.font = .systemFont(ofSize: 14)
        tableListLabel.text = BundleI18n.SKResource.Bitable_Field_AddAnOption

        it.addSubview(tableListLabel)
        tableListLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.left.equalToSuperview()
            make.bottom.equalToSuperview().offset(-2)
        }
    }
    
    // 地理位置字段设置view
    lazy var locationInputTypeChooseButton = BTFieldCustomButton().construct { it in
        it.setLeftIconVisible(isVisible: false)
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UDColor.iconN1))
        it.setTitleString(text: fieldEditModel.fieldProperty.inputType.displayText)
        it.addTarget(self, action: #selector(didClickChooseLocationInputType), for: .touchUpInside)
    }
    
    private lazy var locationView = UIView().construct { it in
        let inputTypeLabel = UILabel()
        inputTypeLabel.textColor = UDColor.textPlaceholder
        inputTypeLabel.font = .systemFont(ofSize: 14)
        inputTypeLabel.text = BundleI18n.SKResource.Bitable_Field_LocateMethodMobileVer

        it.backgroundColor = .clear
        it.addSubview(inputTypeLabel)
        it.addSubview(locationInputTypeChooseButton)

        inputTypeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview()
            make.height.equalTo(20)
            make.bottom.equalTo(locationInputTypeChooseButton.snp.top).offset(-2)
        }
        locationInputTypeChooseButton.snp.makeConstraints { make in
            make.trailing.leading.bottom.equalToSuperview()
            make.top.equalTo(inputTypeLabel.snp.bottom)
            make.height.equalTo(52)
        }
    }

    ///选项字段类型选择按钮
    private lazy var optionTypeChooseButton = BTFieldCustomButton().construct { it in
        it.setLeftIconVisible(isVisible: false)
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickOptionTypeChooseButton), for: .touchUpInside)
    }

    ///级联选项引用数据表选择按钮
    private lazy var dynamicOptionTableChooseButton = BTFieldCustomButton().construct { it in
        it.backgroundColor = .clear
        it.layer.cornerRadius = 0
        it.setLeftIconVisible(isVisible: false)
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickDynamicOptionTableChooseButton), for: .touchUpInside)
        it.setTitleString(text: BundleI18n.SKResource.Bitable_SingleOption_TargetTable_Mobile)
    }

    ///级联选项引用字段选择按钮
    private lazy var dynamicOptionFieldChooseButton = BTFieldCustomButton().construct { it in
        it.backgroundColor = .clear
        it.layer.cornerRadius = 0
        it.setButtonEnable(enable: false)
        it.setLeftIconVisible(isVisible: false)
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickDynamicOptionFieldChooseButton), for: .touchUpInside)
        it.setTitleString(text: BundleI18n.SKResource.Bitable_SingleOption_TargetField_Mobile)
    }

    ///级联选项字段引用view
    private lazy var dynamicOptionLinkView = UIView().construct { it in
        it.backgroundColor = UDColor.bgFloat
        it.clipsToBounds = true
        it.layer.cornerRadius = 10

        let separate = UIView()
        separate.backgroundColor = UDColor.lineDividerDefault

        it.addSubview(dynamicOptionTableChooseButton)
        it.addSubview(separate)
        it.addSubview(dynamicOptionFieldChooseButton)

        dynamicOptionTableChooseButton.snp.makeConstraints { make in
            make.height.equalTo(52)
            make.top.left.right.equalToSuperview()
        }

        separate.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.right.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(dynamicOptionTableChooseButton.snp.bottom).offset(-0.5)
        }

        dynamicOptionFieldChooseButton.snp.makeConstraints { make in
            make.height.equalTo(52)
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(dynamicOptionTableChooseButton.snp.bottom)
        }
    }

    ///级联选项引用条件关系view
    private lazy var dynamicOptionLinkRelationView: BTConditionConjunctionView = {
        let view = BTConditionConjunctionView()
        view.didTapConjuctionButton = {[weak self] btn in
            self?.delegate?.didClickDynamicOptionLinkRelationButton(button: btn)
        }
        return view
    }()

    private lazy var optionTypeLabel = UILabel().construct { it in
        it.textColor = UDColor.textPlaceholder
        it.font = .systemFont(ofSize: 14)
        it.text = BundleI18n.SKResource.Bitable_SingleOption_OptionContent
    }

    ///级联选项字段
    private lazy var dynamicOptionView = UIView().construct { it in
        let tableListLabel = UILabel()
        tableListLabel.textColor = UDColor.textPlaceholder
        tableListLabel.font = .systemFont(ofSize: 14)
        tableListLabel.text = BundleI18n.SKResource.Bitable_SingleOption_SubsetCondition

        let linkViewLabel = UILabel()
        linkViewLabel.textColor = UDColor.textPlaceholder
        linkViewLabel.font = .systemFont(ofSize: 14)
        linkViewLabel.text = BundleI18n.SKResource.Bitable_SingleOption_SubsetSettingsTitle

        it.addSubview(optionTypeLabel)
        it.addSubview(optionTypeChooseButton)
        it.addSubview(linkViewLabel)
        it.addSubview(dynamicOptionLinkView)
        it.addSubview(tableListLabel)
        it.addSubview(dynamicOptionLinkRelationView)

        optionTypeLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.left.equalToSuperview()
            make.top.equalToSuperview().offset(14)
        }

        optionTypeChooseButton.snp.makeConstraints { make in
            make.height.equalTo(52)
            make.left.right.equalToSuperview()
            make.top.equalTo(optionTypeLabel.snp.bottom).offset(2)
        }

        linkViewLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.left.equalToSuperview()
            make.top.equalToSuperview().offset(102)
        }

        dynamicOptionLinkView.snp.makeConstraints { make in
            make.height.equalTo(104)
            make.left.right.equalToSuperview()
            make.top.equalTo(linkViewLabel.snp.bottom).offset(2)
        }

        tableListLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.left.equalToSuperview()
            make.top.equalTo(dynamicOptionLinkView.snp.bottom).offset(14)
            make.bottom.equalTo(dynamicOptionLinkRelationView.snp.top).offset(-2)
        }

        dynamicOptionLinkRelationView.snp.makeConstraints { make in
            make.height.equalTo(52)
            make.left.right.equalToSuperview()
            make.top.equalTo(tableListLabel.snp.bottom).offset(2)
        }
    }

    @objc
    func didClickAiExtensionButton() {
        delegate?.didClickAiExtensionButton(button: aiExtensionButton)
    }
    
    @objc
    func didClickChooseDateType() {
        delegate?.didClickChooseDateType(button: dateTypeChooseButton)
    }

    @objc
    func didClickChooseNumberType() {
        delegate?.didClickChooseNumberType(button: numberTypeChooseButton)
    }
    
    @objc
    func didClickChooseCurrencyType() {
        delegate?.didClickChooseCurrencyType(button: currencyTypeChooseButton)
    }

    @objc
    func didClickChooseProgressType() {
        delegate?.didClickChooseProgressType(button: numberTypeChooseButton)
    }
    
    @objc
    func didClickChooseProgressNumberType(button: BTFieldCustomButton) {
        delegate?.didClickChooseProgressNumberType(button: numberTypeChooseButton)
    }
    
    @objc
    func didClickChooseProgressColor() {
        delegate?.didClickChooseProgressColor(button: progressColorChooseButton)
    }

    @objc
    func didClickChooseRelatedTable() {
        delegate?.didClickChooseRelatedTable(button: linkTableChooseButton)
    }

    @objc
    func didClickChooseRelatedTableRange() {
        delegate?.didClickChooseRelatedTableRange(button: linkTableChooseRangeButton)
    }
    
    @objc
    func didClickAddLinkTableFilterOption() {
        delegate?.didClickAddLinkTableFilterOption(button: linkTableAddFilterOptionButton)
    }
    
    @objc
    func didClickChooseAutoNumberType() {
        delegate?.didClickChooseAutoNumberType()
    }
    
    @objc
    func didClickChooseLocationInputType() {
        delegate?.didClickChooseLocationInputType()
    }

    @objc
    func didClickOptionTypeChooseButton() {
        OnboardingManager.shared.markFinished(for: [.bitableFieldEditDynamicIntro])
        optionTypeChooseButton.setOnboardingViewVisible(isVisible: false)
        delegate?.didClickOptionTypeChooseButton(button: optionTypeChooseButton)
    }

    @objc
    func didClickDynamicOptionTableChooseButton() {
        delegate?.didClickDynamicOptionTableChooseButton(button: dynamicOptionTableChooseButton)
    }

    @objc
    func didClickDynamicOptionFieldChooseButton() {
        delegate?.didClickDynamicOptionFieldChooseButton(button: dynamicOptionFieldChooseButton)
    }

    init(commonData: BTCommonData,
         fieldEditModel: BTFieldEditModel,
         delegate: BTFieldEditViewManagerDelegate?) {
        self.commonData = commonData
        self.fieldEditModel = fieldEditModel
        self.delegate = delegate
    }

    /// 根据字段类型构建不同的view
    func getView(commonData: BTCommonData,
                 fieldEditModel: BTFieldEditModel) -> (view: UIView, viewHeight: CGFloat)? {
        self.commonData = commonData
        self.fieldEditModel = fieldEditModel
        
        // 设置 AI 字段编辑的 编辑 / 配置文案（这里使用前端传过来的文案）
        if canShowAIConfig {
            aiExtensionButton.setSubTitleString(text: self.fieldEditModel.showAIConfigTx)
        }
        
        switch fieldEditModel.compositeType.uiType {
        case let type where type.classifyType == .date:
            dateAutoFillView.isHidden = fieldEditModel.compositeType.uiType != .dateTime
            return configDateView()
        case .number:
            return configNumberView()
        case .currency:
            numberView.removeFromSuperview()
            currencyView.addSubview(numberView)
            numberView.snp.remakeConstraints { make in
                make.top.equalTo(currencyTypeChooseButton.snp.bottom).offset(2)
                make.trailing.leading.bottom.equalToSuperview()
            }
            numberTypeLabel.text = BundleI18n.SKResource.Bitable_Progress_DecimalPlaces_Title
            return (currencyView, 176)
        case .progress:
            // 不需要传height，传默认值 0
            return (progressView, 0)
        case .attachment:
            return (attachmentView, 88)
        case let type where type.classifyType == .link:
            let filterOptionCount = fieldEditModel.fieldProperty.filterInfo?.conditions.count ?? 0
            linkTableMeetConditionView.isHidden = filterOptionCount <= 1 || fieldEditModel.isLinkAllRecord
            linkTableChooseRangeButton.isHidden = fieldEditModel.fieldProperty.tableId.isEmpty
            // 不需要传height，传默认值 0
            return (linkViewWithFilter, 0)
        case .user:
            userView.setSelected(fieldEditModel.fieldProperty.multiple)
            return (userView, 68)
        case .group:
            groupView.setSelected(fieldEditModel.fieldProperty.multiple)
            return (groupView, 68)
        case .autoNumber:
            autoNumberTableListLabel.isHidden = !fieldEditModel.fieldProperty.isAdvancedRules
            // 不需要传height，传默认值 0
            return (autoNumberView, 0)
        case let type where type.classifyType == .option:
            if fieldEditModel.fieldProperty.optionsType == .staticOption {
                if LKFeatureGating.bitableDynamicOptionsEnable {
                    //native FG控制
                    staticOptionView.addSubview(optionTypeLabel)
                    staticOptionView.addSubview(optionTypeChooseButton)

                    optionTypeLabel.snp.remakeConstraints { make in
                        make.height.equalTo(20)
                        make.left.equalToSuperview()
                        make.top.equalToSuperview().offset(14)
                    }

                    optionTypeChooseButton.snp.remakeConstraints { make in
                        make.height.equalTo(52)
                        make.left.right.equalToSuperview()
                        make.top.equalTo(optionTypeLabel.snp.bottom).offset(2)
                    }

                    optionTypeChooseButton.setTitleString(text: BundleI18n.SKResource.Bitable_SingleOption_CustomizeOptionContent)
                    optionTypeChooseButton.setOnboardingViewVisible(isVisible: !OnboardingManager.shared.hasFinished(.bitableFieldEditDynamicIntro))
                }
                return configOptionView(view: staticOptionView)
            } else {
                dynamicOptionView.addSubview(optionTypeLabel)
                dynamicOptionView.addSubview(optionTypeChooseButton)
                optionTypeLabel.snp.makeConstraints { make in
                    make.height.equalTo(20)
                    make.left.equalToSuperview()
                    make.top.equalToSuperview().offset(14)
                }

                optionTypeChooseButton.snp.makeConstraints { make in
                    make.height.equalTo(52)
                    make.left.right.equalToSuperview()
                    make.top.equalTo(optionTypeLabel.snp.bottom).offset(2)
                }
                optionTypeChooseButton.setTitleString(text: BundleI18n.SKResource.Bitable_SingleOption_SubsetFromOtherTable)
                optionTypeChooseButton.setOnboardingViewVisible(isVisible: !OnboardingManager.shared.hasFinished(.bitableFieldEditDynamicIntro))
                return configOptionView(view: dynamicOptionView)
            }
        case .location:
            return (locationView, 88)
        case .barcode:
            return (scanManulView, 68)
        case .text:
            return configTextView()
        default:
            return nil
        }
    }

    ///更新
    @discardableResult
    func updateData(commonData: BTCommonData,
                    fieldEditModel: BTFieldEditModel) -> BTFieldEditModel {
        self.commonData = commonData
        self.fieldEditModel = fieldEditModel

        switch fieldEditModel.compositeType.uiType {
        case let type where type.classifyType == .link:
            updateLinkTableHeaderData()
        case let type where type.classifyType == .date:
            var dateFormat: BTDateFieldFormat?
            if fieldEditModel.fieldProperty.dateFormat.isEmpty,
               fieldEditModel.fieldProperty.timeFormat.isEmpty {

                let defaultDataItem = commonData.fieldConfigItem.fieldItems.first(where: { $0.compositeType == fieldEditModel.compositeType })
                let defaultIndex = defaultDataItem?.property.defaultDateTimeFormatIndex ?? 0
                guard defaultIndex < commonData.fieldConfigItem.commonDateTimeList.count  else { return self.fieldEditModel }

                dateFormat = commonData.fieldConfigItem.commonDateTimeList[defaultIndex]
                if let dateFormat = dateFormat {
                    self.fieldEditModel.fieldProperty.updateDateFormat(with: dateFormat)
                }
            } else {
                dateFormat = commonData
                        .fieldConfigItem
                        .commonDateTimeList.first(where: {
                            fieldEditModel.fieldProperty.isMapDateFormat($0)
                        })
            }
            if let dateFormat = dateFormat {
                dateTypeChooseButton.setTitleString(text: dateFormat.text)
            }
        case .number, .currency, .autoNumber:
            return updateNumberData(commonData: commonData, fieldEditModel: fieldEditModel)
        case .progress:
            var formatter: String = "0"
            if let config = commonData.fieldConfigItem.getCurrentFormatConfig(fieldEditModel: fieldEditModel) {
                // 数字类型
                progressTypeChooseButton.setTitleString(text: config.typeConfig.getFormatTypeName())
                // 小数位数
                formatter = config.typeConfig.getFormatCode(decimalDigits: config.decimalDigits)
                progressNumberTypeChooseButton.setTitleString(text: config.typeConfig.getFormatDecimalDigitsName(decimalDigits: config.decimalDigits))
                DocsLogger.info("progress updateData formatter:\(formatter)")
            }
            
            // 颜色
            if let colorConfig = commonData.fieldConfigItem.getCurrentColorConfig(fieldEditModel: fieldEditModel) {
                progressColorChooseButton.setTitleString(text: colorConfig.selectedColor.name ?? "")
                progressColorChooseButton.colorView.progressColor = colorConfig.selectedColor
                DocsLogger.info("progress updateData color:\(colorConfig.selectedColor.id)")
            }
            
            // 自定义进度条
            let rangeConfig = commonData.fieldConfigItem.getCurrentRangeConfig(fieldEditModel: fieldEditModel)
            progressCustomNumberView.setSelected(rangeConfig.rangeCustomize)
            progressCustomNumberInputView.isHidden = !rangeConfig.rangeCustomize
            if rangeConfig.rangeCustomize {
                if let min = fieldEditModel.fieldProperty.min {
                    if progressCustomMinValueView.inputTextField.isEditing {
                        progressCustomMinValueView.inputTextField.text = BTFormatTypeConfig.format(min)
                    } else {
                        progressCustomMinValueView.inputTextField.text = BTFormatTypeConfig.format(value: min, formatCode: formatter)
                    }
                } else {
                    progressCustomMinValueView.inputTextField.text = ""
                }
                if let max = fieldEditModel.fieldProperty.max {
                    if progressCustomMaxValueView.inputTextField.isEditing {
                        progressCustomMaxValueView.inputTextField.text = BTFormatTypeConfig.format(max)
                    } else {
                        progressCustomMaxValueView.inputTextField.text = BTFormatTypeConfig.format(value: max, formatCode: formatter)
                    }
                } else {
                    progressCustomMaxValueView.inputTextField.text = ""
                }
                if let min = fieldEditModel.fieldProperty.min, let max = fieldEditModel.fieldProperty.max {
                    if min >= max {
                        progressCustomNumberInputTipsView.text = BundleI18n.SKResource.Bitable_Progress_TagetValueShouldGreaterThanStartValue
                    } else {
                        progressCustomNumberInputTipsView.text = ""
                    }
                } else {
                    progressCustomNumberInputTipsView.text = BundleI18n.SKResource.Bitable_Progress_PleaseEnterValue
                }
            } else {
                progressCustomNumberInputTipsView.text = ""
            }
            DocsLogger.info("progress updateData rangeCustomize:\(rangeConfig.rangeCustomize), min:\(rangeConfig.min), max:\(rangeConfig.max)")
        case let type where type.classifyType == .option:
            if LKFeatureGating.bitableDynamicOptionsEnable {
                //FG控制是否需呀显示类型选择按钮
                let buttonText = fieldEditModel.fieldProperty.optionsType == .dynamicOption ?
                BundleI18n.SKResource.Bitable_SingleOption_SubsetFromOtherTable : BundleI18n.SKResource.Bitable_SingleOption_CustomizeOptionContent
                optionTypeChooseButton.setTitleString(text: buttonText)
            }

            //级联选项
            if fieldEditModel.fieldProperty.optionsType == .dynamicOption {
                let targetTableId = fieldEditModel.fieldProperty.optionsRule.targetTable
                let targetFieldId = fieldEditModel.fieldProperty.optionsRule.targetField

                var linkFieldChooseButtonEnable = !targetTableId.isEmpty

                var linkFieldHasError = false
                var linkFieldName = BundleI18n.SKResource.Bitable_Field_Select
                if let linkField = commonData.linkTableFieldOperators.first(where: { $0.id == targetFieldId }) {
                    linkFieldName = linkField.name
                    if linkField.isDeniedField {
                        //字段无权限
                        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                            linkFieldName = BundleI18n.SKResource.Bitable_AdvancedPermission_NotAccessibleField
                        } else {
                        linkFieldName = BundleI18n.SKResource.Bitable_SingleOption_NoPermToReferencedFieldTip_Mobile
                        }
                        linkFieldHasError = true
                    } else if !(linkField.compositeType.classifyType == .option) || linkField.property.optionsType == .dynamicOption {
                        //字段类型发生了变化
                        linkFieldHasError = true
                        linkFieldName = BundleI18n.SKResource.Bitable_SingleOption_ReferencedFieldTypeChangedTip_Mobile
                    }
                } else if !targetFieldId.isEmpty {
                    linkFieldHasError = true
                    linkFieldName = BundleI18n.SKResource.Bitable_SingleOption_ReferencedFieldDeletedTip_Mobile
                }

                dynamicOptionFieldChooseButton.setWaringIconVisible(isVisible: linkFieldHasError)

                var linkTableHasError = false
                var linkTableName = BundleI18n.SKResource.Bitable_Field_Select
                if let linkTable = commonData.tableNames.first(where: { $0.tableId == targetTableId }) {
                    if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                        linkTableName = !linkTable.readPerimission ? BundleI18n.SKResource.Bitable_AdvancedPermission_NotAccessibleTable : linkTable.tableName
                    } else {
                    linkTableName = !linkTable.readPerimission ? BundleI18n.SKResource.Bitable_SingleOption_NoPermToReferencedTableTip_Mobile : linkTable.tableName
                    }
                    
                    linkTableHasError = !linkTable.readPerimission
                    linkFieldChooseButtonEnable = linkTable.readPerimission
                    if !linkTable.readPerimission {
                        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                            linkFieldName = BundleI18n.SKResource.Bitable_AdvancedPermission_NotAccessibleField
                        } else {
                        linkFieldName = BundleI18n.SKResource.Bitable_SingleOption_NoPermToReferencedFieldTip_Mobile
                        }
                    }
                } else if !targetTableId.isEmpty {
                    linkTableHasError = true
                    linkTableName = BundleI18n.SKResource.Bitable_SingleOption_ReferencedTableDeletedTip_Mobile
                    linkFieldName = BundleI18n.SKResource.Bitable_Field_Select
                }

                if linkTableHasError {
                    linkFieldChooseButtonEnable = false
                    self.fieldEditModel.fieldProperty.optionsRule.conditions.removeAll()
                    if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                        // 在引用表无权限的时候，需要展示🔒
                        if isDynamicFieldDenied || !dynamicTableReadPerimission {
                            dynamicOptionFieldChooseButton.setWaringIconVisible(isVisible: true)
                        } else {
                            dynamicOptionFieldChooseButton.setWaringIconVisible(isVisible: false)
                        }
                    } else {
                    dynamicOptionFieldChooseButton.setWaringIconVisible(isVisible: false)
                    }
                }
                if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                    if isDynamicPartNoPerimission || !dynamicTableReadPerimission {
                        // 引用表无权限 或 部分无权限 不可编辑引用字段
                        linkFieldChooseButtonEnable = false
                    }
                    if isDynamicPartNoPerimission {
                        // 级联部分无权限，🔒需要展示出来。⚠️判断代码不能加上边，会影响上边的条件判断代码执行
                        linkTableHasError = true
                    }
                }

                dynamicOptionTableChooseButton.setWaringIconVisible(isVisible: linkTableHasError)
                dynamicOptionTableChooseButton.setSubTitleString(text: linkTableName)
                dynamicOptionFieldChooseButton.setSubTitleString(text: linkFieldName)
                dynamicOptionFieldChooseButton.setButtonEnable(enable: linkFieldChooseButtonEnable)
        
                let conjunctionValue = fieldEditModel.fieldProperty.optionsRule.conjunction
                let conjunctionText = (BTConjunctionType(rawValue: conjunctionValue) ?? .And).text
                var model = BTConditionConjuctionModel(id: conjunctionValue, text: conjunctionText)
                if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                    // 级联引用字段无权限以 及 新文档且部分无权限操作下，设置为灰色，点击弹toast
                    if isDynamicFieldDenied || isDynamicPartNoPerimission {
                        model.disableAction = true
                    }
                }
                dynamicOptionLinkRelationView.configModel(model)
            }
        case .location:
            locationInputTypeChooseButton.setTitleString(text: fieldEditModel.fieldProperty.inputType.displayText)
        default:
            break
        }

        return self.fieldEditModel
    }
    
    func disableUserFieldMultipleSwitch(_ disable: Bool) {
        userView.udSwitch.isEnabled = !disable
    }
    
    private func updateNumberData(commonData: BTCommonData,
                          fieldEditModel: BTFieldEditModel) -> BTFieldEditModel {
        switch fieldEditModel.compositeType.uiType {
        case .number:
            let numberFormatList = commonData.fieldConfigItem.commonNumberFormatList
            var numberFormat = numberFormatList.first(where: { $0.formatCode == fieldEditModel.fieldProperty.formatter })
            
            if numberFormat == nil {
                let defaultNumberItem = commonData.fieldConfigItem.fieldItems.first(where: { $0.compositeType == fieldEditModel.compositeType })
                let defaultIndex = defaultNumberItem?.property.defaultNumberFormatIndex ?? 0
                
                guard defaultIndex < numberFormatList.count else { return self.fieldEditModel }
                
                numberFormat = numberFormatList[defaultIndex]
                if let numberFormat = numberFormat {
                    self.fieldEditModel.fieldProperty.formatter = numberFormat.formatCode
                }
            }
            
            if let numberFormat = numberFormat {
                numberTypeChooseButton.setTitleString(text: numberFormat.name)
                //原数据为数字字段，切选中的格式为货币字段
                if numberFormat.type == FormatterType.currency.rawValue {
                    numberTypeChooseButton.setTitleColor(color: UDColor.textPlaceholder)
                }
            }
        case .currency:
            let commonCurrencyCodeList = commonData.fieldConfigItem.commonCurrencyCodeList
            let commonCurrencyDecimalList = commonData.fieldConfigItem.commonCurrencyDecimalList
            
            let currencyCode = fieldEditModel.fieldProperty.currencyCode
            let formatter = fieldEditModel.fieldProperty.formatter
            
            guard let currencyType = commonCurrencyCodeList.first(where: { $0.currencyCode == currencyCode }),
                  let decimalType = commonCurrencyDecimalList.first(where: {
                      (currencyType.formatCode + $0.formatCode) == formatter
                  }) else {
                return self.fieldEditModel
            }
            
            currencyTypeChooseButton.setTitleString(text: currencyType.currencyCode + "-" + currencyType.currencySymbol)
            currencyTypeChooseButton.setSubTitleString(text: currencyType.name)

            numberTypeChooseButton.setTitleString(text: decimalType.name)
            numberTypeChooseButton.setTitleColor(color: UDColor.textTitle)
        case .autoNumber:
            let isAdvancedRules = fieldEditModel.fieldProperty.isAdvancedRules
            let autoNumberRuleTypelist = commonData.fieldConfigItem.commonAutoNumberRuleTypeList
            let titleText = autoNumberRuleTypelist.first(where: { $0.isAdvancedRules == isAdvancedRules })?.title ?? ""
            let description = autoNumberRuleTypelist.first(where: { $0.isAdvancedRules == isAdvancedRules })?.description ?? ""
            
            autoNumberTypeChooseButton.setTitleString(text: titleText)
            autoNumberTypeChooseButton.setDescriptionString(text: description)
        default:
            break
        }
        
        return self.fieldEditModel
    }

    /// 自动编号字段设置预览text，同时返回预览view高度
    /// - Parameter text: 预览文字
    /// - Returns: 预览view的高度
    func setautoNumberPreviewView(text: String, viewWidth: CGFloat) -> CGFloat {
        return max(autoNumberPreviewView.setText(text: text, viewWidth: viewWidth - 32) + 30, 52)
    }
    
    /// 拓展AI能力，配置 Text 字段UI
    func configTextView() -> (view: UIView, viewHeight: CGFloat)? {
        if !canShowAIConfig {
            return nil
        } else {
            let stackView = UIStackView()
            stackView.addSubview(aiExtensionButton)
            let aiExtensionButtonHeight: CGFloat = 52
            aiExtensionButton.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(14)
                make.left.right.equalToSuperview()
                make.height.equalTo(aiExtensionButtonHeight)
            }
            return (stackView, 14 + 52)
        }
    }
    
    /// 拓展AI能力，配置 Date 字段UI
    func configDateView() -> (view: UIView, viewHeight: CGFloat) {
        if !canShowAIConfig {
            return (dateView, 156)
        } else {
            let stackView = UIStackView()
            let viewHeight: CGFloat = 156
            let aiExtensionButtonHeight: CGFloat = 52
            
            stackView.addSubview(aiExtensionButton)
            aiExtensionButton.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(14)
                make.left.right.equalToSuperview()
                make.height.equalTo(aiExtensionButtonHeight)
            }
            
            stackView.addSubview(dateView)
            dateView.snp.makeConstraints { make in
                make.top.equalTo(aiExtensionButton.snp.bottom)
                make.height.equalTo(viewHeight)
                make.left.right.bottom.equalToSuperview()
            }
            return (stackView, 156 + 14 + 52)
        }
    }
    
    /// 拓展AI能力，配置 Number 字段UI
    func configNumberView() -> (view: UIView, viewHeight: CGFloat) {
        if !canShowAIConfig {
            return (numberView, 88)
        } else {
            let stackView = UIStackView()
            let viewHeight: CGFloat = 88
            let aiExtensionButtonHeight: CGFloat = 52
            
            stackView.addSubview(aiExtensionButton)
            aiExtensionButton.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(14)
                make.left.right.equalToSuperview()
                make.height.equalTo(aiExtensionButtonHeight)
            }
            
            stackView.addSubview(numberView)
            numberView.snp.makeConstraints { make in
                make.top.equalTo(aiExtensionButton.snp.bottom)
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(viewHeight)
            }
            return (stackView, viewHeight + aiExtensionButtonHeight + 14)
        }
    }
    
    /// 拓展AI能力，配置Option字段UI (单选和多选字段)
    func configOptionView(view: UIView)  -> (view: UIView, viewHeight: CGFloat) {
        var tableHeaderViewHeight: CGFloat = 212
        var specialSetViewHeight: CGFloat = 36
        if LKFeatureGating.bitableDynamicOptionsEnable {
            //FG 控制，是否显示选项类型更改按钮
            if fieldEditModel.fieldProperty.optionsType == .staticOption {
                tableHeaderViewHeight = 300 + (canShowAIConfig ? 52 + 14 : 0)
                specialSetViewHeight = 160 + (canShowAIConfig ? 52 + 14 : 0)
            } else {
                if fieldEditModel.fieldProperty.optionsRule.conditions.count > 1 {
                    //多个条件，需要展示条件组合view
                    tableHeaderViewHeight = 502 + (canShowAIConfig ? 52 + 14 : 0)
                    specialSetViewHeight = 324 + (canShowAIConfig ? 52 + 14 : 0)
                } else {
                    //单个条件
                    tableHeaderViewHeight = 440 + (canShowAIConfig ? 52 + 14 : 0)
                    specialSetViewHeight = 262 + (canShowAIConfig ? 52 + 14 : 0)
                }
            }
        }
        self.delegate?.setTableHeaderViewHeight(height: tableHeaderViewHeight)
        if !canShowAIConfig  {
            // 不需要传height，传默认值 0
            return (view, 0)
        } else {
            let stackView = UIStackView()
            let aiExtensionButtonHeight: CGFloat = 52
            stackView.addSubview(aiExtensionButton)
            aiExtensionButton.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(14)
                make.left.right.equalToSuperview()
                make.height.equalTo(aiExtensionButtonHeight)
            }
            
            stackView.addSubview(view)
            view.snp.makeConstraints { make in
                make.top.equalTo(aiExtensionButton.snp.bottom)
                make.left.right.bottom.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            // 不需要传height，传默认值 0
            return (stackView, 0)
        }
    }
}
