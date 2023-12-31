//
//  DocsToolBarUIMakerV2.swift
//  SKCommon
//
//  Created by LiXiaolin on 2020/6/16.
//  swiftlint:disable file_length

import SKFoundation
import SKCommon
import SKUIKit
import SKResource
import EENavigator
import UniverseDesignColor
import UniverseDesignIcon
import UIKit
import RxDataSources
import QuartzCore
import LarkContainer

protocol DocsMainToolBarV2Delegate: AnyObject {
    func rotationHighlightColorSelectView()
}

/// Docs 一级工具栏的构建
// swiftlint:disable type_body_length
public final class DocsMainToolBarV2: SKMainToolBarPanel {
    static let keyboardMark = "KEYBOARD-001"
    static let nullMark = "NULL-001"
    private(set) var items: [ToolBarItemInfo] = [ToolBarItemInfo]()
    //特殊需求的处理delegate
    weak var toolDelegate: DocsMainToolBarDelegate?
    weak var docsMainToolBarV2Delegate: DocsMainToolBarV2Delegate?
    private var showingItemID: String = ""
    private var keyboardSelected = false
    private var mode: DocsMainTBMode = .common {
        didSet {
            if oldValue != mode {
                self.confirmItemPadding = CGFloat.greatestFiniteMagnitude
            }
        }
    }
    private var jsService: DocsJSService = DocsJSService.docToolBarJsName
    private var subPanelIdentifier: String = DocsMainToolBar.keyboardMark
    private var keyboardView: DocsToolBarItemView = DocsToolBarItemView(frame: CGRect(origin: .zero, size: CGSize(width: Const.itemWidth, height: Const.itemWidth)))
    private var keyboardContainerView = UIView()
    private lazy var feedbackGenerator = UISelectionFeedbackGenerator()
    //是否是iPad工具栏
    private var isIPadToolbar = false
    static var hasPresentHighlightPanle = false
    //父菜单的第一个子菜单的index
    private var insertFirstChildIndex: [Int: Int] = [:]
    private var deleteFirstChildIndex: [Int: Int] = [:]
    
    // item的间距只计算一次，即使item的数量发生变化
    private var confirmItemPadding = CGFloat.greatestFiniteMagnitude
    
    let userResolver: UserResolver
    
    private lazy var gradientShadow = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44)).construct { it in
        let layer = CAGradientLayer()
        layer.position = it.center
        layer.bounds = it.bounds
        it.layer.addSublayer(layer)
        layer.ud.setColors([
            UDColor.N00.withAlphaComponent(0.00),
            UDColor.N00.withAlphaComponent(0.70),
            UDColor.N00.withAlphaComponent(0.94)
        ])
        layer.locations = [0, 0.37, 1]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.needsDisplayOnBoundsChange = true
    }
    
    public enum Const {
        static var itemWidth: CGFloat = 44
        static let itemHeight: CGFloat = 44
        static let imageWidth: CGFloat = 24
        static let itemPadding: CGFloat = 8
        static let horPadding: CGFloat = 7
        static let staticHorPadding: CGFloat = 6
        static var separateWidth: CGFloat = 5
        static let highlightCellWidth: CGFloat = 72
        static let fontSizeCellWidth: CGFloat = 139
        static let separateVerPadding: CGFloat = 10
        static let mainToolbarHeight: CGFloat = 44
        static let attachedToolbarHeight: CGFloat = 48
        static let sheetInputViewHeight: CGFloat = 44
        static let iconCellId: String = "iconCellId"
        static let seperatorID: String = "seperatorCellID"
        static let highlightCellId: String = "highlightCellId"
        static let fontSizeCellId: String = "fontSizeCellId"
        static let cellIdentifierPrefix: String = "docs.comment.toolbar."
        static let floatPadding: CGFloat = 4 //二级工具栏与一级工具栏的间距
        static var contentInsetPadding: CGFloat = 7 //新建按钮到工具栏左边的距离
        static let itemMinMargin: CGFloat = 0      // 工具栏item最小间距
        static let itemMaxMargin: CGFloat = 8      // 工具栏item最大间距
    }

    private lazy var layout: SKDocsToolbarCollectionViewLayout = {
        let layout = SKDocsToolbarCollectionViewLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: Const.contentInsetPadding, bottom: 0, right: 0)
        return layout
    }()

    lazy var shadowLayer: CALayer = {
        let layer = CALayer()
        return layer
    }()

    private lazy var itemCollectionView: UICollectionView = {
        let frame = CGRect(origin: .zero, size: CGSize(width: userResolver.docs.editorManager?.currentEditor?.frame.width ?? 0, height: Const.mainToolbarHeight))
        let cv = UICollectionView(frame: frame, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UDColor.bgBody
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.register(DocsToolBarCell.self, forCellWithReuseIdentifier: Const.iconCellId)
        cv.register(SeperatorCell.self, forCellWithReuseIdentifier: Const.seperatorID)
        cv.register(DocsToolBarHighlightCell.self, forCellWithReuseIdentifier: Const.highlightCellId)
        cv.register(DocsToolBarAdjustCell.self, forCellWithReuseIdentifier: Const.fontSizeCellId)
        return cv
    }()

    init(_ layouts: [ToolBarItemInfo], service: DocsJSService, userResolver: UserResolver, isIPadToolbar: Bool ) {
        self.userResolver = userResolver
        super.init(frame: .zero)
        self.items = layouts
        self.jsService = service
        self.backgroundColor = .clear
        self.isIPadToolbar = isIPadToolbar
        updateMode()
        feedbackGenerator.prepare()
        keyboardContainerView.backgroundColor = UDColor.bgBody
        keyboardContainerView.layer.ud.setShadowColor(UDColor.shadowDefaultSm)
        keyboardContainerView.layer.shadowRadius = 4
        keyboardContainerView.layer.shadowOpacity = 1
        keyboardContainerView.layer.shadowOffset = CGSize(width: -2, height: 0)
        keyboardView.docs.removeAllPointer()

        layer.insertSublayer(shadowLayer, below: itemCollectionView.layer)
        shadowLayer.ud.setShadow(type: .s4Down)
        
        keyboardContainerView.docs.addStandardLift()
        keyboardContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickKeyboard)))
        setKeyboard(selected: true)

        gradientShadow.isUserInteractionEnabled = false
        addSubview(itemCollectionView)
        addSubview(gradientShadow)
        addSubview(keyboardContainerView)

        keyboardContainerView.addSubview(keyboardView)
        keyboardContainerView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(4)
            make.width.equalTo(Const.itemWidth)
            make.height.equalTo(Const.mainToolbarHeight + 4)
        }

        keyboardView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(Const.mainToolbarHeight)
        }

        itemCollectionView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalTo(keyboardContainerView.snp.left)
            make.bottom.equalToSuperview()
            make.height.equalTo(Const.mainToolbarHeight)
        }
        gradientShadow.snp.makeConstraints { (make) in
            make.right.equalTo(keyboardContainerView.snp.left)
            make.bottom.equalToSuperview()
            make.width.equalTo(Const.itemWidth)
            make.height.equalTo(Const.mainToolbarHeight)
        }

        reloadItems()
        resetPanelIdentifier(service)
        updateCanScrollTips()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientShadow.layer.sublayers?.forEach { layer in
            if layer is CAGradientLayer {
                layer.position = gradientShadow.bounds.center
                layer.bounds = gradientShadow.bounds
            }
        }

        shadowLayer.frame.origin = itemCollectionView.frame.origin
        shadowLayer.frame.size = CGSize(width: itemCollectionView.frame.width + keyboardView.frame.width, height: Const.mainToolbarHeight)
    }

