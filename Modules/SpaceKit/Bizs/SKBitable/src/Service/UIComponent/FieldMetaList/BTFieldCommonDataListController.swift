//
//  BTFieldCommonDataListController.swift
//  SKBitable
//
//  Created by zoujie on 2021/12/10.
//  

import SKFoundation
import SKUIKit
import HandyJSON
import SKResource
import UniverseDesignEmpty
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast
import UIKit
import UniverseDesignFont

struct BTFieldCommonData: GroupableItem {
    enum RightIconType {
        case none
        case arraw
    }
    
    enum SelectedType {
        case none
        case textHighlight
        case selectedIcon
        case all
    }
    
    var id: String
    var subID: String = ""
    var name: String
    var groupId: String
    var enable: Bool
    var icon: UIImage?
    var rightSubtitle: String?
    var rightIocnType: RightIconType = .none
    var selectedType: SelectedType = .selectedIcon
    var flag: Bool = false
    var isShow: Bool?
    var callbackId: String?
    
    // icon 是否显示闪电下标
    var showLighting = false
    
    // 是否需要展示新的引导按钮按钮
    var isShowNew: Bool = false
    
    var reference: Any?
    
    init(id: String,
         subID: String = "",
         name: String,
         groupId: String = "",
         enable: Bool = true,
         icon: UIImage? = nil,
         showLighting: Bool = false,
         rightSubtitle: String? = nil,
         rightIocnType: RightIconType = .none,
         selectedType: SelectedType = .selectedIcon,
         isShow: Bool? = nil,
         callbackId: String? = nil,
         reference: Any? = nil
    ) {
        self.id = id
        self.subID = subID
        self.name = name
        self.groupId = groupId
        self.enable = enable
        self.icon = icon
        self.showLighting = showLighting
        self.rightSubtitle = rightSubtitle
        self.rightIocnType = rightIocnType
        self.selectedType = selectedType
        self.callbackId = callbackId
        self.reference = reference
        self.isShow = isShow
    }
}

protocol BTFieldCommonDataListDelegate: AnyObject {
    func didSelectedItem(_ item: BTFieldCommonData,
                         relatedItemId: String,
                         relatedView: UIView?,
                         action: String,
                         viewController: UIViewController,
                         sourceView: UIView?)
    
    func didClickBackPage(relatedItemId: String, action: String)
    func didClickDone(relatedItemId: String, action: String)
    func didClickClose(relatedItemId: String, action: String)
    func didClickMask(relatedItemId: String, action: String)
    func commonDataListControllerDidCancel()
    func commonDataListControllerDidDone()
    func checkFieldTypeChange(targetUIType: String, fieldType: String, sourceView: UIView, completion: @escaping () -> Void)
}

extension BTFieldCommonDataListDelegate {
    func didClickBackPage(relatedItemId: String, action: String) {}
    func didClickDone(relatedItemId: String, action: String) {}
    func didClickClose(relatedItemId: String, action: String) {}
    func didClickMask(relatedItemId: String, action: String) {}
    func didClose(relatedItemId: String, action: String) {}
    func commonDataListControllerDidCancel() {}
    func commonDataListControllerDidDone() {}
    func checkFieldTypeChange(targetUIType: String, fieldType: String, sourceView: UIView, completion: @escaping () -> Void) {}
}


