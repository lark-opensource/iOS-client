// 
// Created by duanxiaochen.7 on 2020/3/16.
// Affiliated with DocsSDK.
// 
// Description: 选项字段的编辑面板
//swiftlint:disable file_length

import SKFoundation
import UIKit
import SKUIKit
import RxSwift
import SKCommon
import SKBrowser
import SKResource
import EENavigator
import UniverseDesignEmpty
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignIcon
import UniverseDesignShadow
import UniverseDesignActionPanel
import UniverseDesignLoading

protocol BTOptionPanelDelegate: AnyObject {
    func optionSelectionChanged(to: [BTCapsuleModel], isSingleSelect: Bool, trackInfo: BTTrackInfo)
    func scrollTillFieldVisible()
    func trackOptionFieldEvent(event: String, params: [String: Any])
    func hideView()
    func executeCommands(command: BTCommands,
                         property: Any?,
                         extraParams: Any?,
                         resultHandler: @escaping (BTExecuteFailReson?, Error?) -> Void)
    func getBitableCommonData(type: BTEventType,
                              resultHandler: @escaping (Any?, Error?) -> Void)
    func getFieldPermission(entity: String,
                            operation: OperationType,
                            resultHandler: @escaping (Any?, Error?) -> Void)
    func getDynamicOptions()
}

// swiftlint:disable type_body_length
final class BTOptionPanel: UIView {
    weak var delegate: BTOptionPanelDelegate?
    weak var gestureManager: BTPanGestureManager!
    public weak var hostVC: UIViewController?
    var isSingle: Bool
    var optionModel: [BTCapsuleModel]

    var selectedModel: [BTCapsuleModel]

    private var colors: [BTColorModel] = []
    var optionFilterModel: [BTCapsuleModel] = []
    var currentEditModel: BTCapsuleModel?
    private var textPinyinMap: [String: String] = [:]
    
    var trackInfo = BTTrackInfo()

    //用来数据源刷新后滚动到指定的item
    var lastClickItem: BTCapsuleModel?
    private var minY: CGFloat {
        (self.hostVC?.view.bounds.height ?? self.maxViewHeight) - self.maxViewHeight
    }
    public var initViewHeight: CGFloat = 0
    public var currentViewHeight: CGFloat = 0
    //是否在拖动的过程中
    private var isPanning: Bool = false
    private var keyboard: Keyboard?
    //superView距离屏幕底部的距离，用来适配VC场景下的键盘高度
    private var superViewBottomOffset: CGFloat
    var keyboardIsShow = false
    var editPanel: BTOptionEditorPanel?
    var optionMenu: BTOptionMorePanel?
    var currentContentOffset: CGPoint = .zero
    var lastPositionY: CGFloat = 0
    var isFirstTimeScrollToTop = true
    var isStopEditing = false //是否结束编辑，正在下掉面板

    //当前有显示的弹框，退出BTOptionPanel需要隐藏
    var actionSheet: UDActionSheet?

    //加载页面
    private let loadingViewManager = BTLaodingViewManager()

    //是否是级联选项
    private var isDynamicOptions: Bool

    var canEdit = true

    let reuseID = NSStringFromClass(BTOptionPanelTableViewCell.self)
    let cellHeight: CGFloat = 48
    var maxViewHeight: CGFloat = 0
    var optionTableViewHeight: CGFloat { gestureManager.midHeight - 52 }
    var dragViewHeight: CGFloat = 74

    lazy var searchBar: SKSearchUITextField = SKSearchUITextField().construct { it in
        it.initialPlaceHolder = BundleI18n.SKResource.Bitable_Option_SearchOrCreate
        it.backgroundColor = .clear
        it.delegate = self
        it.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        it.returnKeyType = .search
    }

    private lazy var searchContentView = UIView().construct { it in
        it.backgroundColor = UDColor.bgFiller
        it.layer.cornerRadius = 8
        it.addSubview(searchBar)
    }