//    func reset() {
//        resetPanelIdentifier(jsService)
//        reloadItems()
//    }

    private func resetPanelIdentifier(_ service: DocsJSService) {
        if service == DocsJSService.sheetToolBar {
            subPanelIdentifier = DocsMainToolBar.nullMark
            mode = .floating
        } else {
            subPanelIdentifier = DocsMainToolBar.keyboardMark
            mode = .common
        }
    }

    ///获取itemIdentifier在items数组中的index
    private func getIndex(of itemIdentifier: String, from items: [ToolBarItemInfo]) -> Int? {
        for (i, item) in items.enumerated() where item.identifier == itemIdentifier {
            return i
        }
        return nil
    }

    ///记录插入item父菜单的index
    private func setInsertIndexMap(newData: [ToolBarItemInfo], inserts: [Int]) {
        let lastSeparatorIndex = items.reversed().firstIndex { it in
            it.identifier == BarButtonIdentifier.separator.rawValue
        }

        for insert in inserts where insert < newData.count {
            let item = newData[insert]
            if let itemParent = newData[insert].parentIdentifier, let index = getIndex(of: itemParent, from: items) {
                //记录菜单i父菜单的index，因为父菜单会被删除，故选择父菜单前一个菜单的frame
                layout.insertParentIndexMap.updateValue(index - 1, forKey: insert)
                //记录菜单index的第一个child的index
                if insertFirstChildIndex[index] == nil {
                    insertFirstChildIndex.updateValue(insert, forKey: index)
                }
                //记录需要删除的菜单index的第一个child的frame
                if layout.firstDeleteChildX[index] == nil {
                    let x = getCellFrameX(byIndex: insert, items: newData)
                    layout.firstDeleteChildX.updateValue(x, forKey: index)
                }
            } else if item.identifier == BarButtonIdentifier.checkbox.rawValue ||
                        item.identifier == BarButtonIdentifier.reminder.rawValue {
                //工具栏尾部的checkbox和reminder插入动画以工具栏最后一条分割线的x坐标为起点
                let x = getCellFrameX(byIndex: lastSeparatorIndex?.base ?? 0, items: items)
                layout.firstInsertChildX.updateValue(x, forKey: insert)
            }
        }
    }

    ///记录删除item父菜单的index
    private func setDeleteIndexMap(newData: [ToolBarItemInfo], deletes: [Int]) {
        var checkboxIndex = 0
        let lastSeparatorIndex = newData.reversed().firstIndex { it in
            it.identifier == BarButtonIdentifier.separator.rawValue
        }

        for delete in deletes where delete < items.count {
            let item = items[delete]
            if let itemParent = items[delete].parentIdentifier {
                if let index = getIndex(of: itemParent, from: newData) {
                    //记录菜单i父菜单的frame
                    let x = getCellFrameX(byIndex: index, items: newData)
                    layout.firstDeleteChildX.updateValue(x, forKey: delete)

                    //记录需要插入的菜单index的第一个child的frame
                    if layout.firstInsertChildX[index] == nil {
                        let x = getCellFrameX(byIndex: delete, items: items)
                        layout.firstInsertChildX.updateValue(x, forKey: index)
                    }
                }
            } else if item.identifier == BarButtonIdentifier.checkbox.rawValue {
                //工具栏尾部的checkbox和reminder删除动画以工具栏最后一条分割线的x坐标为终
                checkboxIndex = delete
                let x = getCellFrameX(byIndex: lastSeparatorIndex?.base ?? 0, items: newData)
                layout.firstDeleteChildX.updateValue(x, forKey: delete)
            } else if item.identifier == BarButtonIdentifier.reminder.rawValue {
                if checkboxIndex > 0, let checkboxFrameX = layout.firstDeleteChildX[checkboxIndex] {
                    layout.firstDeleteChildX.updateValue(checkboxFrameX, forKey: delete)
                }
            }
        }
    }

    ///collectionview使用自定义动画
    private func animateLoadData(newData: [ToolBarItemInfo]) {
        guard let (inserts, deletes, updates) = getDifferents(newData: newData) else {
            items = newData
            reloadItems()
            return
        }

        setInsertIndexMap(newData: newData, inserts: inserts)
        setDeleteIndexMap(newData: newData, deletes: deletes)

        var cellsFrame = getCellsFrame()
        //因为cell重用的关系，获取的frame不一定跟cell的index一一对应，所以需要按照坐标排序
        cellsFrame?.sort { $0.origin.x < $1.origin.x }

        layout.cellsFrame = cellsFrame
        layout.animationType = items.count > newData.count ? .fold : .unfold

        for (i, item) in newData.enumerated() {
            if let oldIndex = items.index(of: item) {
                layout.newIndexMapOld.updateValue(oldIndex, forKey: i)
            }
        }

        for index in insertFirstChildIndex {
            let x = getCellFrameX(byIndex: index.value, items: newData)
            layout.firstInsertChildX.updateValue(x, forKey: index.key)
        }

        for index in deleteFirstChildIndex {
            let x = getCellFrameX(byIndex: index.value, items: items)
            layout.firstDeleteChildX.updateValue(x, forKey: index.key)
        }

        updateItems(list: newData, inserts: inserts, deletes: deletes, updates: updates, completion: { [weak self] in
            guard let `self` = self else { return }
            self.updateCanScrollTips()
            self.resetAnimationIndex()
        })
    }

    override public func refreshStatus(status: [ToolBarItemInfo], service: DocsJSService) {
        var isNewTypeToolbar = false
        if service != jsService {
            isNewTypeToolbar = true
            resetPanelIdentifier(service)
            jsService = service
            updateMode()
        }

        let realStatus = status
        for (i, it) in realStatus.enumerated() where it.identifier == BarButtonIdentifier.separator.rawValue {
            it.subIdentifier = String(i)
        }

        if isIPadToolbar && !isNewTypeToolbar {
            //添加展开、收起动画
            animateLoadData(newData: realStatus)
        } else {
            items = status
            reloadItems()
        }

        //如果前端有返回选中的，就选中
        func changeSubPanel(_ selected: ToolBarItemInfo) {
            delegate?.didClickedItem(selected, panel: self, emptyClick: false, isFromRefresh: true)
            subPanelIdentifier = selected.identifier
            itemCollectionView.reloadData()
        }

//        if let realDelegate = toolDelegate {
        if let highlighted = showingChildrenItem(),
           highlighted.identifier == BarButtonIdentifier.insertImage.rawValue {
            changeSubPanel(highlighted)
        } else {
            displayKeyboard()
        }
//        }
        // TODO: 解决一二级面板同时刷新无法获取选中cell的坐标，存在依赖问题。
        // 判断当前一级工具栏是否有cells，如果没有需要等待它刷新完成再进行update。
        // Refactor: 先暂时这样解决，后续需要梳理更新场景彻底解决该问题。
        if itemCollectionView.visibleCells.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
                self._updateAttachedToolBarIfNeed()
            }
        } else {
            self._updateAttachedToolBarIfNeed()
        }
        updateCanScrollTips()
    }

    ///获取当前所有可见cell的frame，用来做动画
    private func getCellsFrame() -> [CGRect]? {
        return itemCollectionView.visibleCells.map({ $0.frame })
    }

    ///获取当前cell的x坐标，动画需要
    private func getCellFrameX(byIndex: Int, items: [ToolBarItemInfo]) -> CGFloat {
        var offsetX: CGFloat = DocsMainToolBarV2.Const.contentInsetPadding
        guard byIndex > 0, byIndex < items.count else { return offsetX }
        let data = items[0...byIndex - 1]
        data.forEach { (toobarInfo) in
            switch toobarInfo.identifier {
            case BarButtonIdentifier.highlight.rawValue:
                offsetX += DocsMainToolBarV2.Const.highlightCellWidth
            case BarButtonIdentifier.separator.rawValue:
                offsetX += DocsMainToolBarV2.Const.separateWidth
            case BarButtonIdentifier.fontSize.rawValue:
                offsetX += DocsMainToolBarV2.Const.fontSizeCellWidth
            default:
                offsetX += DocsMainToolBarV2.Const.itemWidth
            }
        }
        return offsetX
    }

    override public func getCellFrame(byToolBarItemID: String) -> CGRect? {
        //通过ToolBarItemID去获取对应cell的frame
        let cellAccessibilityIdentifierID = Const.cellIdentifierPrefix + byToolBarItemID
        let cellArr = itemCollectionView.visibleCells
        for cell in cellArr where cell.accessibilityIdentifier == cellAccessibilityIdentifierID {
            return cell.convert(cell.bounds, to: self)
        }
        return nil
    }

    ///滚动到指定item的位置
    public override func rollToItem(byID id: String) {
        var indexPath = IndexPath(row: 0, section: 0)
        for (i, item) in items.enumerated() where item.identifier == id {
            indexPath.row = i
        }
        itemCollectionView.scrollToItem(at: indexPath, at: .left, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
            OnboardingManager.shared.targetView(for: [.docInsertTable], updatedExistence: true)
        }
    }

    private func updateToolBarHeight(height: CGFloat = Const.mainToolbarHeight) {
        let toolBar = subviews.first { return $0 is SKSubToolBarPanel }
        guard let subToolBarPanel: SKSubToolBarPanel = (toolBar as? SKSubToolBarPanel),
              let subToolBarHeight = subToolBarPanel.getCurrentDisplayHeight(),
              subToolBarHeight > 0 else {
            toolDelegate?.updateToolBarHeight(height)
            return
        }
        //iPad转屏后刷新布局
        subToolBarPanel.refreshViewLayout()
        //有subToolBar显示时，发生转屏后，会重新刷新toolBar
        toolDelegate?.updateToolBarHeight(max(subToolBarHeight, height))
    }

    private func _updateAttachedToolBarIfNeed() {
        var showingItem: String?
        let index = items.firstIndex { item -> Bool in
            if item.childrenIsShow {
                showingItem = item.identifier
                return true
            }
            return false
        }
        if let willShowMainIndex = index, showingItem != BarButtonIdentifier.insertImage.rawValue {
            showAttachedToolBar(at: willShowMainIndex, animated: self.showingItemID != showingItem)
            showingItemID = showingItem ?? ""
        } else {
            hideAttachedToolBar(true)
        }
    }

    private func hasHighlightPanel() -> Bool {
        return subPanelIdentifier != DocsMainToolBar.nullMark && subPanelIdentifier != DocsMainToolBar.keyboardMark
    }

    private func updateMode() {
        if jsService == DocsJSService.sheetToolBarJsName {
            mode = .floating
        } else {
            mode = .common
        }
    }

