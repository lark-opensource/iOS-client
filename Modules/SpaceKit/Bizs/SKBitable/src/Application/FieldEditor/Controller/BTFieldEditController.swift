//
//  File.swift
//  SKBitable
//
//  Created by zoujie on 2021/11/30.
// swiftlint:disable all
import SKUIKit
import UIKit
import RxSwift
import SKBrowser
import SKResource
import SKCommon
import SKFoundation
import EENavigator
import UniverseDesignCheckBox
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignFont
import UniverseDesignActionPanel
import UniverseDesignToast
import UniverseDesignDialog
import UniverseDesignNotice
import Foundation

protocol BTFieldEditDelegate: AnyObject {
    func editViewDidDismiss()
    func trackEditViewEvent(eventType: DocsTracker.EventType,
                            params: [String: Any],
                            fieldEditModel: BTFieldEditModel)
    func addMaskViewForAiForm(animate: Bool)
}

enum BTFieldEditMode: Int {
    case edit
    case add
}

private extension BTFieldEditModel {
    enum TypeModificationDisabledReason {
        // 按需加载文档
        case partialForbidden
        
        // 不支持转换的扩展子字段（仅 owner 可转换）
        case extendForbidden
        
        var toastTips: String {
            switch self {
            case .partialForbidden:
                return BundleI18n.SKResource.Bitable_Mobile_DataOverLimitNotSupport_Desc
            case .extendForbidden:
                return BundleI18n.SKResource.Bitable_PeopleField_OnlyOwnerCanModifySettings_Description
            }
        }
    }
    
    var actionType: BTFieldActionType? {
        if let val = BTFieldActionType(rawValue: type) {
            return val
        }
        return nil
    }
    
    /// 字段类型选择禁用原因
    var typeModificationDisabledReason: TypeModificationDisabledReason? {
        if isPartial == true && actionType == .openEditPage {
            // 按需文档仅在字段编辑场景禁用（禁用字段转换）
            return .partialForbidden
        }
        if fieldExtendInfo?.editable == false {
            return .extendForbidden
        }
        return nil
    }
    
    /// 字段转换是否可用
    var isTypeModificationEnable: Bool {
        typeModificationDisabledReason == nil
    }
}

final class BTFieldEditController: UIViewController {

    weak var dataService: BTDataService?
    
    var viewModel: BTFieldEditViewModel

    let currentMode: BTFieldEditMode

    weak var delegate: BTFieldEditDelegate?

    var defaultViewHeight: CGFloat = 180

    var keyboard: Keyboard = Keyboard()

    var editingFieldCell: UITableViewCell?
    
    /// 正在发生编辑的view，需要避免被键盘遮挡
    weak var editingView: UIView?
    var editingViewKeyboardSpace: CGFloat = 0  // 键盘弹起时 与 editingView 的间距

    var editingFieldCellIndex: Int?

    var editingFieldCellHasErrorIndexs: [Int] {
        get {
            viewModel.editingFieldCellHasErrorIndexs
        }
        
        set {
            viewModel.editingFieldCellHasErrorIndexs = newValue
            setSaveButtonEnable(enable: newValue.count == 0)
        }
    }
    
    let bag = DisposeBag()

    //动态计算cell高度
    var cellHeight: [Int: CGFloat] = [:]

    ///初始预览string，用来保存时判断编号规则是否发生变化
    var initAutoNumberPreString = ""

    var commitSuccess: Bool = true

    var viewManager: BTFieldEditViewManager?
    
    var filterManager: BTFilterManager?
    
    // 扩展字段
    lazy var extendManager = BTFieldExtendManager(editMode: currentMode, service: dataService, delegate: self)

    var currentOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation

    var isFirstOpen: Bool = true

    /// 埋点字段：字段类型是 Option 的时候的曝光时间
    var optionTypeOpenTime: TimeInterval? //页面打开时机，用来选项字段上报埋点
    
    /// 埋点字段：本页的打开时机，用于做曝光时间统计埋点上报  https://bytedance.feishu.cn/sheets/shtcncmLQisYoUNgor6E4JvUiGd?sheet=D2qM2O
    let openTime: Date = Date()
    
    /// 埋点字段：启动场景，用于埋点上报 https://bytedance.feishu.cn/sheets/shtcncmLQisYoUNgor6E4JvUiGd?sheet=QtG72s
    var sceneType: String
    
    /// 埋点字段：点击提交时，是否进行过字段下细分设置(非标题和字段类型这种通用设置项)的点击，用于埋点上报 https://bytedance.feishu.cn/sheets/shtcncmLQisYoUNgor6E4JvUiGd?sheet=JrmGUA
    var hasFieldSubSettingClick: Bool = false

    ///记录上次字段名是否有错
    var lastFieldNameHasError: Bool = false {
        didSet {
            guard oldValue != lastFieldNameHasError else { return }
            //显示或隐藏错误提示label
            currentTableView.tableHeaderView?.frame.size.height += lastFieldNameHasError ? 24 : -24
            currentTableView.tableHeaderView = containerView
        }
    }

    //是否在手机横屏下，用来禁用某些控件的编辑能力
    var isPhoneLandscape: Bool {
        SKDisplay.phone && UIApplication.shared.statusBarOrientation.isLandscape
    }

    //级联选项条件列表
    var dynamicOptionsConditions: [BTDynamicOptionConditionModel] {
        get {
            return viewModel.dynamicOptionsConditions
        }

        set {
            viewModel.dynamicOptionsConditions = newValue
            guard let viewManager = viewManager,
                  let result = viewManager.getView(commonData: viewModel.commonData,
                                                 fieldEditModel: viewModel.fieldEditModel) else { return }
            let view = result.view
            configOptionUI(view: view, viewManager: viewManager)
        }
    }

    var auotNumberRuleList: [BTAutoNumberRuleOption] {
        get {
            return viewModel.auotNumberRuleList
        }

        set {
            viewModel.auotNumberRuleList = newValue
            guard let result = viewManager?.getView(commonData: viewModel.commonData,
                                                  fieldEditModel: viewModel.fieldEditModel) else { return }
            let view = result.view
            setAutoNumberPreView(view: view)
        }
    }

    //需要展示操作列表cell的字段类型
    var needShowOperateCellType: [BTFieldUIType] = [.singleSelect, .multiSelect, .autoNumber]

    var newItemID: String = "" //新增的item ID用来新增后直接进入编辑态

    // 列表滑动、其他 cell 开始侧滑时，需要把前一个 cell 的侧滑菜单收起
    let slideMutexHelper = SKSlideableTableViewCell.MutexHelper()