    private lazy var cancelButton: UIButton = UIButton().construct { it in
        it.backgroundColor = .clear
        it.isHidden = true
        it.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        it.setTitle(BundleI18n.SKResource.Bitable_Common_ButtonCancel, for: .normal)
        it.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        it.addTarget(self, action: #selector(didClickCancelButton), for: .touchUpInside)
    }

    lazy var addButton: UIButton = UIButton().construct { it in
        it.backgroundColor = .clear
        it.isHidden = !canEdit
        it.setImage(UDIcon.addOutlined.ud.withTintColor(UDColor.iconN1), for: [.normal, .highlighted])
        it.addTarget(self, action: #selector(didClickAddButton), for: .touchUpInside)
    }

    private lazy var addOptionButton = CustomBTOptionButton().construct { it in
        it.setTitle(text: BundleI18n.SKResource.Bitable_Option_Create)
        it.delegate = self
    }

    private lazy var searchBarLeftView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.searchOutlineOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3)
        return imageView
    }()

    lazy var searchView = UIView().construct { it in
        it.backgroundColor = .clear
        it.addSubview(searchContentView)
        it.addSubview(cancelButton)
        it.addSubview(addButton)

        searchContentView.snp.makeConstraints { make in
            make.left.bottom.equalToSuperview()
            make.height.equalTo(36)
            make.right.equalToSuperview().offset(canEdit ? -40 : 0)
        }

        searchBar.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }

        cancelButton.snp.makeConstraints { make in
            make.centerY.equalTo(searchContentView)
            make.right.equalToSuperview()
        }