//    private func index(of identifier: String, datas: [ToolBarItemInfo]) -> Int {
//        let index = datas.firstIndex { return $0.identifier == identifier }
//        return index ?? -1
//    }

    /// sheet回调
    ///
    /// - Parameter selected: 是否有数据
    func reloadFloatingKeyboard(selected: Bool) {
        guard mode == .floating else { return }
        let shoudSelected = selected && !hasHighlightPanel()
        setKeyboard(selected: shoudSelected)
    }

//    private func selectedItems() -> ToolBarItemInfo? {
//        var selected: ToolBarItemInfo?
//        for item in self.items where item.childrenIsShow {
//            selected = item
//            break
//        }
//        return selected
//    }

    private func showingChildrenItem() -> ToolBarItemInfo? {
        var selected: ToolBarItemInfo?
        for item in self.items where item.childrenIsShow {
            selected = item
            break
        }
        return selected
    }

    @objc
    private func onClickKeyboard() {
        onTapticFeedback()
        let keyboard = ToolBarItemInfo(identifier: BarButtonIdentifier.keyboard.rawValue)
        if items.count > 0 { keyboard.jsMethod = items[0].jsMethod }
        // emptyclick指的是在选中的时候继续点击
        delegate?.didClickedItem(keyboard, panel: self, emptyClick: toolDelegate?.keyboardIsShow ?? keyboardSelected)
        toolDelegate?.clickKeyboardItem(resign: true)
        resetPanelIdentifier(jsService)
        setKeyboard(selected: true)
        reloadItems()
    }

    private func onTapticFeedback() {
//       feedbackGenerator.selectionChanged()
    }

    func setKeyboard(selected: Bool) {
        let keyboardIsShow = toolDelegate?.keyboardIsShow ?? selected
        let img = keyboardIsShow ? UDIcon.keyboardDisplayOutlined : UDIcon.keyboardOutlined
        keyboardView.icon.image = img.ud.withTintColor(UDColor.iconN1)
        keyboardSelected = keyboardIsShow
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DocsMainToolBarV2 {
    private func showAttachedToolBar(at index: Int, animated: Bool = true) {
        guard index < items.count else { return }
        let item = items[index]
        guard let children = item.children, let type = item.childrenOrientationType else {
            return
        }
        let point: CGPoint? = {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = itemCollectionView.cellForItem(at: indexPath) {
                return cell.convert(cell.bounds.center, to: self)
            }
            return nil
        }()
        var tmpPoint: CGPoint?
        var isHidden = false
        if subviews.contains(where: { return $0 is DocsAttachedToolBar }) {
            let toolBar = subviews.first { return $0 is DocsAttachedToolBar }
            if let str = (toolBar as? DocsAttachedToolBar)?.identifier, item.identifier == str {
                //展示的是同个二级面板的时候才需要记住位置
                tmpPoint = (toolBar as? DocsAttachedToolBar)?.contentoffSet
            }
            if toolBar?.isHidden == true {
                isHidden = true
            }
            hideAttachedToolBar(false)
        }
        let attachedToolBar = DocsAttachedToolBar(children,
                                                  identifier: item.identifier,
                                                  orientation: type,
                                                  at: point,
                                                  hostViewWidth: self.frame.width)
        attachedToolBar.onDidSelect { [weak self] (item, attachedToolBar, value) in
            if item.identifier == BarButtonIdentifier.highlight.rawValue
                || item.identifier == BarButtonIdentifier.backColor.rawValue
                || item.identifier == BarButtonIdentifier.foreColor.rawValue {
                self?.subPanelIdentifier = item.identifier
            }
            (self?.delegate as? SKAttachedTBPanelDelegate)?.didClickedItem(item, panel: attachedToolBar, value: value)
        }
        if isHidden == true {
            attachedToolBar.isHidden = true
        }
        _addAttachedToolBar(attachedToolBar, at: point, animated: animated)
        reportShowAttachToolBar(identifier: item.identifier)
        if animated == true {
            //二级工具栏需要滚动到最后一个selected的item
            if type == .horizontal {
                let item = children.last { (item) -> Bool in
                    return item.isSelected == true
                }
                attachedToolBar.scrollToItem(item?.identifier)
            }
        } else {
            //移除二级工具栏后，需要记住上次打开的是在哪个地方
            guard let lastOffset = tmpPoint else { return }
            attachedToolBar.setContentOffset(offSet: lastOffset)
        }
    }

    public func hideAttachedToolBar(_ animated: Bool = true, forceRemove: Bool = true) {
        let toolBar = subviews.first { return $0 is DocsAttachedToolBar }
        updateToolBarHeight()

        if forceRemove {
            //只有移除的情况下需要置为""，不移除的情况下不用改
            showingItemID = ""
        }

        // 修改 superView 相关高度
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                guard let tb = toolBar else { return }
                tb.snp.updateConstraints({ (make) in
                    make.bottom.equalTo(self.itemCollectionView.snp.top).offset(tb.frame.size.height + 5)
                })
                tb.alpha = 0
                self.layoutIfNeeded()
            }, completion: { (_) in
                if forceRemove == true {
                    toolBar?.removeFromSuperview()
                } else {
                    toolBar?.isHidden = true
                }
            })
        } else {
            if forceRemove == true {
                toolBar?.removeFromSuperview()
            } else {
                toolBar?.isHidden = true
            }
            layoutIfNeeded()
        }
    }

    //点击颜色选择面板的返回按钮，会发送通知把隐藏的工具栏展示出来
    //该方法会在面板移除动画开始前调用
    public func showAttachToolBar(_ animated: Bool) {
        let toolBar = subviews.first { return $0 is DocsAttachedToolBar }
        guard let attachedToolBar: DocsAttachedToolBar = (toolBar as? DocsAttachedToolBar) else {
            //无二级工具栏时刷新toolBar的高度
            toolDelegate?.updateToolBarHeight(Const.mainToolbarHeight)
            return
        }
        attachedToolBar.isHidden = false
        _addAttachedToolBar(attachedToolBar, animated: animated)
    }

    //使用传进来的DocsAttachedToolBar进行展示
    private func _addAttachedToolBar(_ attachedToolBar: DocsAttachedToolBar,
                                     at point: CGPoint? = nil,
                                     animated: Bool) {
        let attachedTBHeight: CGFloat = {
            if attachedToolBar.orientation == .horizontal {
                return Const.attachedToolbarHeight + Const.floatPadding
            } else {
                return attachedToolBar.items.totalHeight + Const.floatPadding
            }
        }()
        // 修改 superView 相关高度
        if attachedToolBar.isHidden == false {
            let height = attachedTBHeight + Const.mainToolbarHeight
            if point == nil {
                toolDelegate?.updateToolBarHeight(height)
            } else {
                updateToolBarHeight(height: height)
            }
        }
        if animated { // 带动画时需要在下文修改透明度
            attachedToolBar.alpha = 0
        }
//        //之前有可能是hidden的，所以需要改为false
//        attachedToolBar.isHidden = false
        addSubview(attachedToolBar)
        sendSubviewToBack(attachedToolBar)
        attachedToolBar.snp.makeConstraints { (make) in
            make.height.equalTo(attachedTBHeight)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(itemCollectionView.snp.top).offset(attachedTBHeight)
        }
        layoutIfNeeded()
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            attachedToolBar.snp.updateConstraints { (make) in
                make.bottom.equalTo(self.itemCollectionView.snp.top).offset(0)
            }
            attachedToolBar.alpha = 1
            self.layoutIfNeeded()
        }
    }

    func updateCanScrollTips() {
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
            if self.itemCollectionView.contentSize.width > self.itemCollectionView.frame.width {
                if self.itemCollectionView.contentOffset.x > 0 {
                    self.gradientShadow.isHidden = true
                } else {
                    self.gradientShadow.isHidden = false
                }
            } else {
                self.gradientShadow.isHidden = true
            }
        }
    }
}