final class BTFieldCommonDataListController: BTDraggableViewController,
                                       UITableViewDelegate,
                                       UITableViewDataSource {
    
    private var reuseID = "com.bytedance.ee.docs.bitable.fieldCommonData"
    
    private(set) var data: [BTFieldCommonData]
    
    private var groupData: [[BTFieldCommonData]] = []
    
    //打开该面板点击的item id
    private var relatedItemId: String
    
    //打开该面板点击的view
    private var relatedView: UIView?
    
    private var lastSelectedIndexPath: IndexPath?
    
    private var firstOpenView: Bool = true
    
    private let shouldShowGroupTitleById: Bool
    
    //不可点击的item点击后的效果
    private var disableItemClickBlock: ((UIViewController, BTFieldCommonData) -> Void)?
    
    private var lastSelectedItem: BTFieldCommonData? {
        guard let lastSelectedIndexPath = lastSelectedIndexPath,
              lastSelectedIndexPath.row < data.count else { return nil }
        return data[lastSelectedIndexPath.row]
    }
    
    private(set) var action: String
    private var initViewHeightBlock: (() -> CGFloat)? //外部提供初始高度计算block
    
    weak var delegate: BTFieldCommonDataListDelegate?
    
    private var emptyConfig: UDEmptyConfig = UDEmptyConfig(title: .init(titleText: "",
                                                                        font: .systemFont(ofSize: 14, weight: .regular)),
                                                           description: .init(descriptionText: BundleI18n.SKResource.Bitable_Mobile_CannotEditOption),
                                                           imageSize: 100,
                                                           type: .noContent,
                                                           labelHandler: nil,
                                                           primaryButtonConfig: nil,
                                                           secondaryButtonConfig: nil)
    
    private lazy var emptyView: UDEmptyView = {
        let blankView = UDEmptyView(config: emptyConfig)
        // 不用userCenterConstraints会非常不雅观
        blankView.useCenterConstraints = true
        blankView.backgroundColor = UDColor.bgFloatBase
        return blankView
    }()
    
    private lazy var emptyViewContainer: UIView = UIView().construct { it in
        it.addSubview(emptyView)
        it.backgroundColor = UDColor.bgFloatBase
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private lazy var typeTableView = UITableView(frame: .zero, style: .grouped).construct { it in
        it.backgroundColor = .clear
        it.register(BTFieldCommonDataCell.self, forCellReuseIdentifier: reuseID)
        it.isScrollEnabled = true
        it.dataSource = self
        it.delegate = self
        it.layer.masksToBounds = true
        it.clipsToBounds = true
        it.separatorStyle = .none
        it.keyboardDismissMode = .onDrag
        it.contentInset = UIEdgeInsets(top: 16,
                                       left: 0,
                                       bottom: 8,
                                       right: 0)
    }
    //是否展示底部footer，目前commondatalist业务耦合度高，伴有手动计算高度逻辑，不建议通过修改cell data增加元素，通过footer进行自定义
    var showHiddenTableFooter: Bool
   convenience init(newData: [BTConditionEditModel],
         title: String,
         action: String,
         shouldShowDragBar: Bool = false,
         shouldShowDoneButton: Bool = false,
         shouldShowGroupTitleById: Bool = true,
         relatedItemId: String = "",
         relatedView: UIView? = nil,
         disableItemClickBlock: ((UIViewController, BTFieldCommonData) -> Void)? = nil,
         lastSelectedIndexPath: IndexPath? = nil,
         emptyViewType: UDEmptyType = .noContent,
         emptyViewText: String = "",
         initViewHeightBlock: (() -> CGFloat)? = nil,
         showHiddenTableFooter: Bool = false) {
       let index = newData.firstIndex(where: { $0.checked ?? false}) ?? 0
       let indexPath = IndexPath(row: index, section: 0)
       self.init(data: newData.map({ $0.fieldCommonData }),
                 title: title,
                 action: action,
                 shouldShowDragBar: shouldShowDragBar,
                 shouldShowDoneButton: shouldShowDoneButton,
                 shouldShowGroupTitleById: shouldShowGroupTitleById,
                 relatedItemId: relatedItemId,
                 relatedView: relatedView,
                 disableItemClickBlock: disableItemClickBlock,
                 lastSelectedIndexPath: indexPath,
                 emptyViewType: emptyViewType,
                 emptyViewText: emptyViewText,
                 initViewHeightBlock: initViewHeightBlock,
                 showHiddenTableFooter: showHiddenTableFooter)
    }
    
    init(data: [BTFieldCommonData],
         title: String,
         action: String,
         shouldShowDragBar: Bool = false,
         shouldShowDoneButton: Bool = false,
         shouldShowGroupTitleById: Bool = true,
         relatedItemId: String = "",
         relatedView: UIView? = nil,
         disableItemClickBlock: ((UIViewController, BTFieldCommonData) -> Void)? = nil,
         lastSelectedIndexPath: IndexPath? = nil,
         emptyViewType: UDEmptyType = .noContent,
         emptyViewText: String = "",
         initViewHeightBlock: (() -> CGFloat)? = nil,
         showHiddenTableFooter: Bool = false) {
        self.showHiddenTableFooter = showHiddenTableFooter
        self.data = data
        self.action = action
        self.relatedView = relatedView
        self.relatedItemId = relatedItemId
        self.initViewHeightBlock = initViewHeightBlock
        self.disableItemClickBlock = disableItemClickBlock
        self.lastSelectedIndexPath = lastSelectedIndexPath
        self.shouldShowGroupTitleById = shouldShowGroupTitleById
        super.init(title: title,
                   shouldShowDragBar: shouldShowDragBar,
                   shouldShowDoneButton: shouldShowDoneButton)
        
        guard let groupItems = self.data.aggregateByGroupID() as? [[BTFieldCommonData]] else { return }
        self.groupData = groupItems
        
        //配置数据表空的显示
        self.emptyConfig.description = .init(descriptionText: emptyViewText)
        self.emptyConfig.type = emptyViewType
        self.emptyView.update(config: self.emptyConfig)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 获取当前选择的 item 上适合的 popover 的控价
    func getSourceViewForPopoverFromSelectedItem() -> UIView? {
        guard let indexPath = lastSelectedIndexPath else {
            return nil
        }
        return (typeTableView.cellForRow(at: indexPath) as? BTFieldCommonDataCell)?.getRightIconIfShow()
    }
    
    /// 刷新列表
    func updateDates(_ datas: [BTFieldCommonData]) {
        self.data = datas
        guard let groupItems = self.data.aggregateByGroupID() as? [[BTFieldCommonData]] else { return }
        self.groupData = groupItems
        typeTableView.reloadData()
    }
    
    override func setupUI() {
        if let initViewHeightBlock = initViewHeightBlock {
            initViewHeight = initViewHeightBlock()
        } else {
            initViewHeight = min(max(CGFloat(data.count * 52 + 38 + 16 + 48), minViewHeight), maxViewHeight)
        }
        
        super.setupUI()
        contentView.addSubview(typeTableView)
        containerView.addSubview(emptyViewContainer)
        
        typeTableView.snp.makeConstraints { make in
            make.edges.equalTo(contentView.safeAreaLayoutGuide)
        }
        
        emptyViewContainer.snp.makeConstraints { make in
            make.edges.equalTo(contentView.safeAreaLayoutGuide)
        }
        
        emptyViewContainer.isHidden = !groupData.isEmpty
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        guard self.navigationController?.modalPresentationStyle == .overFullScreen,
              !self.hasBackPage else { return }
        
        let contenViewHeight = min(initViewHeight + view.safeAreaInsets.bottom, maxViewHeight)
        
        containerView.snp.updateConstraints { make in
            make.height.equalTo(contenViewHeight)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if firstOpenView, !groupData.isEmpty {
            let lastSelectedIndexPath = lastSelectedIndexPath ?? IndexPath(row: 0, section: 0)
            typeTableView.layoutIfNeeded() //不加会导致tableView滚动距离不符合预期
            typeTableView.scrollToRow(at: lastSelectedIndexPath, at: .top, animated: false)
        }
        
        firstOpenView = false
    }
    
    override func didClickBackPage() {
        super.didClickBackPage()
        delegate?.didClickBackPage(relatedItemId: relatedItemId, action: action)
        delegate?.commonDataListControllerDidCancel()
    }
    
    @objc
    override func didClickClose() {
        super.didClickClose()
        delegate?.didClickClose(relatedItemId: relatedItemId, action: action)
        delegate?.commonDataListControllerDidCancel()
    }
    
    @objc
    override func didClickDoneButton() {
        delegate?.didClickDone(relatedItemId: relatedItemId, action: action)
        delegate?.commonDataListControllerDidDone()
        super.didClickDoneButton()
    }
    
    /// 点击 mask 的处理，默认 dismiss 掉自己
    @objc
    override func didClickMask() {
        super.didClickMask()
        delegate?.didClickMask(relatedItemId: relatedItemId, action: action)
        delegate?.commonDataListControllerDidCancel()
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return groupData.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < groupData.count else { return 0 }
        return groupData[section].count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        guard let commonDataCell = cell as? BTFieldCommonDataCell,
              indexPath.section < groupData.count,
              indexPath.row < groupData[indexPath.section].count else { return cell }
        let item = groupData[indexPath.section][indexPath.row]
        var isLast = indexPath.row == groupData[indexPath.section].count - 1
        if showHiddenTableFooter {
            isLast = false
        }
        commonDataCell.config(model: item,
                              isSelected: indexPath == lastSelectedIndexPath,
                              isLast: isLast)
        
        if groupData[indexPath.section].count == 1 {
            commonDataCell.position = .solo
        } else if indexPath.row == 0 {
            commonDataCell.position = .first
        } else if indexPath.row == groupData[indexPath.section].count - 1 {
            commonDataCell.position = .last
            if showHiddenTableFooter {
                commonDataCell.position = .middle
            }
        } else {
            commonDataCell.position = .middle
        }
        
        return commonDataCell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < groupData.count,
              shouldShowGroupTitleById,
              let groupId = groupData[section].first?.groupId,
              !groupId.isEmpty else { return nil }
        
        let headerView = BTFieldCommonDataHeaderView()
        headerView.setText(text: groupId)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section < groupData.count,
              shouldShowGroupTitleById,
              let groupId = groupData[section].first?.groupId,
              !groupId.isEmpty else { return 0 }
        
        return 22
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if showHiddenTableFooter {
            if section == (groupData.count - 1) {
                let containerView = UIView()
                let foot = HiddenTableFooterView()
                containerView.addSubview(foot)
                foot.snp.makeConstraints { make in
                    make.top.bottom.equalToSuperview()
                    make.left.equalToSuperview().offset(16)
                    make.right.equalToSuperview().offset(-16)
                }
                return containerView
            }
            return nil
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if showHiddenTableFooter, section == (groupData.count - 1) {
            return 60
        }
        guard section < groupData.count,
              let groupId = groupData[section].first?.groupId,
              !groupId.isEmpty else { return 0 }
        
        return 14
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard indexPath.section < groupData.count,
              indexPath.row < groupData[indexPath.section].count else { return }
        
        guard let sourceView = tableView.cellForRow(at: indexPath) else { return }
        
        let item = groupData[indexPath.section][indexPath.row]
        
        guard item.enable else {
            if let disableItemClickBlock = disableItemClickBlock {
                disableItemClickBlock(self, item)
            }
            return
        }
        
        var needReloadRows = [indexPath]
        
        if let lastIndexPath = self.lastSelectedIndexPath {
            needReloadRows.append(lastIndexPath)
        }
        self.lastSelectedIndexPath = indexPath
        tableView.reloadRows(at: needReloadRows, with: .none)
        delegate?.didSelectedItem(item,
                                  relatedItemId: relatedItemId,
                                  relatedView: relatedView,
                                  action: action,
                                  viewController: self,
                                  sourceView: sourceView)
    }
}

final class BTFieldCommonDataHeaderView: UIView {
    private lazy var label = UILabel().construct { it in
        it.textColor = UDColor.textPlaceholder
        it.font = .systemFont(ofSize: 14)
    }
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-2)
            make.height.equalTo(20)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setText(text: String) {
        label.text = text
    }
}
// 底部无权限提示
final class HiddenTableFooterView: UIView {
    lazy var label: UILabel = {
        let view = UILabel()
        view.textColor = UDColor.textPlaceholder
        view.font = UDFont.body0
        view.text = BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermTableFiltered_Toast
        view.numberOfLines = 0
        return view
    }()
    init() {
        super.init(frame: .zero)
        backgroundColor = UDColor.bgFloat
        addSubview(label)
        layer.cornerRadius = 10.0
        layer.maskedCorners = .bottom
        layer.masksToBounds = true
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