        addButton.snp.makeConstraints { make in
            make.centerY.equalTo(searchContentView)
            make.right.equalToSuperview()
        }
    }

    private lazy var dragViewLine = UIView().construct { it in
        it.backgroundColor = UDColor.lineBorderCard
        it.layer.cornerRadius = 2
    }

    private lazy var dragViewSeparator = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }

    private lazy var dragView = UIView().construct { it in
        it.backgroundColor = UDColor.bgFloat
        it.layer.cornerRadius = 12
        it.layer.maskedCorners = .top
        it.layer.masksToBounds = true

        it.addSubview(dragViewLine)
        dragViewLine.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(4)
        }

        it.addSubview(searchView)
        searchView.snp.makeConstraints { make in
            make.height.equalTo(36)
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        it.addSubview(dragViewSeparator)
        dragViewSeparator.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1 / SKDisplay.scale)
        }

        dragViewSeparator.isHidden = optionModel.isEmpty && !canEdit
        searchView.isHidden = optionModel.isEmpty && !canEdit

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panToChangeSize(sender:)))
        it.addGestureRecognizer(panGestureRecognizer)
    }

    private lazy var placeholderViewContainer: UIView = UIView().construct { it in
        it.addSubview(placeholderView)
        placeholderView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.centerY.greaterThanOrEqualToSuperview()
        }
    }

    private var emptyConfig: UDEmptyConfig = UDEmptyConfig(title: .init(titleText: "",
                                                                        font: .systemFont(ofSize: 14, weight: .regular)),
                                                           description: .init(descriptionText: BundleI18n.SKResource.Bitable_Mobile_CannotEditOption),
                                                           imageSize: 100,
                                                           type: .noContent,
                                                           labelHandler: nil,
                                                           primaryButtonConfig: nil,
                                                           secondaryButtonConfig: nil)
    
    private lazy var placeholderView: UDEmptyView = {
        let blankView = UDEmptyView(config: emptyConfig)
        // 不用userCenterConstraints会非常不雅观
        blankView.useCenterConstraints = true
        blankView.backgroundColor = UDColor.bgFloat
        return blankView
    }()

    lazy var optionView = UITableView(frame: .zero, style: .plain).construct { it in
        it.backgroundColor = UDColor.bgFloat
        it.register(BTOptionPanelTableViewCell.self, forCellReuseIdentifier: reuseID)
        it.isScrollEnabled = true
        it.dataSource = self
        it.delegate = self
        it.layer.masksToBounds = true
        it.clipsToBounds = true
        it.separatorStyle = .none
        it.keyboardDismissMode = .onDrag
        it.panGestureRecognizer.addTarget(self, action: #selector(tableViewPan(sender:)))
    }

    init(delegate: BTOptionPanelDelegate!,
         gestureManager: BTPanGestureManager?,
         isSingle: Bool,
         isDynamicOptions: Bool,
         hostVC: UIViewController,
         colors: [BTColorModel],
         optionModel: [BTCapsuleModel],
         selectedModel: [BTCapsuleModel],
         superViewBottomOffset: CGFloat) {
        self.hostVC = hostVC
        self.colors = colors
        self.optionModel = optionModel
        self.selectedModel = selectedModel
        self.delegate = delegate
        self.gestureManager = gestureManager
        self.isSingle = isSingle
        self.isDynamicOptions = isDynamicOptions
        self.superViewBottomOffset = superViewBottomOffset
        self.trackInfo.didSearch = false
        self.trackInfo.didClickDone = false

        super.init(frame: .zero)

        backgroundColor = UDColor.bgFloat
        layer.ud.setShadow(type: .s4Up)
        layer.cornerRadius = 12
        layer.maskedCorners = .top

        addSubview(placeholderViewContainer)
        addSubview(optionView)
        addSubview(dragView)
        addSubview(addOptionButton)

        textPinyinMap.removeAll()

        if !isDynamicOptions {
            getFieldPermission()
            optionModel.forEach { model in
                textPinyinMap.updateValue(BTUtil.transformChineseToPinyin(string: model.text), forKey: model.id)
            }
            optionFilterModel = optionModel
        } else {
            //级联选项需要从接口获取
            self.optionModel = []
            self.canEdit = false
            permissionUpdate()
        }

        if optionModel.isEmpty {
            dragViewHeight = 20
        }

        dragView.snp.makeConstraints { it in
            it.top.equalToSuperview()
            it.height.equalTo(dragViewHeight)
            it.left.right.equalToSuperview()
        }

        placeholderViewContainer.snp.makeConstraints { it in
            it.top.equalTo(addOptionButton.snp.bottom)
            it.left.right.bottom.equalToSuperview()
        }

        optionView.snp.makeConstraints { it in
            it.top.equalTo(addOptionButton.snp.bottom)
            it.left.right.equalToSuperview()
            it.bottom.equalToSuperview().offset(-self.safeAreaInsets.bottom)
        }

        updateSearchView()

        addOptionButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(dragView.snp.bottom)
            make.bottom.equalTo(optionView.snp.top)
            make.height.equalTo(0)
        }

        addOptionButton.isHidden = true
        optionView.reloadData()
        optionView.isHidden = optionFilterModel.isEmpty
        placeholderViewContainer.isHidden = !optionFilterModel.isEmpty

        if isDynamicOptions {
            placeholderViewContainer.isHidden = true
        }

        initViewHeight = hostVC.view.bounds.height * 0.45
        currentViewHeight = initViewHeight
        maxViewHeight = hostVC.view.bounds.height * 0.8
        startKeyBoardObserver()
    }

    deinit {
        keyboard?.stop()
        actionSheet?.dismiss(animated: false)
        optionMenu?.dismiss(animated: false)
        editPanel?.dismiss(animated: false)
    }
    
    override func didMoveToSuperview() {
        guard self.superview != nil else { return }
        scrollToFirstSelection()
    }
    
    private func scrollToFirstSelection() {
        if let index = findFirstSelectionIndex() {
            let indexPath = IndexPath(row: index, section: 0)
            optionView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    private func findFirstSelectionIndex() -> Int? {
        for info in selectedModel where info.isSelected {
            for (index, showInfo) in optionModel.enumerated() where showInfo.id == info.id {    
                return index
            }
        }
        return nil
    }

    //更新搜索框的显示逻辑
    private func updateSearchView() {
        dragViewHeight = (optionModel.isEmpty && !canEdit) ? 20 : 68
        dragView.snp.updateConstraints { it in
            it.height.equalTo(dragViewHeight)
        }

        if optionModel.isEmpty {
            resetSearchBar()
        }

        dragViewSeparator.isHidden = optionModel.isEmpty && !canEdit
        searchView.isHidden = optionModel.isEmpty && !canEdit
    }

    //更新搜索框的显示样式：显示取消按钮 || 显示+号按钮 || 不显示任何按钮
    private func updateSearchContentView() {
        //取消按钮的隐藏逻辑：输入框没有内容 && 输入框有焦点
        let cancelButtonIsHidden = (self.searchBar.text?.isEmpty ?? true) && !keyboardIsShow
        //+号按钮的隐藏逻辑：取消按钮显示 || 没有编辑权限
        let addButtonIsHidden = !(cancelButtonIsHidden && self.canEdit)
        self.cancelButton.isHidden = cancelButtonIsHidden
        self.addButton.isHidden = addButtonIsHidden

        var searchContentViewRightOffest: CGFloat = 0
        if !cancelButtonIsHidden {
            //显示取消按钮
            searchContentViewRightOffest = -cancelButton.bounds.width - 16
        } else if !addButtonIsHidden {
            //显示+号按钮
            searchContentViewRightOffest = -40
        }

        searchContentView.snp.updateConstraints { make in
            make.right.equalToSuperview().offset(searchContentViewRightOffest)
        }
    }

    func updatePanel(fieldModel: BTFieldModel,
                     dynamicOptions: [BTOptionModel] = []) {
        textPinyinMap.removeAll()
        let colors = fieldModel.colors
        var selectedOptionIDs = fieldModel.optionIDs
        var allOptions = fieldModel.property.options

        let currentOptionsIsDynamic = fieldModel.property.optionsType == .dynamicOption
        if currentOptionsIsDynamic != isDynamicOptions {
            //选项类型发生了变化，权限需要更新
            isDynamicOptions = currentOptionsIsDynamic
            if isDynamicOptions {
                canEdit = false
                permissionUpdate()
            } else {
                getFieldPermission()
            }
        }

        if isDynamicOptions {
            allOptions = dynamicOptions
            selectedOptionIDs = fieldModel.dynamicOptions.compactMap({ $0.id })
        }

        optionModel = BTUtil.getAllOptions(with: selectedOptionIDs, colors: colors, allOptionInfos: allOptions)
        selectedModel = BTUtil.getSelectedOptions(withIDs: selectedOptionIDs, colors: colors, allOptionInfos: allOptions)

        optionModel.forEach { model in
            textPinyinMap.updateValue(BTUtil.transformChineseToPinyin(string: model.text), forKey: model.id)
        }
        if searchBar.text?.isEmpty ?? true {
            optionFilterModel = optionModel
        } else {
            let string = searchBar.text ?? ""
            optionFilterModel = BTUtil.getSimilarityItems(matchString: string.lowercased(),
                                                          textPinyinMap: textPinyinMap,
                                                          models: optionModel)
        }

        if let editModel = currentEditModel,
           !optionModel.contains(editModel) {
            //正在编辑的选项被删除，需要下掉编辑面板
            editPanel?.dismiss(animated: true)
        }

        optionView.reloadData()
        updateSearchView()

        optionView.isHidden = optionFilterModel.isEmpty
        if optionFilterModel.isEmpty {
            placeholderViewContainer.isHidden = isDynamicOptions
        } else {
            placeholderViewContainer.isHidden = true
        }

        if let lastClickItem = lastClickItem,
           let index = self.optionFilterModel.firstIndex(where: { $0.id == lastClickItem.id }) {
            let indexPath = IndexPath(row: index, section: 0)
            self.optionView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
        lastClickItem = nil
    }

    private func permissionUpdate() {
        self.searchBar.attributedPlaceholder = nil
        self.searchBar.initialPlaceHolder = self.canEdit ? BundleI18n.SKResource.Bitable_Option_SearchOrCreate : BundleI18n.SKResource.Bitable_Option_Search

        guard !keyboardIsShow else { return }
        updateSearchContentView()
        if !canEdit {
            hideAddButton()
            optionMenu?.dismiss(animated: true)
        }
        optionView.reloadData()
    }

    private func getFieldPermission() {
        //获取当前字段是否有编辑权限
        delegate?.getFieldPermission(entity: "Field",
                                     operation: .editable) { [weak self] (result, error) in
            guard let self = self else { return }
            guard error == nil,
                  let result = result as? [String: Any],
                  let hasPermission = result["result"] as? [Bool] else {
                DocsLogger.error("bitable optionPanel getFieldPermission failed")
                return
            }
            self.canEdit = (hasPermission.first ?? true) && !self.isDynamicOptions
            self.permissionUpdate()
        }
    }

    @objc
    private func panToChangeSize(sender: UIPanGestureRecognizer) {
        guard let host = hostVC, !isStopEditing else { return }
        isFirstTimeScrollToTop = false
        let fingerY = sender.location(in: host.view).y
        let translation = sender.translation(in: host.view)
        let panUp = translation.y < 0
        guard fingerY >= minY else { return }
        switch sender.state {
        case .began, .changed:
            isPanning = true
            gestureManager?.panToChangeSize(ofPanel: self, sender: sender)
        case .ended, .cancelled, .failed:
            isPanning = false
            let maxY = host.view.bounds.height - initViewHeight

            if panUp {
                //更新高度
                gestureManager.resizePanel(panel: self, to: minY)
                self.superview?.layoutIfNeeded()
                delegate?.scrollTillFieldVisible()
            } else {
                if fingerY > maxY {
                    //下掉面板
                    delegate?.hideView()
                } else {
                    //更新高度
                    gestureManager.resizePanel(panel: self, to: maxY)
                    self.superview?.layoutIfNeeded()
                    delegate?.scrollTillFieldVisible()
                }
            }
        default: break
        }
        guard searchBar.superview != nil else { return }
        searchBar.resignFirstResponder()
    }

    @objc
    private func tableViewPan(sender: UIPanGestureRecognizer) {
        guard let host = hostVC, currentContentOffset.y == 0, !isStopEditing else { return }
        switch sender.state {
        case .ended, .failed, .cancelled:
            let viewHeight = self.bounds.height
            if viewHeight < initViewHeight {
                //下掉面板
                delegate?.hideView()
            } else if viewHeight > maxViewHeight {
                //更新高度
                gestureManager.resizePanel(panel: self, to: minY)
                self.superview?.layoutIfNeeded()
                delegate?.scrollTillFieldVisible()
            } else {
                let maxY = host.view.bounds.height - initViewHeight
                
                let distanceToMinHeight = viewHeight - initViewHeight
                let distanceToMaxHeight = maxViewHeight - viewHeight

                if distanceToMaxHeight > distanceToMinHeight {
                    //更新高度
                    gestureManager.resizePanel(panel: self, to: maxY)
                } else {
                    //更新高度
                    gestureManager.resizePanel(panel: self, to: minY)
                }
                self.superview?.layoutIfNeeded()
                delegate?.scrollTillFieldVisible()
            }
        default:
            break
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func startKeyBoardObserver() {
        keyboard = Keyboard(listenTo: [searchBar], trigger: "bitableoption")
        keyboard?.on(events: [.willShow, .didShow]) { [weak self] option in
            guard let self = self else { return }
            self.keyboardIsShow = true
            self.gestureManager?.resizePanel(panel: self, to: self.minY)
            self.currentViewHeight = self.maxViewHeight
            let realKeyboardHeight = option.endFrame.height - self.superViewBottomOffset
            let remainHeightExceptKeyboard = self.bounds.height - self.dragView.bounds.height - 52
            var remainHeight = remainHeightExceptKeyboard - realKeyboardHeight

            remainHeight = max(133, remainHeight)

            let bottomOffset = remainHeightExceptKeyboard - remainHeight

            UIView.performWithoutAnimation {
                self.updateSearchContentView()

                self.placeholderViewContainer.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(-bottomOffset)
                }

                if option.event == .didShow {
                    self.optionView.snp.updateConstraints { it in
                        it.bottom.equalToSuperview().offset(-realKeyboardHeight)
                    }
                }

                self.layoutIfNeeded()
            }
            self.delegate?.scrollTillFieldVisible()
        }

        keyboard?.on(events: [.willHide, .didHide]) { [weak self] _ in
            guard let self = self else { return }
            self.keyboardIsShow = false
            UIView.performWithoutAnimation {
                self.updateSearchContentView()

                self.placeholderViewContainer.snp.updateConstraints { make in
                    make.bottom.equalToSuperview()
                }

                self.optionView.snp.updateConstraints { it in
                    it.bottom.equalToSuperview().offset(-self.safeAreaInsets.bottom)
                }
                self.layoutIfNeeded()
            }
        }
        keyboard?.start()
    }

    func resetSearchBar() {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        updateSearchContentView()
        optionView.isHidden = optionModel.isEmpty
        placeholderViewContainer.isHidden = !optionModel.isEmpty
        optionFilterModel = optionModel
        optionView.reloadData()
    }

    public func stopEditing() {
        keyboard?.stop()
        isStopEditing = true
    }

    //隐藏创建选项按钮
    func hideAddButton() {
        addOptionButton.snp.updateConstraints { make in
            make.height.equalTo(0)
        }
        addOptionButton.isHidden = true
    }

    func getTrackParams(click: String? = nil, target: String? = nil, isSingle: Bool? = nil) -> [String: Any] {
        var params: [String: Any] = [:]

        if let click = click {
            params["click"] = click
        }

        if let target = target {
            params["target"] = target
        }

        if let isSingle = isSingle {
            params["field_type"] = isSingle ? "single_option" : "multi_option"
        }
        return params
    }

    @objc
    private func didClickCancelButton() {
        resetSearchBar()
        hideAddButton()
    }

    @objc
    private func didClickAddButton() {
        //埋点上报
        delegate?.trackOptionFieldEvent(event: DocsTracker.EventType.bitableOptionFieldPanelClick.rawValue,
                             params: getTrackParams(click: "add",
                                                    target: "ccm_bitable_option_field_edit_view",
                                                    isSingle: isSingle))
        generateNewModel { [weak self] model in
            guard let self = self, let model = model else { return }
            self.showEditPanel(model: model, editMode: .add)
        }
    }

    @objc
    private func textDidChange(_ textField: UITextField) {
        //搜索匹配，忽略大小写
        let string = textField.text ?? ""
        if string.isEmpty {
            hideAddButton()
            optionView.isHidden = optionModel.isEmpty
            placeholderViewContainer.isHidden = !optionModel.isEmpty
            optionFilterModel = optionModel
            optionView.reloadData()
            return
        }

        let matchModel = optionModel.filter { $0.text == string }
        optionFilterModel = BTUtil.getSimilarityItems(matchString: string.lowercased(),
                                                      textPinyinMap: textPinyinMap,
                                                      models: optionModel)

        if optionFilterModel.isEmpty {
            //显示placeholder
            emptyConfig.description = .init(descriptionText: BundleI18n.SKResource.Bitable_Option_NoOptionFound)
            emptyConfig.type = optionModel.isEmpty ? .noContent : .searchFailed
            placeholderView.update(config: emptyConfig)
            optionView.isHidden = true
            placeholderViewContainer.isHidden = false
        } else {
            optionView.isHidden = false
            placeholderViewContainer.isHidden = true
        }
        optionView.reloadData()

        guard canEdit else { return }

        if matchModel.isEmpty {
            //未检索到相关选项，显示新增view
            generateNewModel { [weak self] model in
                guard let self = self, var model = model, self.canEdit else {
                    return
                }
                model.text = string
                self.addOptionButton.updateModel(model: model)
                self.addOptionButton.setTitle(text: BundleI18n.SKResource.Bitable_Option_Create)
                self.addOptionButton.snp.updateConstraints { make in
                    make.height.equalTo(52)
                }
                self.addOptionButton.isHidden = false
            }

        } else {
            //检索到相关选项，隐藏新增view
            hideAddButton()
        }

    }

    private func generateNewModel(completion: @escaping (BTCapsuleModel?) -> Void) {
        guard let delegate = delegate else {
            DocsLogger.info("bitable optionPanel new option failed")
            completion(nil)
            return
        }

        delegate.getBitableCommonData(type: .getNewOptionId, resultHandler: { [weak self] (result, error) in
            guard let self = self, error == nil,
                  let optionIds = result as? [String],
                  let optionId = optionIds.first else {
                DocsLogger.info("bitable optionPanel getOptionId failed")
                completion(nil)
                return
            }
            //调用前端接口获取随机生成的颜色
            delegate.getBitableCommonData(type: .getRandomColor, resultHandler: { result, error in
                guard error == nil,
                      let result = result as? [String: Any],
                      let colorId = result["color"] as? Int else {
                          DocsLogger.info("bitable optionPanel getOptionColor failed")
                          completion(nil)
                          return
                      }
                guard let randColor = self.colors.first(where: { $0.id == colorId }) else {
                    DocsLogger.info("bitable optionPanel getOptionColor failed")
                    completion(nil)
                    return
                }
                let newModel = BTCapsuleModel(id: optionId, text: "", color: randColor, isSelected: false)
                completion(newModel)
            })
        })
    }

    func getModelsJSON(models: [BTCapsuleModel]) -> [String: Any] {
        var options: [[String: Any]] = []

        models.forEach { model in
            let option: [String: Any] = ["id": model.id,
                                          "name": model.text,
                                          "color": model.color.id]
            options.append(option)
        }

        return ["options": options]
    }

    func showEditPanel(model: BTCapsuleModel, editMode: BTOptionEditMode) {
        guard let host = hostVC else { return }
        editPanel = BTOptionEditorPanel(model: model,
                                        models: optionModel,
                                        colors: colors,
                                        editMode: editMode,
                                        hostVC: host,
                                        superViewBottomOffset: superViewBottomOffset,
                                        isSingle: isSingle,
                                        gestureManager: gestureManager,
                                        delegate: self)
        guard let panel = editPanel else { return }

        panel.modalPresentationStyle = .overFullScreen
        panel.updateLayoutWhenSizeClassChanged = false
        panel.transitioningDelegate = panel.panelTransitioningDelegate
        Navigator.shared.present(panel, from: host, animated: true)
    }

    func didSelectedModel(model: BTCapsuleModel) {
        var currentSelectedOptions = [BTCapsuleModel]()

        if isSingle {
            var model = model
            trackInfo.didClickDone = false
            trackInfo.itemChangeType = model.isSelected ? .delete : .add
            if !model.isSelected {
                model.isSelected = true
                currentSelectedOptions.append(model)
            }
        } else {
            currentSelectedOptions = selectedModel
            var operateModel = model
            trackInfo.itemChangeType = operateModel.isSelected ? .delete : .add
            operateModel.isSelected.toggle()
            if operateModel.isSelected {//select
                currentSelectedOptions.append(operateModel)
            } else {//unselect
                currentSelectedOptions.removeAll { (model) -> Bool in
                    return model.id == operateModel.id
                }
            }
        }

        if !(searchBar.text?.isEmpty ?? true) {
            lastClickItem = model
        }

        trackInfo.isEditPanelOpen = !isSingle
        delegate?.optionSelectionChanged(to: currentSelectedOptions, isSingleSelect: isSingle, trackInfo: trackInfo)
    }
    
    func startLoadingTimer() {
        self.perform(#selector(type(of: self).showLoading), with: nil, afterDelay: 0.2)
    }

    @objc
    func showLoading() {
        placeholderViewContainer.isHidden = true
        loadingViewManager.showLoading(superView: self)
    }

    func hideLoading() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showLoading), object: nil)
        loadingViewManager.hideLoading()
    }

    func showTryAgainEmptyView(text: String, type: UDEmptyType, tryAgainBlock: (() -> Void)? = nil) {
        emptyConfig.description = .init(descriptionText: text)
        emptyConfig.type = type
        emptyConfig.primaryButtonConfig = (BundleI18n.SKResource.Bitable_Common_ButtonRetry, { _ in
            tryAgainBlock?()
        })
        placeholderView.update(config: self.emptyConfig)
        optionView.isHidden = true
        placeholderViewContainer.isHidden = false
    }

    func showEmptyView(text: String, type: UDEmptyType) {
        //显示placeholder
        emptyConfig.description = .init(descriptionText: text)
        emptyConfig.type = type
        placeholderView.update(config: self.emptyConfig)
        optionView.isHidden = true
        placeholderViewContainer.isHidden = false
    }

    func hideEmptyView() {
        optionView.isHidden = false
        placeholderViewContainer.isHidden = true
    }
}

public protocol CustomBTOptionButtonDelegate: AnyObject {
    func didClick(model: BTCapsuleModel)
}

public final class CustomBTOptionButton: UIButton {
    private var model: BTCapsuleModel
    private var optionItemView: BTOptionItemView
    public weak var delegate: CustomBTOptionButtonDelegate?

    override public var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UDColor.fillPressed : UDColor.bgFloat
        }
    }

    private let bottomSeparator = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }

    private let textLabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 16, weight: .regular)
        it.textAlignment = .center
    }

    public init(model: BTCapsuleModel = BTCapsuleModel(id: "",
                                                       text: "",
                                                       color: BTColorModel(),
                                                       isSelected: false)) {
        self.model = model
        self.optionItemView = BTOptionItemView(model: model)
        super.init(frame: .zero)
        backgroundColor = UDColor.bgFloat
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(textLabel)
        addSubview(optionItemView)
        addSubview(bottomSeparator)

        bottomSeparator.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        textLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        optionItemView.snp.makeConstraints { make in
            make.left.equalTo(textLabel.snp.right)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.centerY.equalTo(textLabel)
            make.height.equalTo(24)
        }

        optionItemView.isUserInteractionEnabled = false
        textLabel.textColor = UDColor.textTitle
        addTarget(self, action: #selector(didClick), for: .touchUpInside)
    }

    func updateModel(model: BTCapsuleModel) {
        self.model = model
        self.optionItemView.update(model: model)
    }

    func setTitle(text: String) {
        textLabel.text = text
    }

    @objc
    func didClick() {
        delegate?.didClick(model: model)
    }
}