extension DocsMainToolBarV2: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCanScrollTips()
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        layout.offsetX = offsetX
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.row < items.count {
            let toolbarItemInfo: ToolBarItemInfo = items[indexPath.row]
            if toolbarItemInfo.identifier == BarButtonIdentifier.separator.rawValue {
                //如果是分割线，需要单独设置item大小，其他使用默认尺寸
                return CGSize(width: Const.separateWidth, height: Const.itemHeight)
            }
            if toolbarItemInfo.identifier == BarButtonIdentifier.highlight.rawValue {
                //如果是高亮色选择item，则需要单独设置item大小，其它使用默认尺寸
                return CGSize(width: Const.highlightCellWidth, height: Const.itemHeight)
            }
            if toolbarItemInfo.identifier == BarButtonIdentifier.fontSize.rawValue {
                //sheet@doc工具栏
                //如果是字体大小选择item，则需要单独设置item大小，其它使用默认尺寸
                return CGSize(width: Const.fontSizeCellWidth, height: Const.itemHeight)
            }
            return CGSize(width: Const.itemWidth, height: Const.itemHeight)
        } else {
            return CGSize(width: Const.itemWidth, height: Const.itemHeight)
        } //数据异常处理，返回默认尺寸
    }

    fileprivate func paddingAdjust(_ padding: CGFloat) -> CGFloat {
        
        var newpadding = padding
        
        if padding < Const.itemMinMargin {
            // 如果间距小于最小间距，使用最小间距
            newpadding = Const.itemMinMargin
        } else if padding > Const.itemMaxMargin {
            // 如果间距大于最大间距，使用最大间距
            newpadding = Const.itemMaxMargin
        }
        
        return newpadding
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        if isIpad == true { return 0 } //ipadUI布局采用固定padding，固定item大小。

        guard self.confirmItemPadding == CGFloat.greatestFiniteMagnitude else {
            return self.confirmItemPadding
        }
        
        let sub = items.maxWidth - items.totalWidth
        let count = CGFloat(items.count)
        let padding = sub / count
        self.confirmItemPadding = paddingAdjust(padding)
        return self.confirmItemPadding
    }
    

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.item < items.count else { return collectionView.dequeueReusableCell(withReuseIdentifier: Const.iconCellId, for: indexPath) }
        let item = items[indexPath.item]
        
        // 如果是分割线
        if item.identifier == BarButtonIdentifier.separator.rawValue {
            let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: Const.seperatorID, for: indexPath)
            cell1.accessibilityIdentifier = Const.cellIdentifierPrefix + item.identifier
            return cell1
        }

        // 如果是高亮item
        if item.isHighlight {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Const.highlightCellId, for: indexPath)
            cell.accessibilityIdentifier = Const.cellIdentifierPrefix + item.identifier
            if let highLightCell = cell as? DocsToolBarHighlightCell {
                if let image = item.image {
                    highLightCell.lightItUp(light: item.isSelected, image: image)
                    highLightCell.isEnabled = item.isEnable
                }
                if let json = item.valueJSON {
                    highLightCell.updateHighlightColor(for: json)
                }
                highLightCell.index = indexPath
                highLightCell.needRotation = true
                highLightCell.delegate = self
                docsMainToolBarV2Delegate = highLightCell
            }
            return cell
        }

        // 如果是字号item
        if item.isAdjustFont {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Const.fontSizeCellId, for: indexPath)
            cell.accessibilityIdentifier = Const.cellIdentifierPrefix + item.identifier
            if let list = item.valueList, let index = list.firstIndex(where: { $0 == item.value }) {
                (cell as? DocsToolBarAdjustCell)?.updateData(list, index: index)
            }
            (cell as? DocsToolBarAdjustCell)?.adjustViewDelegate = self
            return cell
        }

        // 其他 cell 类型
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Const.iconCellId, for: indexPath)
        if let cell = cell as? DocsToolBarCell {
            cell.updateAppearance(image: item.image, enabled: item.isEnable, adminLimit: item.adminLimit, selected: item.isSelected, hasChildren: item.childrenIsShow, showOriginColor: item.imageNoTint)
            //颜色选择器颜色填充
            if item.identifier == BarButtonIdentifier.foreColor.rawValue {
                cell.accessibilityIdentifier = Const.cellIdentifierPrefix + item.identifier
                let colorVal = (item.value ?? "#000000").lowercased()
                cell.updateSelectColor(for: colorVal)
            } else {
                cell.updateSelectColor(for: nil)
            }
        }
        _setupAccessibilityIdentifier(for: cell, toolItem: item)
        
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let item = items[indexPath.item]
        guard item.isEnable else { return }
        if item.identifier == BarButtonIdentifier.highlight.rawValue ||
            item.isAdjustFont {
            return
        }
        
        // admin管控(前端控制)，native只需要回调前端事件
        if item.adminLimit && item.identifier == BarButtonIdentifier.insertImage.rawValue {
            delegate?.didClickedItem(item, panel: self, emptyClick: false)
            onTapticFeedback()
            return
        }

        if item.identifier == BarButtonIdentifier.foreColor.rawValue {
            subPanelIdentifier = item.identifier
            delegate?.didClickedItem(item, panel: self, value: item.value)
            onTapticFeedback()
            return
        }

        if item.identifier == BarButtonIdentifier.hn.rawValue {
            item.childrenIsShow = !item.childrenIsShow
            //因为前端不处理Hn点击事件，菜单项不会刷新，这里需要手动设置一下，隐藏掉其它二级工具栏
            items.forEach { (toolBar) in
                //隐藏其它的二级工具栏
                if toolBar.identifier != BarButtonIdentifier.hn.rawValue {
                    toolBar.childrenIsShow = false
                }
            }
            _updateAttachedToolBarIfNeed()
        } else {
            items.forEach { (toolBar) in
                if toolBar.identifier == BarButtonIdentifier.hn.rawValue {
                    toolBar.childrenIsShow = false
                }
            }
        }

        let hasSubPanel = item.identifier == BarButtonIdentifier.insertImage.rawValue
        if hasSubPanel {
            setKeyboard(selected: false)
        }

        if subPanelIdentifier == item.identifier,
            tapAgainBackItems().contains(item.identifier) {
            delegate?.didClickedItem(item, panel: self, emptyClick: true)
            displayKeyboard()
        } else if subPanelIdentifier == item.identifier {
            delegate?.didClickedItem(item, panel: self, emptyClick: true)
        } else {
            delegate?.didClickedItem(item, panel: self, emptyClick: false)
            if hasSubPanel {
                subPanelIdentifier = item.identifier
            } else { subPanelIdentifier = DocsMainToolBar.keyboardMark } //没有subPanel的时候需要将identifier重置为默认，否则subPanel状态会出错
        }
        onTapticFeedback()
        
        if item.identifier == BarButtonIdentifier.checkbox.rawValue {
            //点击checkbox之后，mention的位置会变动，所以需要延时展示
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000) {
                OnboardingManager.shared.targetView(for: [.docTodoCenterIntro], updatedExistence: true)
            }
        }
    }

    private func _setupAccessibilityIdentifier(for cell: UICollectionViewCell, toolItem: ToolBarItemInfo) {
        cell.accessibilityIdentifier = "docs.comment.toolbar." + toolItem.identifier
    }

    func getDifferents(newData: [ToolBarItemInfo]) -> ([Int], [Int], [Int])? {
        let initialItemContainer = ToolBarItemContainer(identifier: "toolbar", items: items)
        let finalItemContainer = ToolBarItemContainer(identifier: "toolbar", items: newData)

        do {
            let differents = try Diff.differencesForSectionedView(initialSections: [initialItemContainer], finalSections: [finalItemContainer])
            var inserts: [Int] = []
            var deletes: [Int] = []
            var updates: [Int] = []
            for different in differents {
                let insert = different.insertedItems.map(\.itemIndex)
                let delete = different.deletedItems.map(\.itemIndex)
                let update = different.updatedItems.map(\.itemIndex)
                inserts.append(contentsOf: insert)
                deletes.append(contentsOf: delete)
                updates.append(contentsOf: update)
            }
            return (inserts, deletes, updates)
        } catch {
            DocsLogger.error("toolbar.standard.differ --- diff failed with error", error: error)
            return nil
        }
    }

    //局部刷新，解决cell复用导致的点击跳动问题