    var snapView: UIView?
    var startIndex: IndexPath?
    var endIndex: IndexPath?
    lazy var currentTableView = UITableView(frame: .zero, style: .plain).construct { it in
        it.backgroundColor = .clear
        it.register(BTOptionTableCell.self, forCellReuseIdentifier: reuseID + ".staticOption")
        it.register(BTAutoNumberTableCell.self, forCellReuseIdentifier: reuseID + ".autoNumber")
        it.register(BTConditionSelectCell.self, forCellReuseIdentifier: reuseID + ".condition")
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            it.register(BTConditionNoPermissionCell.self, forCellReuseIdentifier: reuseID + ".noPermission")
        }
        it.register(BTCommonItemCell.self, forCellReuseIdentifier: reuseID + ".common")
        it.dataSource = self
        it.delegate = self
        it.layer.masksToBounds = true
        it.clipsToBounds = true
        it.bounces = false
        it.separatorStyle = .none
        it.keyboardDismissMode = .onDrag
        it.estimatedRowHeight = 0
        it.estimatedSectionHeaderHeight = 0
        it.estimatedSectionFooterHeight = 0
        it.showsHorizontalScrollIndicator = false
        it.showsVerticalScrollIndicator = false
        it.contentInset = UIEdgeInsets(top: 0,
                                       left: 0,
                                       bottom: 8,
                                       right: 0)
    }
        
    private func updateLayout() {
        // 兼容旧布局
        let useFieldEditConfig = self.viewModel.fieldEditConfig.commonDataModel != nil
        currentTableView.snp.updateConstraints { make in
            make.left.right.equalTo(view.safeAreaLayoutGuide).inset(useFieldEditConfig ? 16 : 0)
        }
        titleLabel.snp.updateConstraints { make in
            make.left.equalToSuperview().inset(useFieldEditConfig ? 0 : 16)
        }

        titleInputTextViewWrapper.snp.updateConstraints { make in
            make.left.right.equalToSuperview().inset(useFieldEditConfig ? 0 : 16)
        }

        titleErrorMessageLabel.snp.updateConstraints { make in
            make.left.equalToSuperview().inset(useFieldEditConfig ? 0 : 16)
        }

        fieldTypeLabel.snp.updateConstraints { make in
            make.left.equalToSuperview().inset(useFieldEditConfig ? 0 : 16)
        }

        fieldTypeChooseButton.snp.updateConstraints { make in
            make.left.right.equalToSuperview().inset(useFieldEditConfig ? 0 : 16)
        }
    }

    var reuseID = "bitable.Field.edit"
    
    /// 需要在界面整体退出的时候通知 typeChoose
    weak var typeChoose: BTFieldCommonDataListController?

    lazy var containerView = UIView().construct { it in
        it.backgroundColor = .clear
    }

    private lazy var cancelButton = UIButton().construct { it in
        it.setTitle(BundleI18n.SKResource.Bitable_Common_ButtonCancel, for: .normal)
        it.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        it.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
        it.addTarget(self, action: #selector(didClickCancel), for: .touchUpInside)
    }

    lazy var saveButton = UIButton().construct { it in
        it.setTitle(BundleI18n.SKResource.Bitable_Common_ButtonSave, for: .normal)
        it.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        it.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
        it.addTarget(self, action: #selector(didClickSave), for: .touchUpInside)
    }

    private lazy var headerTitleLabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 17, weight: .medium)
        it.textColor = UDColor.textTitle
        it.textAlignment = .center
        it.text = BundleI18n.SKResource.Bitable_BTModule_EditField
    }

    lazy var headerView = BTOptionMenuHeaderView().construct { it in
        it.backgroundColor = UDColor.bgFloatBase
        it.setLeftView(cancelButton)
        it.setRightView(saveButton)
        it.setTitleView(headerTitleLabel)
        it.setBottomSeparatorVisible(visible: false)
    }
    
    private var extendNotice: FieldExtendExceptNotice? = nil
    
    lazy var noticeBanner: BTExtendNoticeView = {
        BTExtendNoticeView(delegate: self)
    }()
    
    lazy var specialSetView = UIView().construct { it in
        it.backgroundColor = .clear
        it.clipsToBounds = true
    }

    private lazy var titleLabel = UILabel().construct { it in
        it.textColor = UDColor.textPlaceholder
        it.font = .systemFont(ofSize: 14)
        it.text = BundleI18n.SKResource.Bitable_BTModule_FieldName
    }

    private lazy var titleErrorMessageLabel = UILabel().construct { it in
        it.textColor = UDColor.functionDangerContentDefault
        it.font = .systemFont(ofSize: 14)
    }

    private lazy var fieldTypeLabel = UILabel().construct { it in
        it.textColor = UDColor.textPlaceholder
        it.font = .systemFont(ofSize: 14)
        it.text = BundleI18n.SKResource.Bitable_BTModule_FieldType
    }

    lazy var titleInputTextView = BTConditionalTextField().construct { it in
        it.addTarget(self, action: #selector(fieldNameDidChange), for: .editingChanged)
        it.font = .systemFont(ofSize: 16)
        it.textColor = UDColor.textTitle
        it.autocorrectionType = .no
        it.spellCheckingType = .no
        it.clearButtonMode = .whileEditing
        it.returnKeyType = .done
        it.delegate = self
        it.baseContext = self.baseContext
        it.placeholder = BundleI18n.SKResource.Bitable_Field_PleaseEnterFieldName
    }

    private lazy var titleInputTextViewWrapper = UIView().construct { it in
        it.layer.cornerRadius = 10
        it.clipsToBounds = false
        it.backgroundColor = UDColor.bgFloat

        it.addSubview(titleInputTextView)

        titleInputTextView.snp.makeConstraints { make in
            make.height.equalTo(22)
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview().inset(12)
        }
    }

    private lazy var fieldTypeChooseButton = BTFieldCustomButton().construct { it in
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickChooseType(_:)), for: .touchUpInside)
    }

    lazy var aiExtensionButton = BTFieldCustomButton().construct { it in
        it.setRightIcon(image: UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3))
        it.addTarget(self, action: #selector(didClickAiExtensionButton), for: .touchUpInside)
        it.setTitleString(text: BundleI18n.SKResource.Bitable_BaseAI_AIField_GenerateWithAI_Option)
        it.setLeftIcon(image: UDIcon.intelligentAssistantFilled, showLighting: viewModel.isCurrentExtendChildType)
    }
    
    let stackView = UIStackView().construct { it in
        it.axis = .vertical
        it.backgroundColor = .clear
    }

    lazy var footerView = BTFieldEditFooter(delegate: self)

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return [.allButUpsideDown]
    }

    let baseContext: BaseContext
    
    var generateAIContent: Bool? = nil
    
    // 计算属性，判断是否可以展示 ai 接口
    var canShowAIConfig: Bool {
        return UserScopeNoChangeFG.QYK.btChatAIExtension && self.viewModel.fieldEditModel.canShowAIConfig
    }
    
    // UDActionSheet 的默认宽度
    var preferredContentWidth: CGFloat { return 350 }

    init(fieldEditModel: BTFieldEditModel,
         commonData: BTCommonData,
         currentMode: BTFieldEditMode,
         sceneType: String,
         baseContext: BaseContext,
         dataService: BTDataService?) {
        self.currentMode = currentMode
        self.sceneType = sceneType
        self.baseContext = baseContext
        self.dataService = dataService
        self.viewModel = BTFieldEditViewModel(fieldEditModel: fieldEditModel,
                                              commonData: commonData,
                                              dataService: dataService)
        super.init(nibName: nil, bundle: nil)
        viewModel.extendManager = extendManager
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        DocsLogger.btInfo("[LifeCycle] ---BTFieldEditController deinit---")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        initData()
        configUI()
        startKeyboardObserver()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentOrientation = UIApplication.shared.statusBarOrientation
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstOpen {
            isFirstOpen = false

            if viewModel.fieldEditModel.compositeType.classifyType == .option {
                optionTypeOpenTime = Date().timeIntervalSince1970
            }
        }
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        delegate?.editViewDidDismiss()
        trackStadingOptionTypeTime()
        keyboard.stop()
        
        tracingDurationViewEvent()
        // 整体退出时，如果还显示了类型选择面板，要一起触发
        self.typeChoose?.removeFromParentBlock?()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [self] _ in
            if UIApplication.shared.statusBarOrientation != currentOrientation {
                currentOrientation = UIApplication.shared.statusBarOrientation
                orientationDidChange()
            }

            if viewModel.fieldEditModel.compositeType.uiType == .autoNumber {
                //屏幕宽度发生变化，需要重新计算自动编号预览view的高度
                updateUI(fieldEditModel: viewModel.fieldEditModel)
            }

            if viewModel.fieldEditModel.compositeType.classifyType == .option,
               viewModel.fieldEditModel.fieldProperty.optionsType == .dynamicOption {
                //屏幕宽度发生变化，需要重新计算条件cell高度
                currentTableView.reloadData()
            }
        }
    }

    private func initData() {
        titleInputTextView.text = viewModel.fieldEditModel.fieldName
        
        if viewModel.fieldEditModel.compositeType.classifyType == .link {
            setupFilterManager()
            updateCellViewData()
        }

        self.viewManager = BTFieldEditViewManager(commonData: viewModel.commonData,
                                                  fieldEditModel: viewModel.fieldEditModel,
                                                  delegate: self)
        
        extendDataInit()
    }

    private func configUI() {
        view.addSubview(currentTableView)
        view.addSubview(headerView)
        view.addSubview(noticeBanner)

        containerView.addSubview(titleLabel)
        containerView.addSubview(titleErrorMessageLabel)
        containerView.addSubview(titleInputTextViewWrapper)
        containerView.addSubview(fieldTypeLabel)
        containerView.addSubview(fieldTypeChooseButton)
        containerView.addSubview(specialSetView)

        currentTableView.tableHeaderView = containerView
        currentTableView.tableHeaderView?.frame.size.height = 198
        if currentMode == .add {
            headerTitleLabel.text = BundleI18n.SKResource.Bitable_BTModule_AddField
        }
        view.backgroundColor = UDColor.bgFloatBase

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(52)
        }
        
        noticeBanner.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.equalTo(view.safeAreaLayoutGuide)
        }
        
        currentTableView.snp.makeConstraints { make in
            make.top.equalTo(noticeBanner.snp.bottom)
            make.left.right.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview().inset(view.safeAreaInsets.bottom)
        }
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.top.equalToSuperview().offset(14)
            make.left.equalToSuperview().inset(16)
            make.bottom.equalTo(titleInputTextView.snp.top).offset(-2)
        }

        titleInputTextViewWrapper.snp.makeConstraints { make in
            make.height.equalTo(52)
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
        }

        titleErrorMessageLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.height.equalTo(0)
            make.top.equalTo(titleInputTextViewWrapper.snp.bottom).offset(4)
        }

        fieldTypeLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.height.equalTo(20)
            make.top.equalTo(titleInputTextViewWrapper.snp.bottom).offset(14)
            make.bottom.equalTo(fieldTypeChooseButton.snp.top).offset(-2)
        }

        fieldTypeChooseButton.snp.makeConstraints { make in
            make.height.equalTo(52)
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(fieldTypeLabel.snp.bottom).offset(2)
        }

        specialSetView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.width.equalToSuperview().offset(-32)
            make.left.equalToSuperview().inset(16)
            make.top.equalTo(fieldTypeChooseButton.snp.bottom)
        }

        updateUI(fieldEditModel: viewModel.fieldEditModel)
    }

    private func startKeyboardObserver() {
        keyboard.on(events: [.willShow, .didShow]) { [weak self] options in
            guard let self = self else { return }
            self.handleKeyboardShow(options: options)
        }

        keyboard.on(events: [.willHide, .didHide]) { [weak self] _ in
            guard let self = self else { return }
            self.handleKeyboardHide()
        }

        keyboard.start()
    }

    private func handleKeyboardShow(options: Keyboard.KeyboardOptions) {
        if titleInputTextView.isFirstResponder, options.event == .didShow {
            delegate?.trackEditViewEvent(eventType: .bitableFieldModifyViewClick,
                                         params: ["click": "title",
                                                  "target": "none",
                                                  "action_type": self.actionTypeStringForTracking,
                                                  "scene_type": self.sceneType,
                                                  "field_type": viewModel.fieldEditModel.fieldTrackName
                                                 ],
                                         fieldEditModel: self.viewModel.fieldEditModel)
        }
        
        if let editingView = editingView as? BTFieldInputView, editingView.inputTextField.isFirstResponder, let window = editingView.window {
            let keyboardHeight = options.endFrame.height
            let inWindowRect = editingView.convert(editingView.bounds, to: window)
            let offset = (window.frame.height - inWindowRect.bottom) - keyboardHeight - editingViewKeyboardSpace
            currentTableView.transform = CGAffineTransformMakeTranslation(currentTableView.transform.tx, currentTableView.transform.ty + offset)
            return
        }
        
        guard let editingCell = editingFieldCell as? BTFieldEditCell,
              true == editingCell.inpuTextView?.isFirstResponder else { return }

        let keyboardFrameInCurrentVC = view.convert(options.endFrame, from: nil)
        let keyboardHeightInCurrentVC = view.frame.height - keyboardFrameInCurrentVC.minY
        guard keyboardHeightInCurrentVC > 0 else { return }

        if [.didShow, .didChangeFrame].contains(options.event) {
            currentTableView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(-keyboardHeightInCurrentVC)
            }
            view.layoutIfNeeded()
            if let editingCellIndex = editingFieldCellIndex,
               (editingCellIndex < self.viewModel.options.count ||
                editingCellIndex < self.auotNumberRuleList.count) {
                DispatchQueue.main.async {
                    self.currentTableView.scrollToRow(at: IndexPath(row: editingCellIndex, section: 0), at: .bottom, animated: true)
                }
            }
        }
    }

    private func handleKeyboardHide() {
        if currentTableView.transform.ty != 0 {
            currentTableView.transform = CGAffineTransformMakeTranslation(currentTableView.transform.tx, 0)
        }
        if needShowOperateCellType.contains(viewModel.fieldEditModel.compositeType.uiType) {
            currentTableView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().inset(view.safeAreaInsets.bottom)
            }
        }
    }

    func resignInputFirstResponder() {
        titleInputTextView.resignFirstResponder()
        if let editingCell = editingFieldCell as? BTFieldEditCell {
            editingCell.inpuTextView?.resignFirstResponder()
        }
        if let editingView = editingView as? BTFieldInputView {
            editingView.inputTextField.resignFirstResponder()
        }
    }

    @objc
    private func orientationDidChange() {
        resignInputFirstResponder()
        configInputEditable()
    }

    private func configInputEditable() {
        titleInputTextView.textColor = !isPhoneLandscape ? UDColor.textTitle : UDColor.textDisabled
        //隐藏新增按钮
        if needShowOperateCellType.contains(viewModel.fieldEditModel.compositeType.uiType) {
            currentTableView.reloadData()
        }
    }

    func showUDActionSheetForTypeChange(targetUIType: String, fieldType: String, sourceView: UIView, extra: [String: Any], completion: @escaping () -> Void) {
        resignInputFirstResponder()
        
        // 文案后面需要加入空格
        let title = BundleI18n.SKResource.Bitable_BaseAI_ChangeFieldType_PopUp_Title + " "
        let desc = BundleI18n.SKResource.Bitable_BaseAI_ChangeFieldType_PopUp_Desc(fieldType: fieldType)

        let textLabel = UILabel()
        textLabel.font = UDFont.title4
        textLabel.text = title + desc
        textLabel.numberOfLines = 1
        
        /// 计算iPad端popOver的宽度
        let preferredContentWidth = textLabel.intrinsicContentSize.width + 24
        let source = UDActionSheetSource(sourceView: sourceView,
                                         sourceRect: sourceView.bounds,
                                         preferredContentWidth: preferredContentWidth)
        
        let config = UDActionSheetUIConfig(isShowTitle: true, popSource: source)
        let aiActionSheet = UDActionSheet(config: config)
        aiActionSheet.setTitle(textLabel.text ?? "")
        aiActionSheet.addItem(text: BundleI18n.SKResource.Bitable_BaseAI_ChangeFieldType_PopUp_ChangeButton) { [weak self] in
            guard let self = self else { return }
            guard let aiPromptTx = extra["aiPromptTx"] as? String, let supportAIConfig = extra["checkTypeConvert"] as? Bool else {
                DocsLogger.btError("showUDActionSheetForTypeChange: can not get aiPromptTx and checkTypeConvert")
                completion()
                return
            }
            self.viewModel.fieldEditModel.canShowAIConfig = supportAIConfig
            self.viewModel.fieldEditModel.showAIConfigTx = aiPromptTx
            completion()
        }
        
        aiActionSheet.setCancelItem(text: BundleI18n.SKResource.Bitable_BaseAI_ChangeFieldType_PopUp_CancelButton) { [weak self] in
            guard let self = self else { return }
            return
        }
        
        Navigator.shared.present(aiActionSheet, from: self, completion: { [weak self] in
            guard let self = self else { return }
        })

    }
    
    func getProperty() -> [String: Any] {
        var property: [String: Any] = [:]
        property = viewModel.createNormalCommitChangeProperty()
        if viewModel.fieldEditModel.compositeType.uiType == .duplexLink,
           viewModel.oldFieldEditModel.fieldProperty.tableId != viewModel.fieldEditModel.fieldProperty.tableId {
            if let currentTableName = viewModel.fieldEditModel.tableNameMap.first(where: { $0.tableId == viewModel.fieldEditModel.tableId })?.tableName {
                property["backFieldName"] = currentTableName + "-" + viewModel.fieldEditModel.fieldName
            }
        }
        return property
    }
    
    func showUDActionSheetForAI() {
        resignInputFirstResponder()
        let completion: (Result<CheckConfirmResult, Error>) -> Void =  { [weak self] result in
            guard let self = self else {
                DocsLogger.error("checkConfirm failed, self is nil")
                return
            }
            self.dismiss(animated: true)
        }
        var property = getProperty()
        
        
        let fieldInfo = self.viewModel.getJSFieldInfoArgs(editMode: self.currentMode, fieldEditModel: self.viewModel.fieldEditModel)
        var args = BTCheckConfirmAPIArgs(tableID: self.viewModel.fieldEditModel.tableId,
                                         viewID: self.viewModel.fieldEditModel.viewId,
                                         fieldInfo: fieldInfo,
                                         property: property,
                                         extraParams: nil,
                                         generateAIContent: generateAIContent)
        
        let source = UDActionSheetSource(sourceView: saveButton,
                                         sourceRect: saveButton.bounds,
                                         preferredContentWidth: preferredContentWidth)
        
        let config = UDActionSheetUIConfig(isShowTitle: false, popSource: source)

        let aiActionSheet = UDActionSheet(config: config)
        aiActionSheet.addItem(text: BundleI18n.SKResource.Bitable_BaseAI_Mobile_FieldConfigurationOnly_Option) { [weak self] in
            guard let self = self else { return }
            self.generateAIContent = false
            self.handleChangeCommit(shouldCheckConfirm: true, checkConfirmValue: nil)
        }
        
        aiActionSheet.addItem(text: BundleI18n.SKResource.Bitable_BaseAI_Mobile_AIGenerate_Option) { [weak self] in
            guard let self = self else { return }
            self.generateAIContent = true
            self.handleChangeCommit(shouldCheckConfirm: true, checkConfirmValue: nil)
        }
        
        aiActionSheet.setCancelItem(text: BundleI18n.SKResource.Bitable_BaseAI_Mobile_Cancel_Option, action: nil)
        
        Navigator.shared.present(aiActionSheet, from: self, completion: nil)
    }
    
    @objc
    func didClickChooseType(_ sender: BTFieldCustomButton) {
        guard sender.enable else {
            if UserScopeNoChangeFG.ZYS.loadRecordsOnDemand {
                if let reason = viewModel.fieldEditModel.typeModificationDisabledReason {
                    UDToast.showTips(with: reason.toastTips, on: self.view)
                }
                return
            }
            // 待删除的代码
            if viewModel.fieldEditModel.fieldExtendInfo?.editable == false {
                UDToast.showTips(with: BundleI18n.SKResource.Bitable_PeopleField_OnlyOwnerCanModifySettings_Description, on: self.view)
            }
            return
        }
        resignInputFirstResponder()
        let selectedType = viewModel.commonData.fieldConfigItem.fieldItems.first { $0.compositeType == viewModel.fieldEditModel.compositeType }

        var lastSelectedIndexPath: IndexPath?
        var data = viewModel.commonData.fieldConfigItem.fieldItems.map { fieldItem -> BTFieldCommonData in
            var item = BTFieldCommonData(id: fieldItem.compositeType.typesId,
                                         subID: "",
                                         name: fieldItem.title,
                                         groupId: fieldItem.groupId,
                                         enable: fieldItem.enable,
                                         icon: fieldItem.compositeType.icon())
            
            if let onBoardingID = BTFieldEditConfig.onBoardingID(fieldType: fieldItem.compositeType) {
                item.isShowNew = !OnboardingManager.shared.hasFinished(onBoardingID)
            }
            if (UserScopeNoChangeFG.ZYS.fieldSupportExtend) {
                let isExtType = fieldItem.compositeType.isSupportFieldExt
                let showExtNew = isExtType && !OnboardingManager.shared.hasFinished(OnboardingID.bitableUserFieldExtendNew)
                item.isShowNew = item.isShowNew || showExtNew
            }
            return item
        }
        
        if let group = extendManager.extendableFields, !group.fields.isEmpty {
            data.append(contentsOf: group.fields.map({ origin in
                var item = BTFieldCommonData(
                    id: origin.fieldId,
                    name: origin.fieldName,
                    groupId: group.groupName,
                    icon: origin.compositeType.icon(),
                    rightIocnType: .arraw,
                    selectedType: .none,
                    reference: origin
                )
                if UserScopeNoChangeFG.ZYS.fieldSupportExtend {
                    item.isShowNew = !OnboardingManager.shared.hasFinished(OnboardingID.bitableUserFieldExtendNew)
                }
                return item
            }))
        }

        // 如果当前字段是扩展子字段，无需设置选中态（其选中态在二级子页面体现）
        if !viewModel.isCurrentExtendChildType, let groupItems = data.aggregateByGroupID() as? [[BTFieldCommonData]] {
            for (i, datas) in groupItems.enumerated() {
                for (j, data) in datas.enumerated() {
                    // 如果是扩展字段列表中的 item，不参与选中态的匹配（类型可能重复）
                    let isNotExtendItem = data.groupId != extendManager.extendableFields?.groupName
                    if isNotExtendItem, data.id == viewModel.fieldEditModel.compositeType.typesId {
                        lastSelectedIndexPath = IndexPath(row: j, section: i)
                    }
                }
            }
        }

        let initViewHeightBlock: (() -> CGFloat) = { [weak self] in
            (self?.view.window?.bounds.height ?? SKDisplay.activeWindowBounds.height)
        }

        let typeChoose = BTFieldCommonDataListController(data: data,
                                                         title: BundleI18n.SKResource.Bitable_BTModule_FieldType,
                                                         action: BTFieldEditDataListViewAction.updateFieldType.rawValue,
                                                         shouldShowDragBar: false,
                                                         relatedItemId: "",
                                                         disableItemClickBlock: { (hostVc, _) in
            UDToast.showWarning(with: BundleI18n.SKResource.Bitable_Field_PleaseModifyOnDesktop,
                                on: hostVc.view)
        },
                                                         lastSelectedIndexPath: lastSelectedIndexPath,
                                                         initViewHeightBlock: initViewHeightBlock)

        self.typeChoose = typeChoose
        typeChoose.delegate = self

        self.delegate?.trackEditViewEvent(eventType: .bitableFieldModifyViewClick,
                                          params: ["click": "field_type",
                                                   "target": "ccm_bitable_field_type_modify_view",
                                                   "action_type": self.actionTypeStringForTracking,
                                                   "scene_type": self.sceneType,
                                                   "field_type": viewModel.fieldEditModel.fieldTrackName],
                                          fieldEditModel: viewModel.fieldEditModel)
        let typeChooseOpenTime = Date()
        // 这里用的 push，则下方对应 popbackBlock，保持联动
        Navigator.shared.push(typeChoose,
                              from: self,
                              animated: true) { [weak self] in
            guard let compositeType = selectedType?.compositeType else {
                DocsLogger.warning("selectedType is nil")
                return
            }
            guard let self = self else {
                DocsLogger.warning("target released")
                return
            }
            self.delegate?.trackEditViewEvent(eventType: .bitableFieldTypeModifyView,
                                              params: ["field_type": compositeType.fieldTrackName,
                                                       "is_index_column": self.viewModel.fieldEditModel.fieldIndex == 0,
                                                       "edit_type": self.editTypeStringForTracking,
                                                       "scene_type": self.sceneType],
                                              fieldEditModel: self.viewModel.fieldEditModel)
        }
        typeChoose.removeFromParentBlock = { [weak self] in
            guard let self = self else {
                DocsLogger.warning("target released")
                return
            }
            self.typeChoose = nil
            self.delegate?.trackEditViewEvent(eventType: .bitableFieldTypeModifyDurationView,
                                              params: ["field_type": self.viewModel.fieldEditModel.fieldTrackName,
                                                       "edit_type": self.editTypeStringForTracking,
                                                       "duration": Int((Date().timeIntervalSince(typeChooseOpenTime)) * 1000)],
                                              fieldEditModel: self.viewModel.fieldEditModel)
        }
    }
    
    @objc
    func onNoticeBannerButtonTapped(_ sender: UIButton) {
        
    }

    @objc
    func didClickCancel() {
        resignInputFirstResponder()
        let trackString = self.viewModel.fieldEditModel.fieldTrackName
        delegate?.trackEditViewEvent(eventType: .bitableFieldModifyViewClick,
                                          params: ["click": "cancel",
                                                   "field_type": trackString,
                                                   "target": "ccm_bitable_field_modify_cancel_confirm_view"],
                                          fieldEditModel: viewModel.fieldEditModel)
        showConfirmActionPanel()
    }

    @objc
    func didClickSave() {
        viewModel.fieldEditConfig.checkBeforeSave { [weak self] continueSave in
            if continueSave {
                self?.handleSave()
            } else {
                DocsLogger.info("save canceled")
            }
        }
    }
    
    func handleSave() {
        let realText = titleInputTextView.text?.trim()
        viewModel.fieldEditModel.fieldName = realText ?? ""
        if !viewModel.fieldEditModel.allowEmptyTitle && (realText?.isEmpty ?? true) {
            //字段名为空在点击save时报错
            titleErrorMessageLabel.snp.updateConstraints { make in
                make.height.equalTo(20)
            }

            fieldTypeLabel.snp.updateConstraints { make in
                make.top.equalTo(titleInputTextViewWrapper.snp.bottom).offset(38)
            }

            titleErrorMessageLabel.text = BundleI18n.SKResource.Bitable_Field_TitleIsRequired
            setSaveButtonEnable(enable: false)
            commitSuccess = false
            lastFieldNameHasError = true
            return
        }
        lastFieldNameHasError = false
        resignInputFirstResponder()
        
        if viewModel.fieldEditModel.compositeType.uiType == .progress {
            viewModel.verifyProgress()
            
            let (success, msg) = viewModel.verifyProgress()
            if !success, let msg = msg {
                UDToast.showWarning(with: msg, on: self.view)
                return
            }
        }

        //非新增的，初始为自动编号字段且编号规则发生变化，需要弹二次确认框
        if currentMode == .edit {
            if viewModel.autoNumberShouldShowConfirmPanel() {
                autoNumberSaveConfirmActionPanel(clickItemCallback: { [weak self] in
                    guard let self = self else {
                        DocsLogger.error("handleChangeCommit after autoNumberSaveConfirmActionPanel error, self is nil")
                        return
                    }
                    if self.currentMode == .edit {
                        self.handleChangeCommit(shouldCheckConfirm: true, checkConfirmValue: nil)
                    } else {
                        self.handleChangeCommit(shouldCheckConfirm: false, checkConfirmValue: nil)
                    }
                })
                return
            }
        }
        
        viewModel.setAutoNumberReformatExistingRecord()

        if viewModel.fieldEditModel.compositeType.classifyType == .option &&
           viewModel.fieldEditModel.fieldProperty.optionsType == .dynamicOption {
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                if !viewModel.verifyTargetTable() {
                    //需要选择引用数据表和引用字段
                    UDToast.showWarning(with: BundleI18n.SKResource.Bitable_SingleOption_PleaseSelectReferencedDataToast_Mobile, on: self.view)
                    return
                }
            } else {
            if !viewModel.verifyTargetTable() ||
                !viewModel.verifyTargetField() {
                //需要选择引用数据表和引用字段
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_SingleOption_PleaseSelectReferencedDataToast_Mobile, on: self.view)
                return
            }
            }

            if !viewModel.verifyCondition() {
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_SingleOption_PleaseFillInConditionToast_Mobile, on: self.view)
                return
            }
        }
        
        let verifyLinkField = viewModel.verifyLinkFieldCommitData()
        if !verifyLinkField.isValid {
            UDToast.showWarning(with: verifyLinkField.invalidMsg ?? "", on: self.view)
            return
        }

        if currentMode == .add {
            handleChangeCommit(shouldCheckConfirm: false, checkConfirmValue: nil)
        } else {
            self.generateAIContent = nil
            checkConfirm { [weak self] result in
                guard let self = self else {
                    DocsLogger.btError("checkConfirm failed, self is nil")
                    return
                }
                switch result {
                case .success(let checkConfirmResult):
                    switch checkConfirmResult.type {
                    case .ConfirmAIGenerate:
                        self.generateAIContent = true
                        self.showUDActionSheetForAI()
                    default:
                        self.generateAIContent = false
                        self.handleChangeCommit(shouldCheckConfirm: true, checkConfirmValue: nil)
                    }
                case .failure(let error):
                    self.handleChangeCommit(shouldCheckConfirm: false, checkConfirmValue: nil)
                    spaceAssertionFailure("checkConfirm error, downgrade to handleChangeCommit")
                }
            }
        }
        trackOnSaveButtonClick()
    }

    @objc
    func didClickAdd(sender: BTAddButton) {
        guard !isPhoneLandscape else {
            UDToast.showWarning(with: BundleI18n.SKResource.Doc_Block_NotSupportEditInLandscape, on: self.view)
            return
        }
        hasFieldSubSettingClick = true
        if viewModel.fieldEditModel.compositeType.classifyType == .option,
           viewModel.fieldEditModel.fieldProperty.optionsType == .dynamicOption {
            delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                         params: ["click": "add_condition",
                                                  "target": "none"],
                                         fieldEditModel: viewModel.fieldEditModel)
        }
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            if viewModel.fieldEditModel.compositeType.classifyType == .option {
                if viewModel.isDynamicFieldDenied || viewModel.isDynamicPartNoPerimission {
                    UDToast.showWarning(with: BundleI18n.SKResource.Bitable_DataReference_NoPermToEditReferenceConditionDueToInaccessibleReferenceTable_Tooltip, on: view)
                    return
                }
            }
        }
        guard sender.buttonIsEnabled else {
            if viewModel.fieldEditModel.compositeType.classifyType == .option,
               viewModel.fieldEditModel.fieldProperty.optionsType == .dynamicOption,
               !viewModel.verifyTargetTable() {
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_SingleOption_SelectTableThenAddConditionToast_Mobile, on: self.view)
            }
            return
        }
        resignInputFirstResponder()

        if viewModel.fieldEditModel.compositeType.uiType == .autoNumber {
            presentAutoNumberRuleSelecteController()
            return
        }


        if viewModel.fieldEditModel.compositeType.classifyType == .option {
            didAddOptionItem()
        }
    }

    @objc
    func fieldNameDidChange() {
        setSaveButtonEnable()
        viewModel.fieldEditModel.fieldName = titleInputTextView.text ?? ""
        commitSuccess = true

        let (verifyNameOK, message) = viewModel.verifyFieldName()
        titleErrorMessageLabel.text = message
        
        guard verifyNameOK == lastFieldNameHasError else { return }

        lastFieldNameHasError = !verifyNameOK
        if !verifyNameOK {
            titleErrorMessageLabel.snp.updateConstraints { make in
                make.height.equalTo(20)
            }

            fieldTypeLabel.snp.updateConstraints { make in
                make.top.equalTo(titleInputTextViewWrapper.snp.bottom).offset(38)
            }
        } else {
            titleErrorMessageLabel.snp.updateConstraints { make in
                make.height.equalTo(0)
            }

            fieldTypeLabel.snp.updateConstraints { make in
                make.top.equalTo(titleInputTextViewWrapper.snp.bottom).offset(14)
            }
        }
    }

    func didAddOptionItem() {
        if LKFeatureGating.bitableDynamicOptionsEnable,
           viewModel.fieldEditModel.compositeType.classifyType == .option,
           viewModel.fieldEditModel.fieldProperty.optionsType == .dynamicOption {
            //添加级联选项规则
            viewModel.didAddOptionItem() { [weak self] _ in
                guard let self = self else { return }
                self.updateUI(fieldEditModel: self.viewModel.fieldEditModel)
                self.currentTableView.reloadData()
                self.currentTableView.layoutIfNeeded()
                self.currentTableView.scrollToRow(at: IndexPath(row: max(self.dynamicOptionsConditions.count - 1, 0), section: 0), at: .bottom, animated: false)
            }
        } else {
            //添加静态选项
            self.delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                              params: ["click": "add_option",
                                                       "target": "none"],
                                              fieldEditModel: viewModel.fieldEditModel)
            viewModel.didAddOptionItem() { [weak self] optionId in
                guard let self = self, let optionId = optionId else { return }
                self.newItemID = optionId
                self.configOptionFooter()
                self.adjustFooterContentHeight()
                self.currentTableView.reloadData()
                self.currentTableView.layoutIfNeeded()
                self.currentTableView.scrollToRow(at: IndexPath(row: max(self.viewModel.options.count - 1, 0), section: 0), at: .bottom, animated: false)
            }
        }
    }

    ///数据校验后提交修改到前端
    // swiftlint:disable cyclomatic_complexity
    func handleChangeCommit(shouldCheckConfirm: Bool, checkConfirmValue: [String: Any]?) {
        if shouldCheckConfirm, checkConfirmValue != nil {
            spaceAssertionFailure("invaild params, please check code")
        }
        if shouldCheckConfirm {
            DocsLogger.info("call handleCheckConfirm")
            handleCheckConfirm()
            // 这里需要return，避免checkConfirm后直接commitChange
            return
        }
        commitChange(checkConfirmValue: checkConfirmValue) { failReason in
            if let reason = failReason {
                DocsLogger.btError("field edit commit failed")
                switch reason {
                case .nameRepeat:
                    self.setTitleErrorMessage(message: BundleI18n.SKResource.Bitable_Field_NameExists)
                case .holding:
                    DocsLogger.info("setFieldAttr return holding, not close window")
                default:
                    UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Common_UnableToSave, on: self.view)
                }
                self.setSaveButtonEnable(enable: false)
                self.commitSuccess = false
                self.titleInputTextView.text = self.titleInputTextView.text?.trim()
                return
            }

            self.dismiss(animated: true)
        }
        var params = ["click": "confirm",
                      "target": "none",
                      "action_type": self.actionTypeStringForTracking,
                      "scene_type": self.sceneType,
                      "field_type": viewModel.fieldEditModel.fieldTrackName]
        params["from_field_type"] = currentMode != .add ? viewModel.oldFieldEditModel.fieldTrackName : nil
        delegate?.trackEditViewEvent(eventType: .bitableFieldModifyViewClick,
                                          params: params,
                                          fieldEditModel: viewModel.fieldEditModel)

        if viewModel.fieldEditModel.compositeType.classifyType == .option {
            let stringForTrack = viewModel.fieldEditModel.fieldTrackName
            let isDynamicOptions = viewModel.fieldEditModel.fieldProperty.optionsType == .dynamicOption
            delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                         params: ["click": "confirm",
                                                  "field_type": stringForTrack,
                                                  "option_content": isDynamicOptions ? "quote_data" : "custom_data",
                                                  "condition_num": isDynamicOptions ? viewModel.fieldEditModel.fieldProperty.optionsRule.conditions.count : 0,
                                                  "quote_file_id": isDynamicOptions ? viewModel.dynamicOptionRuleTargetField.encryptToken : "",
                                                  "quote_table_id": isDynamicOptions ? viewModel.dynamicOptionRuleTargetTable.encryptToken : "",
                                                  "target": "none"],
                                         fieldEditModel: viewModel.fieldEditModel)
        }

        tracingSpecialFieldTypeSaveEvent()
        
        tracingFiledSubSettingClick()
    }
    
    func handleCheckConfirm() {
        checkConfirm { [weak self] result in
            guard let self = self else {
                DocsLogger.error("checkConfirm failed, self is nil")
                return
            }
            switch result {
            case .success(let checkConfirmResult):
                DocsLogger.info("checkConfirm callback, result.type is \(checkConfirmResult.type.rawValue)")
                let indexFieldType = checkConfirmResult.extra?["indexFieldType"] as? String
                let selfFieldType = self.viewModel.fieldEditModel.fieldTrackName
                switch checkConfirmResult.type {
                case .SetFieldAttr:
                    DocsLogger.info("checkConfirm type is SetFieldAttr and call handleChangeCommit")
                    self.handleChangeCommit(shouldCheckConfirm: false, checkConfirmValue: nil)
                case .ConfirmConvertType:
                    let alert = UDDialog()
                    alert.setTitle(text: BundleI18n.SKResource.Bitable_Relation_ConvertToRelationField_ConfirmToConvert_Title)
                    alert.setContent(text: BundleI18n.SKResource.Bitable_Relation_ConvertToRelationField_ConfirmToConvert_Description_Mobile)
                    alert.addSecondaryButton(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel) { [weak self] in
                        guard let self = self else {
                            DocsLogger.error("ccm_bitable_relation_switch_no_add_warning_toast_click error, self is nil")
                            return
                        }
                        DocsLogger.info("click ConfirmConvertType dialog cancel button")
                        if let dele = self.delegate {
                            dele.trackEditViewEvent(
                                eventType: .bitableRelationSwitchNoAddWarningToastClick,
                                params: [
                                    "click": "cancel",
                                    "target": "none",
                                    "index_field_type": indexFieldType,
                                    "self_field_type": selfFieldType
                                ],
                                fieldEditModel: self.viewModel.fieldEditModel
                            )
                        } else {
                            DocsLogger.error("ccm_bitable_relation_switch_no_add_warning_toast_click error, delegate is nil")
                        }
                    }
                    alert.addPrimaryButton(text: BundleI18n.SKResource.Bitable_Common_Confirm_Button) { [weak self] in
                        guard let self = self else {
                            DocsLogger.error("handleChangeCommit error, self is nil")
                            return
                        }
                        DocsLogger.info("click ConfirmConvertType dialog cancel button and call handleChangeCommit")
                        self.handleChangeCommit(shouldCheckConfirm: false, checkConfirmValue: nil)
                        if let dele = self.delegate {
                            dele.trackEditViewEvent(
                                eventType: .bitableRelationSwitchNoAddWarningToastClick,
                                params: [
                                    "click": "confirm",
                                    "target": "ccm_bitable_relation_change_toast_view",
                                    "index_field_type": indexFieldType,
                                    "self_field_type": selfFieldType
                                ],
                                fieldEditModel: self.viewModel.fieldEditModel
                            )
                        } else {
                            DocsLogger.error("ccm_bitable_relation_switch_no_add_warning_toast_click, delegate is nil")
                        }
                    }
                    DocsLogger.info("checkConfirm type is ConfirmConvertType and present dialog")
                    self.present(alert, animated: true)
                    if let dele = self.delegate {
                        dele.trackEditViewEvent(eventType: .bitableRelationSwitchNoAddWarningToastView,
                                                params: [
                                                    "index_field_type": indexFieldType,
                                                    "self_field_type": selfFieldType
                                                ],
                                                fieldEditModel: self.viewModel.fieldEditModel)
                    } else {
                        DocsLogger.error("ccm_bitable_relation_switch_no_add_warning_toast_view error, delegate is nil")
                    }
                case .ConfirmKeepNoExistData:
                    let linkTableName = checkConfirmResult.extra?["linkTableName"] as? String
                    if linkTableName == nil {
                        spaceAssertionFailure("linkTableName from frontend is nil")
                    }
                    let sourceView: UIView = (SKDisplay.pad ? self.saveButton : self.view) ?? .init()
                    let source = UDActionSheetSource(sourceView: sourceView, sourceRect: sourceView.bounds, preferredContentWidth: self.preferredContentWidth)
                    let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true, popSource: source))
                    actionSheet.setTitle(BundleI18n.SKResource.Bitable_Relation_ConvertToRelationField_KeepData_Title(linkTableName ?? ""))
                    actionSheet.addDefaultItem(text: BundleI18n.SKResource.Bitable_Relation_ConvertToRelationField_KeepUnmatchedData_Description_Mobile) { [weak self] in
                        guard let self = self else {
                            DocsLogger.error("ConvertToRelationField_KeepUnmatchedData error, self is nil")
                            return
                        }
                        DocsLogger.info("click ConfirmKeepNoExistData actionsheet KeepUnmatchedData button and call handleChangeCommit")
                        self.handleChangeCommit(shouldCheckConfirm: false, checkConfirmValue: ["shouldSyncToLinkedTable": true])
                        if let dele = self.delegate {
                            dele.trackEditViewEvent(
                                eventType: .bitableRelationSwitchCanAddWarningToastClick,
                                params: [
                                    "click": "confirm",
                                    "target": "ccm_bitable_relation_change_toast_view",
                                    "record_keep_type": "true",
                                    "index_field_type": indexFieldType,
                                    "self_field_type": selfFieldType
                                ],
                                fieldEditModel: self.viewModel.fieldEditModel
                            )
                        } else {
                            DocsLogger.error("ccm_bitable_relation_switch_can_add_warning_toast_server KeepUnmatchedData error, delegate is nil")
                        }
                    }
                    actionSheet.addDefaultItem(text: BundleI18n.SKResource.Bitable_Relation_ConvertToRelationField_DoNotKeepUnmatchedData_Description) { [weak self] in
                        guard let self = self else {
                            DocsLogger.error("ConvertToRelationField_DoNotKeepUnmatchedData error, self is nil")
                            return
                        }
                        DocsLogger.info("click ConfirmKeepNoExistData actionsheet DoNotKeepUnmatchedData button and call handleChangeCommit")
                        self.handleChangeCommit(shouldCheckConfirm: false, checkConfirmValue: ["shouldSyncToLinkedTable": false])
                        if let dele = self.delegate {
                            dele.trackEditViewEvent(
                                eventType: .bitableRelationSwitchCanAddWarningToastClick,
                                params: [
                                    "click": "confirm",
                                    "target": "ccm_bitable_relation_change_toast_view",
                                    "record_keep_type": "false",
                                    "index_field_type": indexFieldType,
                                    "self_field_type": selfFieldType
                                ],
                                fieldEditModel: self.viewModel.fieldEditModel
                            )
                        } else {
                            DocsLogger.error("ccm_bitable_relation_switch_can_add_warning_toast_server DoNotKeepUnmatchedData error, delegate is nil")
                        }
                    }
                    actionSheet.setCancelItem(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel) { [weak self] in
                        guard let self = self else {
                            DocsLogger.error("ccm_bitable_relation_switch_can_add_warning_toast_server cancel error, self is nil")
                            return
                        }
                        DocsLogger.info("click ConfirmKeepNoExistData actionsheet cancel button")
                        if let dele = self.delegate {
                            dele.trackEditViewEvent(
                                eventType: .bitableRelationSwitchCanAddWarningToastClick,
                                params: [
                                    "click": "cancel",
                                    "target": "none",
                                    "index_field_type": indexFieldType,
                                    "self_field_type": selfFieldType
                                ],
                                fieldEditModel: self.viewModel.fieldEditModel
                            )
                        } else {
                            DocsLogger.error("ccm_bitable_relation_switch_can_add_warning_toast_server cancel error, delegate is nil")
                        }
                    }
                    DocsLogger.info("checkConfirm type is ConfirmConvertType and present actionSheet")
                    self.present(actionSheet, animated: true)
                    if let dele = self.delegate {
                        dele.trackEditViewEvent(eventType: .bitableRelationSwitchCanAddWarningToastView,
                                                params: [
                                                    "index_field_type": indexFieldType,
                                                    "self_field_type": selfFieldType
                                                ],
                                                fieldEditModel: self.viewModel.fieldEditModel)
                    } else {
                        DocsLogger.error("ccm_bitable_relation_switch_can_add_warning_toast_view error, delegate is nil")
                    }
                case .ConfirmConvertPeople:
                    let fromFieldType = self.viewModel.oldFieldEditModel.fieldTrackName
                    let alt = UDDialog()
                    let content = ConvertUserAlertContentView()
                    alt.setContent(view: content)
                    alt.addSecondaryButton(
                        text: BundleI18n.SKResource.Bitable_Common_Cancel_Button,
                        dismissCompletion: {
                            if let dele = self.delegate {
                                dele.trackEditViewEvent(eventType: .bitableDatabaseSwitchToastClick,
                                                        params: [
                                                            "click": "cancel",
                                                            "from_field_type": fromFieldType,
                                                            "to_field_type": "person"
                                                        ],
                                                        fieldEditModel: self.viewModel.fieldEditModel)
                            } else {
                                DocsLogger.error("ccm_bitable_database_switch_toast_view error, delegate is nil")
                            }
                        }
                    )
                    alt.addPrimaryButton(
                        text: BundleI18n.SKResource.Bitable_Common_Confirm_Button,
                        dismissCompletion: { [weak self, weak content] in
                            guard let self = self else {
                                DocsLogger.error("showConvertUserAlert failed, self is nil")
                                return
                            }
                            let value: Bool
                            if let content = content {
                                value = content.check.isSelected
                            } else {
                                value = true
                                DocsLogger.error("showConvertUserAlert error, content is nil, and set value true")
                            }
                            self.handleChangeCommit(shouldCheckConfirm: false, checkConfirmValue: ["shouldCreateNewPeopleField": value])
                            if let dele = self.delegate {
                                dele.trackEditViewEvent(eventType: .bitableDatabaseSwitchToastClick,
                                                        params: [
                                                            "click": "confirm",
                                                            "from_field_type": fromFieldType,
                                                            "to_field_type": "person",
                                                            "is_create_new_column": value
                                                        ],
                                                        fieldEditModel: self.viewModel.fieldEditModel)
                            } else {
                                DocsLogger.error("ccm_bitable_database_switch_toast_view error, delegate is nil")
                            }
                        }
                    )
                    alt.setTitle(text: BundleI18n.SKResource.Bitable_PeopleField_Conversion_Title)
                    self.present(alt, animated: true)
                    if let dele = self.delegate {
                        dele.trackEditViewEvent(eventType: .bitableDatabaseSwitchToastView,
                                                params: [
                                                    "from_field_type": fromFieldType,
                                                    "to_field_type": "person"
                                                ],
                                                fieldEditModel: self.viewModel.fieldEditModel)
                    } else {
                        DocsLogger.error("ccm_bitable_database_switch_toast_view error, delegate is nil")
                    }
                case .ConfirmExtendFieldDelete:
                    let alert = UDDialog()
                    let names = checkConfirmResult.extra?["names"] as? String ?? " "
                    let content = BundleI18n.SKResource.Bitable_PeopleField_ThisActionWillDeleteFields_Description(names)
                    alert.setTitle(text: BundleI18n.SKResource.Bitable_PeopleField_ThisActionWillDeleteFields_Title)
                    alert.setContent(text: content)
                    alert.addCancelButton()
                    alert.addDestructiveButton(text: BundleI18n.SKResource.Bitable_Common_ButtonDelete, dismissCompletion: {
                        DocsLogger.info("checkConfirm type is SetFieldAttr and call handleChangeCommit")
                        self.handleChangeCommit(shouldCheckConfirm: false, checkConfirmValue: nil)
                    })
                    self.present(alert, animated: true)
                case .ConfirmConvertPeopleForStage:
                    let alert = UDDialog()
                    let names = checkConfirmResult.extra?["fieldName"] as? String ?? " "
                    let title = BundleI18n.SKResource.Bitable_Flow_EdgeCase_EditFieldType_PopUpTitle
                    let content = BundleI18n.SKResource.Bitable_Flow_EdgeCase_EditFieldType_PopUpDesc(names)
                    alert.setTitle(text: title)
                    alert.setContent(text: content)
                    alert.addCancelButton()
                    alert.addDestructiveButton(text: BundleI18n.SKResource.Bitable_Flow_EdgeCase_ConfirmDelete_PopUpButton, dismissCompletion: {
                        DocsLogger.info("checkConfirm type is SetFieldAttr and call handleChangeCommit")
                        self.handleChangeCommit(shouldCheckConfirm: false, checkConfirmValue: nil)
                    })
                    self.present(alert, animated: true)
                case .ConfirmAIGenerate:
                    DocsLogger.info("ConfirmAIGenerate type is ConfirmAIGenerate and call handleChangeCommit")
                    self.handleChangeCommit(shouldCheckConfirm: false, checkConfirmValue: nil)
                }
            case .failure(let error):
                self.handleChangeCommit(shouldCheckConfirm: false, checkConfirmValue: nil)
                spaceAssertionFailure("checkConfirm error, downgrade to handleChangeCommit")
                DocsLogger.error("checkConfirm error", error: error)
            }
        }
    }
    
    @discardableResult
    func setSaveButtonEnable(enable: Bool = true) -> Bool {
        let verifyOK = viewModel.verifyData() && enable
        saveButton.isEnabled = verifyOK
        let isDynamicOption = viewModel.fieldEditModel.compositeType.classifyType == .option && viewModel.fieldEditModel.fieldProperty.optionsType == .dynamicOption
        let isLinkType = viewModel.fieldEditModel.compositeType.classifyType == .link
        if isDynamicOption || isLinkType {
            // 级联和关联字段点击保存需要弹toast
            let (success, _) = viewModel.verifyFieldName()
            saveButton.isEnabled = success && enable
        }
        saveButton.setTitleColor(verifyOK ? UDColor.primaryContentDefault : UDColor.textDisabled, for: .normal)

        return verifyOK
    }

    func setTitleErrorMessage(message: String) {
        titleErrorMessageLabel.text = message
        lastFieldNameHasError = true
        titleErrorMessageLabel.snp.updateConstraints { make in
            make.height.equalTo(20)
        }

        fieldTypeLabel.snp.updateConstraints { make in
            make.top.equalTo(titleInputTextViewWrapper.snp.bottom).offset(38)
        }
    }
    
    func commitChange(checkConfirmValue: [String: Any]?, completion: ((BTExecuteFailReson?) -> Void)? = nil) {
        var property: [String: Any] = [:]
        property = viewModel.createNormalCommitChangeProperty()

        let modifyCommitBlock = { [weak self] in
            guard let self = self else { return }
            var fieldInfo = self.viewModel.getJSFieldInfoArgs(editMode: self.currentMode, fieldEditModel: self.viewModel.fieldEditModel)
            fieldInfo.id = self.currentMode == .add ? self.viewModel.fieldEditModel.fieldId : nil
            let args = BTExecuteCommandArgs(command: self.currentMode == .edit ? .setFieldAttr : .addField,
                                            tableID: self.viewModel.fieldEditModel.tableId,
                                            viewID: self.viewModel.fieldEditModel.viewId,
                                            fieldInfo: fieldInfo,
                                            property: property,
                                            checkConfirmValue: checkConfirmValue,
                                            extraParams: nil)
            self.dataService?.executeCommands(args: args) { failReason, _ in
                completion?(failReason)
            }
            if fieldInfo.extendConfig?.isEmpty == false,
               let start = self.extendManager.extendConfigs?.configs.first,
               let end = self.footerView.extFooter.configs.first {
                self.extendManager.trackExtendSave(model: self.viewModel.fieldEditModel, start: start, end: end)
            }
        }

        //双向关联当关联的tableId发生变化时重新获取backFieldId和backFieldName
        //当之前从单向关联转换到双向关联字段时，即使关联表没发生变化也要重新获取backFieldId和backFieldName
        if viewModel.fieldEditModel.compositeType.uiType == .duplexLink &&
            (viewModel.oldFieldEditModel.compositeType.uiType == .singleLink ||
             viewModel.oldFieldEditModel.fieldProperty.tableId != viewModel.fieldEditModel.fieldProperty.tableId) {
            if let currentTableName = viewModel.fieldEditModel.tableNameMap.first(where: { $0.tableId == viewModel.fieldEditModel.tableId })?.tableName {
                property["backFieldName"] = currentTableName + "-" + viewModel.fieldEditModel.fieldName
            }
            //关联字段，且当关联表发生变化时重新生成fieldId
            viewModel.getNewFieldID(tableID: viewModel.fieldEditModel.fieldProperty.tableId) { fieldId in
                guard let fieldId = fieldId else { return }
                property["backFieldId"] = fieldId
                
                modifyCommitBlock()
            }
        } else {
            modifyCommitBlock()
        }
    }
    
    func checkConfirm(completion: @escaping (Result<CheckConfirmResult, Error>) -> Void) {
        //和setfieldattr保持一致结构(除了cmd)
        var property = getProperty()
        /*本地mock测试可以放开进行
         completion(.success(CheckConfirmResult(type: .ConfirmKeepNoExistData, extra: nil)))
         return
         */
        guard let dataService = dataService else {
            DocsLogger.error("checkConfirm error, dataService is nil")
            return
        }
        let fieldInfo = self.viewModel.getJSFieldInfoArgs(editMode: self.currentMode, fieldEditModel: self.viewModel.fieldEditModel)
        let args = BTCheckConfirmAPIArgs(tableID: self.viewModel.fieldEditModel.tableId,
                                         viewID: self.viewModel.fieldEditModel.viewId,
                                         fieldInfo: fieldInfo,
                                         property: property,
                                         extraParams: nil,
                                         generateAIContent: self.generateAIContent
                    )
        dataService.checkConfirmAPI(args: args) { result in
            completion(result)
        }
    }

    func showConfirmActionPanel() {
        guard viewModel.oldFieldEditModel != viewModel.fieldEditModel else {
            self.dismiss(animated: true)
            return
        }

        let tips = BundleI18n.SKResource.Bitable_Field_ChangesUnsavedDesc
        let textLabel = UILabel()
        textLabel.font = UDFont.title4
        textLabel.text = tips
        textLabel.numberOfLines = 1

        //24为文字两边的边距
        let preferredContentWidth = textLabel.intrinsicContentSize.width + 24

        let source = UDActionSheetSource(sourceView: cancelButton,
                                         sourceRect: cancelButton.bounds,
                                         preferredContentWidth: preferredContentWidth)
        

        let config = UDActionSheetUIConfig(isShowTitle: true, popSource: source)

        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(BundleI18n.SKResource.Bitable_Field_ChangesUnsavedDesc)
        actionSheet.addDestructiveItem(text: BundleI18n.SKResource.Bitable_Field_ChangesUnsavedButtonLeave) { [weak self] in
            guard let self = self else { return }
            self.delegate?.trackEditViewEvent(eventType: .bitableFieldModifyCancelConfirmClick,
                                              params: ["click": "exit",
                                                       "target": "none"],
                                              fieldEditModel: self.viewModel.fieldEditModel)
            self.dismiss(animated: true)
        }

        actionSheet.setCancelItem(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel) { [weak self] in
            guard let self = self else { return }
            self.delegate?.trackEditViewEvent(eventType: .bitableFieldModifyCancelConfirmClick,
                                              params: ["click": "cancel",
                                                       "target": "none"],
                                              fieldEditModel: self.viewModel.fieldEditModel)
        }

        Navigator.shared.present(actionSheet, from: self, completion: { [weak self] in
            guard let self = self else { return }
            self.delegate?.trackEditViewEvent(eventType: .bitableFieldModifyCancelConfirmView,
                                              params: [:],
                                              fieldEditModel: self.viewModel.fieldEditModel)
        })
    }

    ///自动编号字段，规则修改后点击保存确认弹框
    func autoNumberSaveConfirmActionPanel(clickItemCallback: @escaping () -> Void) {
        let tips = BundleI18n.SKResource.Bitable_Field_ApplyToExistedIdPopup
        let textLabel = UILabel()
        textLabel.font = UDFont.title4
        textLabel.text = tips
        textLabel.numberOfLines = 1

        //24为文字两边的边距
        let preferredContentWidth = textLabel.intrinsicContentSize.width + 24

        let source = UDActionSheetSource(sourceView: saveButton,
                                         sourceRect: saveButton.bounds,
                                         preferredContentWidth: preferredContentWidth)


        let config = UDActionSheetUIConfig(isShowTitle: true, popSource: source) { [weak self] in
            guard let self = self else { return }
            self.delegate?.trackEditViewEvent(eventType: .bitableAutoNumberCheckClick,
                                              params: ["click": "cancel"],
                                              fieldEditModel: self.viewModel.fieldEditModel)
        }

        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(tips)
        actionSheet.addItem(text: BundleI18n.SKResource.Bitable_Field_ApplyToExistedIdPopupButtonNo) { [weak self] in
            guard let self = self else { return }
            self.viewModel.fieldEditModel.fieldProperty.reformatExistingRecord = false
            self.delegate?.trackEditViewEvent(eventType: .bitableAutoNumberCheckClick,
                                              params: ["click": "not_change"],
                                              fieldEditModel: self.viewModel.fieldEditModel)
            clickItemCallback()
        }

        actionSheet.addItem(text: BundleI18n.SKResource.Bitable_Field_ApplyToExistedIdPopupButtonYes) { [weak self] in
            guard let self = self else { return }
            self.viewModel.fieldEditModel.fieldProperty.reformatExistingRecord = true
            self.delegate?.trackEditViewEvent(eventType: .bitableAutoNumberCheckClick,
                                              params: ["click": "change"],
                                              fieldEditModel: self.viewModel.fieldEditModel)
            clickItemCallback()
        }

        actionSheet.setCancelItem(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel) { [weak self] in
            guard let self = self else { return }
            self.delegate?.trackEditViewEvent(eventType: .bitableAutoNumberCheckClick,
                                              params: ["click": "cancel"],
                                              fieldEditModel: self.viewModel.fieldEditModel)
        }

        Navigator.shared.present(actionSheet, from: self, completion: { [weak self] in
            guard let self = self else { return }
            self.delegate?.trackEditViewEvent(eventType: .bitableAutoNumberCheckView,
                                              params: [:],
                                              fieldEditModel: self.viewModel.fieldEditModel)
        })
    }
    
    func adjustFooterContentHeight() {
        footerView.hideEditableContent(isPhoneLandscape)
        
        let w = currentTableView.bounds.width
        let h = UIView.layoutFittingCompressedSize.height
        let size = footerView.systemLayoutSizeFitting(CGSize(width: w, height: h))
        footerView.frame.size.height = size.height
        currentTableView.tableFooterView = footerView
        
        currentTableView.reloadData()
    }

    func updateUI(fieldEditModel: BTFieldEditModel) {
        viewModel.updateCurrentFieldEditConfig(viewController: self)
        updateLayout()  // 兼容旧的布局和commonDataModel
        
        updateNoticeBanner()

        setSaveButtonEnable()
        configInputEditable()
        
        specialSetView.subviews.forEach { $0.removeFromSuperview() }
        footerView.deactiveSpeFooter()
        
        let image = viewModel.fieldEditModel.compositeType.icon()
        if let fieldItem = viewModel.commonData.fieldConfigItem.fieldItems.first(where: { $0.compositeType == viewModel.fieldEditModel.compositeType }) {
            fieldTypeChooseButton.setLeftIcon(image: image, showLighting: viewModel.isCurrentExtendChildType)
            fieldTypeChooseButton.setTitleString(text: fieldItem.title)
            if UserScopeNoChangeFG.ZYS.loadRecordsOnDemand {
                fieldTypeChooseButton.setButtonEnable(enable: fieldEditModel.isTypeModificationEnable)
            } else if viewModel.isCurrentExtendChildType {
                // 待删除的代码
                fieldTypeChooseButton.setButtonEnable(enable: fieldEditModel.fieldExtendInfo?.editable == true)
            }
        }
        
        configExtendFooter()
        
        guard !viewModel.isCurrentExtendChildType,
              let viewManager = viewManager,
              let result = viewManager.getView(commonData: viewModel.commonData, fieldEditModel: viewModel.fieldEditModel) else {
            currentTableView.tableHeaderView?.frame.size.height = lastFieldNameHasError ? 200 : 176
            currentTableView.tableHeaderView = containerView
            adjustFooterContentHeight()
            currentTableView.reloadData()
            return
        }
        let view = result.view
        let viewHeight = result.viewHeight
    
        switch viewModel.fieldEditModel.compositeType.uiType {
        case .text:
            addSubViewToSpecailSetView(subview: view, subviewHeight: viewHeight)
        case let type where type.classifyType == .option:
            configOptionUI(view: view, viewManager: viewManager)
        case let type where type.classifyType == .date:
            addSubViewToSpecailSetView(subview: view, subviewHeight: viewHeight)
        case .number:
            addSubViewToSpecailSetView(subview: view, subviewHeight: viewHeight)
        case .currency:
            viewModel.initCurrencyProperty()
            addSubViewToSpecailSetView(subview: view, subviewHeight: 176)
        case .progress:
            configProgressUI(view: view, viewManager: viewManager)
        case .attachment:
            addSubViewToSpecailSetView(subview: view, subviewHeight: 88)
        case let type where type.classifyType == .link:
            configLinkFieldUI(view: view, viewManager: viewManager)
        case .user:
            addSubViewToSpecailSetView(subview: view, subviewHeight: 68)
        case .group:
            addSubViewToSpecailSetView(subview: view, subviewHeight: 68)
        case .autoNumber:
            configAutoNumberUI(view: view, viewManager: viewManager)
        case .location:
            addSubViewToSpecailSetView(subview: view, subviewHeight: 88)
        case .barcode:
            addSubViewToSpecailSetView(subview: view, subviewHeight: 68)
        default:
            break
        }
        self.viewModel.fieldEditModel = viewManager.updateData(commonData: viewModel.commonData,
                                                               fieldEditModel: self.viewModel.fieldEditModel)
        let errorLabelHeight: CGFloat = lastFieldNameHasError ? 24 : 0
        currentTableView.tableHeaderView?.frame.size.height += errorLabelHeight
        currentTableView.tableHeaderView = containerView
        adjustFooterContentHeight()
        currentTableView.reloadData()
    }
    
    private func updateNoticeBanner() {
        guard let notice = viewModel.fieldEditModel.editNotice else {
            extendNotice = nil
            noticeBanner.noticeText = nil
            noticeBanner.actionText = nil
            noticeBanner.isHidden = true
            return
        }
        guard notice != extendNotice else {
            return
        }
        extendNotice = notice
        
        noticeBanner.noticeText = notice.bodyText
        noticeBanner.actionText = notice.actionText
        
        // TODO: yinyuan 这里取 isOwner 只用于埋点，需要想办法取到 base 对应的信息
        let isOwner = viewModel.dataService?.hostDocInfo.isOwner ?? false
        extendManager.trackExtendNoticeView(model: viewModel.fieldEditModel, notice: notice, isOwner: isOwner)
    }
    
    private func configExtendFooter() {
        if let extendInfo = viewModel.fieldEditModel.fieldExtendInfo {
            // 当前字段是扩展子字段，展示扩展字段来源
            footerView.activeExtendFooter { footer in
                footer.update(
                    originModel: FooterExtendOriginModel(
                        refreshState: self.viewModel.fieldExtendRefreshState,
                        extendInfo: extendInfo
                    )
                )
            }
            return
        }
        if let configs = extendManager.extendConfigs?.configs {
            // 当前字段是扩展根字段，展示扩展字段配置
            let isMultiple = viewModel.fieldEditModel.fieldProperty.multiple
            footerView.activeExtendFooter { footer in
                footer.update(configs: configs)
                if isMultiple {
                    footer.insertDisableReason(.notSupportMultiple)
                } else {
                    footer.removeDisableReason(.notSupportMultiple)
                }
            }
            return
        }
        // 当前字段不是扩展子字段，也不支持扩展，不展示扩展字段 Footer
        footerView.deactiveExtFooter()
    }
    
    private func configOptionFooter() {
        if LKFeatureGating.bitableDynamicOptionsEnable, viewModel.fieldEditModel.fieldProperty.optionsType == .dynamicOption {
            var enable = dynamicOptionsConditions.count < 5 && viewModel.verifyTargetTable()

            let buttonText = dynamicOptionsConditions.count == 5 ?
            BundleI18n.SKResource.Bitable_SingleOption_AddUpToNumCondition_Mobile(5) :
            BundleI18n.SKResource.Bitable_SingleOption_AddCondition_Mobile
            
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                // 级联引用字段无权限以 及 新文档且部分无权限操作下，设置为灰色，点击弹toast
                if viewModel.isDynamicFieldDenied || viewModel.isDynamicPartNoPerimission {
                    enable = false
                }
            }
            
            
            let tableId = viewModel.dynamicOptionRuleTargetTable
            
            setSaveButtonEnable()
            if let linkTable = viewModel.commonData.tableNames.first(where: { $0.tableId == tableId }),
               !linkTable.readPerimission {
                //引用表无权限，不展示条件cell
                
                let tip = BundleI18n.SKResource.Bitable_SingleOption_UnableToViewConditionSetting_Mobile
                
                footerView.activeOptionFooter { footer in
                    footer.updateTipLabel(hidden: false, text: tip, topMargin: 0)
                }
            } else {
                footerView.activeOptionFooter { [weak self] footer in
                    guard let self = self else { return }
                    let margin: CGFloat = self.dynamicOptionsConditions.isEmpty ? 0 : 16
                    footer.updateAddButton(hidden: false, enable: enable, text: buttonText, topMargin: margin)
                    footer.addAction = { [weak self] sender in
                        self?.didClickAdd(sender: sender)
                    }
                }
            }
        } else {
            footerView.activeOptionFooter { [weak self] footer in
                guard let self = self else { return }
                let margin: CGFloat = self.viewModel.options.isEmpty ? 0 : 16
                let text = BundleI18n.SKResource.Bitable_Field_AddAnOption
                footer.updateAddButton(hidden: false, enable: true, text: text, topMargin: margin)
                footer.addAction = { [weak self] sender in
                    self?.didClickAdd(sender: sender)
                }
            }
        }
    }

    ///配置选项字段UI
    func configOptionUI(view: UIView, viewManager: BTFieldEditViewManager) {
        //添加选项
        configOptionFooter()


        specialSetView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    ///配置进度条字段UI
    func configProgressUI(view: UIView, viewManager: BTFieldEditViewManager) {
        addSubViewToSpecailSetView(subview: view, subviewHeight: view.frame.height)
    }
    
    /// 设置 SpecailSetView 的子视图
    func addSubViewToSpecailSetView(subview: UIView, subviewHeight: CGFloat) {
        currentTableView.tableHeaderView?.frame.size.height = 178 + subviewHeight
        specialSetView.addSubview(subview)
        subview.snp.remakeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(subviewHeight)
        }
    }
    
    /// 配置地理位置字段UI
    private func configGeoLocationUI(view: UIView) {
        currentTableView.tableHeaderView?.frame.size.height = 274
        specialSetView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(90)
        }
    }

    func safePresent(safe: @escaping (() -> Void)) {
        if let presentedVC = self.presentedViewController {
            presentedVC.dismiss(animated: true, completion: safe)
        } else {
            safe()
        }
    }

    public func didClickDeletedButton(index: IndexPath) {
        hasFieldSubSettingClick = true
        resignInputFirstResponder()
        var tableIndex = 0
        let isDeleteAutoNumCell = viewModel.fieldEditModel.compositeType.uiType == .autoNumber
        let isDeleteOptionCell = viewModel.fieldEditModel.compositeType.classifyType == .option
        if isDeleteAutoNumCell {
            let row = index.row
            guard row < auotNumberRuleList.count else { return }
            
            auotNumberRuleList.remove(at: row)
            tableIndex = row
        } else if isDeleteOptionCell {
            let row = index.row
            guard row < viewModel.options.count else { return }

            delegate?.trackEditViewEvent(eventType: .bitableOptionFieldModifyViewClick,
                                         params: ["click": "delete",
                                                  "target": "none"],
                                         fieldEditModel: viewModel.fieldEditModel)
            viewModel.options.remove(at: row)
            tableIndex = row
        }
        editingFieldCellHasErrorIndexs.removeAll(where: { $0 == tableIndex })
        currentTableView.performBatchUpdates {
            currentTableView.deleteRows(at: [IndexPath(item: tableIndex, section: 0)], with: .automatic)
        } completion: { [weak self] completed in
            if completed {
                if isDeleteAutoNumCell {
                    self?.configAutoNumFooter()
                } else if isDeleteOptionCell {
                    self?.configOptionFooter()
                }
                self?.adjustFooterContentHeight()
                self?.currentTableView.reloadData()
            }
        }
    }
    
    private func trackOnSaveButtonClick() {
        viewModel.fieldEditConfig.trackOnSaveButtonClick()
        let fieldType = viewModel.fieldEditModel.compositeType.uiType
        var params: [String: Any] = [:]
        switch fieldType {
        case .location:
            params = [
                "click": "location_input",
                "target": "none",
                "input": viewModel.fieldEditModel.fieldProperty.inputType.trackText
            ]
            
            delegate?.trackEditViewEvent(eventType: .bitableGeoFieldModifyClick,
                                         params: params,
                                         fieldEditModel: self.viewModel.fieldEditModel)
        case .autoNumber:
            let numberTime = auotNumberRuleList.filter({ $0.type == .createdTime }).count
            let numberFix = auotNumberRuleList.filter({ $0.type == .fixedText }).count

            delegate?.trackEditViewEvent(eventType: .bitableAutoNumberFieldViewClick,
                                         params: ["number_type": viewModel.fieldEditModel.fieldProperty.isAdvancedRules ? "customized" : "increased",
                                                  "num_time": numberTime,
                                                  "num_fix": numberFix],
                                         fieldEditModel: viewModel.fieldEditModel)
        case .currency:
            var fromCurrency = viewModel.oldFieldEditModel.fieldProperty.currencyCode
            let toCurrency = viewModel.fieldEditModel.fieldProperty.currencyCode
            var formatter = viewModel.fieldEditModel.fieldProperty.formatter
            
            let commonCurrencyCodeList = viewModel.commonData.fieldConfigItem.commonCurrencyCodeList
            
            guard let currency = commonCurrencyCodeList.first(where: { $0.currencyCode == toCurrency }) else {
                return
            }
            
            let newFormatter = formatter.replacingOccurrences(of: currency.formatCode, with: "")
            if let numberFormatter = viewModel.commonData.fieldConfigItem.commonCurrencyDecimalList.first(where: { $0.formatCode == newFormatter }) {
                formatter = numberFormatter.formatterName
            }
            
            let fieldItem = viewModel.commonData.fieldConfigItem.fieldItems.first(where: { $0.compositeType == viewModel.fieldEditModel.compositeType })
            let defaultCurrencyCodeIndex = fieldItem?.property.defaultCurrencyCodeIndex ?? 0
            if fromCurrency.isEmpty,
               defaultCurrencyCodeIndex < commonCurrencyCodeList.count {
                fromCurrency = commonCurrencyCodeList[defaultCurrencyCodeIndex].currencyCode
            }

            delegate?.trackEditViewEvent(eventType: .bitableCurrencyFieldModifyClick,
                                         params: ["from_currency": fromCurrency,
                                                  "to_currency": toCurrency,
                                                  "decimal_digits_type": formatter],
                                         fieldEditModel: viewModel.fieldEditModel)
        case .progress:
            var params: [String: Any] = [
                "click": "confirm",
                "target": "none"
            ]
            if let formatConfig = viewModel.commonData.fieldConfigItem.getCurrentFormatConfig(fieldEditModel: viewModel.fieldEditModel) {
                params["number_format_type"] = formatConfig.typeConfig.type?.tracingString()
                params["decimal_digits_type"] = BTFormatTypeConfig.getDecimalDigitsTracingString(formatConfig.decimalDigits)
            }
            let rangeConfig = viewModel.commonData.fieldConfigItem.getCurrentRangeConfig(fieldEditModel: viewModel.fieldEditModel)
            params["is_customized_progress"] = rangeConfig.rangeCustomize ? "switch_on" : "switch_off"
            if let colorConfig = viewModel.commonData.fieldConfigItem.getCurrentColorConfig(fieldEditModel: viewModel.fieldEditModel) {
                params["color_id"] = colorConfig.selectedColor.id
            }
            
            delegate?.trackEditViewEvent(eventType: .bitableProgressFieldModifyClick,
                                         params: params,
                                         fieldEditModel: self.viewModel.fieldEditModel)
        default:
            break
        }
    }
}

extension BTFieldEditController: ClipboardProtectProtocol {
    public func getDocumentToken() -> String? {
        return self.baseContext.permissionObj.objToken
    }
}