//    func reloadDiffItems(newData: [ToolBarItemInfo]) {
//        guard let (inserts, deletes, updates) = getDifferents(newData: newData) else {
//            items = newData
//            reloadItems()
//            return
//        }
//
//        UIView.setAnimationsEnabled(false)
//        CATransaction.setDisableActions(true)
//        updateItems(list: newData, inserts: inserts, deletes: deletes, updates: updates, completion: { [weak self] in
//            guard let `self` = self else { return }
//            UIView.setAnimationsEnabled(true)
//            self.updateCanScrollTips()
//            self.resetAnimationIndex()
//        })
//        CATransaction.commit()
//    }

    func updateItems(list: [ToolBarItemInfo], inserts: [Int], deletes: [Int], updates: [Int], completion: (() -> Void)?) {
        let convertToIndexPath = { (indexs: [Int]) -> [IndexPath] in
            return indexs.map {
                IndexPath(row: $0, section: 0)
            }
        }
        let diffOptimize = UserScopeNoChangeFG.LJW.toolbarDiffOptimize
        //list新数据源，item旧数据源, updates需要更新的index数组
        if !updates.isEmpty, diffOptimize {
            self.itemCollectionView.performBatchUpdates({
                //先更新一下需要reload的工具栏项
                for index in updates {
                    guard index < items.count else { return }
                    let updateId = items[index].identifier
                    if let newItemInfo = list.first(where: { $0.identifier == updateId }) {
                        items[index] = newItemInfo
                    }
                }
                itemCollectionView.reloadItems(at: convertToIndexPath(updates))
            })
        }
        
        items = list
        self.itemCollectionView.performBatchUpdates({
            itemCollectionView.deleteItems(at: convertToIndexPath(deletes))
            itemCollectionView.insertItems(at: convertToIndexPath(inserts))
            if !diffOptimize {
                itemCollectionView.reloadItems(at: convertToIndexPath(updates))
            }
        }, completion: { _ in
            completion?()
        })
    }

    func resetAnimationIndex() {
        self.insertFirstChildIndex.removeAll()
        self.deleteFirstChildIndex.removeAll()
        self.layout.newIndexMapOld.removeAll()
        self.layout.firstInsertChildX.removeAll()
        self.layout.firstDeleteChildX.removeAll()
        self.layout.deleteParentIndexMap.removeAll()
        self.layout.insertParentIndexMap.removeAll()
    }

    func reloadItems() {
        //去掉collectionView的动画
        UIView.performWithoutAnimation {
            itemCollectionView.reloadData()
            itemCollectionView.layoutIfNeeded()
        }
    }

    /// 切换到keyboard面板
    private func displayKeyboard() {
        if subPanelIdentifier == BarButtonIdentifier.highlight.rawValue
            || subPanelIdentifier == BarButtonIdentifier.foreColor.rawValue
            || subPanelIdentifier == BarButtonIdentifier.backColor.rawValue {
            return
        }
        resetPanelIdentifier(jsService)
        toolDelegate?.requestDisplayKeyboard()
        setKeyboard(selected: true)
    }

    func tapAgainBackItems() -> Set<String> {
        let backItems: Set<String> = [BarButtonIdentifier.attr.rawValue,
                                      BarButtonIdentifier.sheetTxtAtt.rawValue,
                                      BarButtonIdentifier.mnTextAtt.rawValue]
        return backItems
    }
}

// statistics
extension DocsMainToolBarV2 {
    func reportShowAttachToolBar(identifier: String) {
        guard SKDisplay.pad,
              let info = self.toolDelegate?.docsInfo(),
              let publicParams = DocsToolBar.toolBarPublicParamsWith(info: info) else {
            return
        }
        var event: DocsTracker.EventType
        let params = publicParams
        switch info.type {
        case .mindnote:
            if identifier == BarButtonIdentifier.mnTextFormat.rawValue {
                event = DocsTracker.EventType.bottomToolbarHeaderIPadView
            } else if identifier == BarButtonIdentifier.mnTextStyle.rawValue {
                event = DocsTracker.EventType.bottomToolbarFontColorIPadView
            } else {
                return
            }
        default:
            return
        }
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }
}

extension DocsMainToolBarV2: DocsToolBarHighlightCellDelegate {
    public func hasChooseAction(isOpenPanel: Bool, index: IndexPath) {
        guard let highlightIndex = items.firstIndex(where: { $0.identifier == BarButtonIdentifier.highlight.rawValue }) else { return }
        let item = items[highlightIndex]
        if var jsonValue = item.valueJSON {
            jsonValue["openPanel"] = isOpenPanel
            item.valueJSON = jsonValue
            item.updateJsonString(value: jsonValue)
        }
        DocsMainToolBarV2.hasPresentHighlightPanle = isOpenPanel
        if DocsMainToolBarV2.hasPresentHighlightPanle,
           highlightIndex < itemCollectionView.visibleCells.count,
           let highlightCell = itemCollectionView.cellForItem(at: IndexPath(row: highlightIndex, section: 0)) as? DocsToolBarHighlightCell {
            highlightCell.lightSelectView()
        }
        delegate?.didClickedItem(item, panel: self, emptyClick: true)
    }
}

extension DocsMainToolBarV2: FontSizeAdjustViewDelegate {
    public func hasUpdateValue(cell: UICollectionViewCell, value: String) {
        guard let tmp: IndexPath = itemCollectionView.indexPath(for: cell) else { return }
        let item = items[tmp.row]
        if item.isSeparator {
            return
        }
        delegate?.didClickedItem(item, panel: self, value: value)
    }
}

// MARK: - Private Extension
// 这里都是计算属性，小心使用
fileprivate extension Array where Element == ToolBarItemInfo {
    var countOfSeparator: Int {
        filter { return $0.isSeparator }.count
    }

    var countOfAdjustFont: Int {
        filter { return $0.isAdjustFont }.count
    }

    var countOfItems: Int {
        count - countOfSeparator - countOfAdjustFont
    }

    var totalWidth: CGFloat {
        let widthOfItems = CGFloat(countOfItems) * DocsMainToolBarV2.Const.itemWidth
        let widthOfSeparators = CGFloat(countOfSeparator) * DocsMainToolBarV2.Const.separateWidth
        //计算一级工具栏的宽度，用来判断是否小于屏幕，判断是否需要添加padding
        return widthOfItems + widthOfSeparators + DocsMainToolBarV2.Const.contentInsetPadding
    }

    var maxWidth: CGFloat {
        let ur = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let width: CGFloat = (ur.docs.editorManager?.currentEditor?.frame.width ?? 0) - DocsMainToolBarV2.Const.itemWidth
        return width
    }
}

fileprivate extension ToolBarItemInfo {
    var isSeparator: Bool {
        return identifier == BarButtonIdentifier.separator.rawValue
    }
    var isAdjustFont: Bool {
        return identifier == BarButtonIdentifier.fontSize.rawValue
    }
    var isHighlight: Bool {
        return identifier == BarButtonIdentifier.highlight.rawValue
    }
}
