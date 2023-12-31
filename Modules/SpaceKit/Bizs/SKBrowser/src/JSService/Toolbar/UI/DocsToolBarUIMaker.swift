//
//  DocsToolBarUIMaker.swift
//  SpaceKit
//
//  Created by Webster on 2019/5/27.
//

import Foundation
import SKCommon
import SKUIKit
import SKResource
import EENavigator
import UniverseDesignColor
import UniverseDesignIcon
import SKFoundation
import LarkContainer

public final class DocsToolBarUIMaker: SKToolBarUICreater {
    private weak var mainDelegate: DocsMainToolBarDelegate?
    
    let userResolver: UserResolver
    
    public init(mainToolDelegate: DocsMainToolBarDelegate?, userResolver: UserResolver) {
        mainDelegate = mainToolDelegate
        self.userResolver = userResolver
    }

    public func updateMainToolBarPanel(_ status: [ToolBarItemInfo], service: DocsJSService) -> SKMainToolBarPanel {
        let newTool = DocsMainToolBar(status, service: service, userResolver: userResolver)
        newTool.toolDelegate = mainDelegate
        return newTool
    }

    public func updateMainToolBarPanelV2(_ status: [ToolBarItemInfo], service: DocsJSService, isIPadToolbar: Bool) -> SKMainToolBarPanel {
        let newTool = DocsMainToolBarV2(status, service: service, userResolver: userResolver, isIPadToolbar: isIPadToolbar)
        newTool.toolDelegate = mainDelegate
        return newTool
    }

    public func updateSubToolBarPanel(_ status: [ToolBarItemInfo]?, identifier: String, curWindow: UIWindow?) -> SKSubToolBarPanel? {
        guard let barIdentifier = BarButtonIdentifier(rawValue: identifier) else { return nil }
        switch barIdentifier {
        case .attr, .textTransform:
            return DocsSubToolBar.docsAttributionPanel(status)
        case .insertImage:
            return DocsSubToolBar.assetPanel(status, docsInfo: mainDelegate?.docsInfo(), curWindow: curWindow)
        case .sheetTxtAtt:
            return DocsSubToolBar.sheetAttributionPanel(status)
        case .sheetCellAtt:
            return DocsSubToolBar.sheetCellManagerPanel(status)
        case .mnTextAtt:
            return DocsSubToolBar.mindNodeAttributionPanel(status)
        default:
            return nil
        }
    }

}

public protocol DocsMainToolBarDelegate: AnyObject {
    var keyboardIsShow: Bool { get }
    func clickKeyboardItem(resign: Bool)
    func requestDisplayKeyboard()
    func itemHasSubPanel(_ item: ToolBarItemInfo) -> Bool
    func updateToolBarHeight(_ height: CGFloat)
    func docsInfo() -> DocsInfo?
}

extension DocsMainToolBarDelegate {
    public func docsInfo() -> DocsInfo? {
        return nil
    }
}

public enum DocsMainTBMode {
    case common
    case floating
}

/// Docs 一级工具栏的构建
public final class DocsMainToolBar: SKMainToolBarPanel {

    static let keyboardMark = "KEYBOARD-001"
    static let nullMark = "NULL-001"
    private(set) var items: [ToolBarItemInfo] = [ToolBarItemInfo]()
    //特殊需求的处理delegate
    weak var toolDelegate: DocsMainToolBarDelegate?
    private var keyboardSelected = false
    private var mode: DocsMainTBMode = .common
    private var jsService: DocsJSService = DocsJSService.docToolBarJsName
    private var subPanelIdentifier: String = DocsMainToolBar.keyboardMark
    private var keyboardView: DocsToolBarItemView = DocsToolBarItemView(frame: CGRect(origin: .zero, size: CGSize(width: Const.itemWidth, height: Const.itemWidth)))
    private lazy var feedbackGenerator = UISelectionFeedbackGenerator()
    
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

    private struct Const {
        static let itemWidth: CGFloat = 44
        static let itemHeight: CGFloat = 44
        static let imageWidth: CGFloat = 24
        static let itemPadding: CGFloat = 8
        static let horPadding: CGFloat = 7
        static let staticHorPadding: CGFloat = 6
        static let separateWidth: CGFloat = 1
        static let separateVerPadding: CGFloat = 10
        static let inherentHeight: CGFloat = 44
        static let sheetInputViewHeight: CGFloat = 44
        static let iconCellId: String = "iconCellId"
    }

    private lazy var layout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: Const.itemWidth, height: Const.itemWidth)
        layout.minimumLineSpacing = Const.itemPadding
        layout.sectionInset = UIEdgeInsets(top: 0, left: Const.horPadding, bottom: 0, right: Const.horPadding)
        return layout
    }()

    private lazy var itemCollectionView: UICollectionView = {
        let frame = CGRect(origin: .zero, size: CGSize(width: self.userResolver.navigator.mainSceneWindow?.frame.width ?? 0, height: Const.inherentHeight))
        let cv = UICollectionView(frame: frame, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UDColor.bgBody
        cv.showsHorizontalScrollIndicator = false
        cv.register(DocsToolBarCell.self, forCellWithReuseIdentifier: Const.iconCellId)
        return cv
    }()

    init(_ layouts: [ToolBarItemInfo], service: DocsJSService, userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(frame: .zero)
        self.items = layouts
        self.jsService = service
        self.backgroundColor = UDColor.bgBody
        updateMode()
        feedbackGenerator.prepare()
        addSubview(itemCollectionView)
        addSubview(gradientShadow)
        addSubview(keyboardView)
        keyboardView.layer.ud.setShadowColor(UDColor.shadowDefaultSm)
        keyboardView.layer.shadowRadius = 4
        keyboardView.layer.shadowOpacity = 1
        keyboardView.layer.shadowOffset = CGSize(width: -2, height: 0)
        keyboardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickKeyboard)))
        setKeyboard(selected: true)
        keyboardView.backgroundColor = UDColor.bgBody
        keyboardView.snp.makeConstraints { (make) in
            make.width.height.equalTo(Const.itemWidth)
            make.bottom.trailing.equalToSuperview()
        }
        gradientShadow.snp.makeConstraints { (make) in
            make.width.equalTo(Const.itemWidth)
            make.height.equalTo(Const.itemHeight)
            make.bottom.equalToSuperview()
            make.trailing.equalTo(keyboardView.snp.leading)
        }
        itemCollectionView.snp.makeConstraints { (make) in
            make.trailing.equalTo(keyboardView.snp.leading)
            make.leading.bottom.equalToSuperview()
            make.height.equalTo(Const.inherentHeight)
        }
        itemCollectionView.reloadData()
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
    }

    func reset() {
        resetPanelIdentifier(jsService)
        itemCollectionView.reloadData()
    }

    private func resetPanelIdentifier(_ service: DocsJSService) {
        if service == DocsJSService.sheetToolBar {
            subPanelIdentifier = DocsMainToolBar.nullMark
            mode = .floating
        } else {
            subPanelIdentifier = DocsMainToolBar.keyboardMark
            mode = .common
        }
    }

    func showAttachedToolBar(at index: Int) {
        guard index < items.count else { return }
        let item = items[index]
        guard let children = item.children, let type = item.childrenOrientationType else {
            return
        }
        let point: CGPoint? = {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = itemCollectionView.cellForItem(at: indexPath) {
                return cell.convert(cell.frame.center, to: self)
            }
            return nil
        }()

        if subviews.contains(where: { return $0 is DocsAttachedToolBar }) {
            hideAttachedToolBar()
        }
        let attachedToolBar = DocsAttachedToolBar(children,
                                                  identifier: item.identifier,
                                                  orientation: type,
                                                  at: point,
                                                  hostViewWidth: self.frame.width)
        attachedToolBar.onDidSelect { [weak self] (item, attachedToolBar, value) in
            (self?.delegate as? SKAttachedTBPanelDelegate)?.didClickedItem(item, panel: attachedToolBar, value: value)
        }
        _addAttachedToolBar(attachedToolBar, at: point)
    }

    func hideAttachedToolBar() {
        let toolBar = subviews.first { return $0 is DocsAttachedToolBar }
        toolBar?.removeFromSuperview()

    }

    private func _addAttachedToolBar(_ attachedToolBar: DocsAttachedToolBar,
                                     at point: CGPoint? = nil) {
        let attachedTBHeight: CGFloat = {
            if attachedToolBar.orientation == .horizontal {
                return Const.inherentHeight
            } else {
                return attachedToolBar.items.totalHeight
            }
        }()

        toolDelegate?.updateToolBarHeight(attachedTBHeight + Const.inherentHeight)
        self.snp.updateConstraints { (make) in
            make.height.equalTo(attachedTBHeight + Const.inherentHeight)
        }
        layoutIfNeeded()
        addSubview(attachedToolBar)
        _layout(attachedToolBar, at: point, with: attachedTBHeight)
    }

    private func _layout(_ attachedToolBar: DocsAttachedToolBar,
                         at point: CGPoint? = nil,
                         with height: CGFloat) {
        attachedToolBar.snp.makeConstraints { (make) in
            make.height.equalTo(height)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(itemCollectionView.snp.top)
        }
    }

    override public func refreshStatus(status: [ToolBarItemInfo], service: DocsJSService) {
        if service != jsService {
            resetPanelIdentifier(service)
            jsService = service
        }

        let oldData = self.items
        self.items = status
        //如果前端有返回选中的，就选中
        if let selected = selectedItems(),
            let realDelegate = toolDelegate,
            realDelegate.itemHasSubPanel(selected) {
            delegate?.didClickedItem(selected, panel: self, emptyClick: false)
            subPanelIdentifier = selected.identifier
            itemCollectionView.reloadData()
            return
        }

        let oldIndex = index(of: subPanelIdentifier, datas: oldData)
        let nowIndex = index(of: subPanelIdentifier, datas: self.items)

        if hasHighlightPanel(),
            oldData.count == self.items.count,
            oldIndex >= 0,
            nowIndex >= 0,
            oldIndex == nowIndex,
        items[nowIndex].isEnable { } else {
            displayKeyboard()
        }

        /// 展示二级面板，需要在 reload 之后，因为需要知道二级面板的位置
        if let willShowMainIndex = items.firstIndex(where: { return $0.childrenIsShow }) {
            showAttachedToolBar(at: willShowMainIndex)
        } else {
            hideAttachedToolBar()
        }

        reloadItems()
        updateCanScrollTips()
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

    private func index(of identifier: String, datas: [ToolBarItemInfo]) -> Int {
        let index = datas.firstIndex { return $0.identifier == identifier }
        return index ?? -1
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

    /// sheet回调
    ///
    /// - Parameter selected: 是否有数据
    func reloadFloatingKeyboard(selected: Bool) {
        guard mode == .floating else { return }
        let shoudSelected = selected && !hasHighlightPanel()
        setKeyboard(selected: shoudSelected)
    }

    private func selectedItems() -> ToolBarItemInfo? {
        var selected: ToolBarItemInfo?
        for item in self.items where item.isSelected {
            selected = item
            break
        }
        return selected
    }

    @objc
    private func onClickKeyboard() {
        let keyboardHasSelect = keyboardSelected
        onTapticFeedback()
        setKeyboard(selected: true)
        let keyboard = ToolBarItemInfo(identifier: BarButtonIdentifier.keyboard.rawValue)
        if items.count > 0 { keyboard.jsMethod = items[0].jsMethod }
        // emptyclick指的是在选中的时候继续点击
        delegate?.didClickedItem(keyboard, panel: self, emptyClick: keyboardHasSelect)
        toolDelegate?.clickKeyboardItem(resign: keyboardHasSelect)
        resetPanelIdentifier(jsService)
        reloadItems()
    }

    private func onTapticFeedback() {
       feedbackGenerator.selectionChanged()
    }

    func setKeyboard(selected: Bool) {
        let img = selected ? UDIcon.keyboardDisplayOutlined : UDIcon.keyboardOutlined // icon_global_shortcuts_nor
        keyboardView.icon.image = img.ud.withTintColor(UDColor.iconN1)
        keyboardSelected = selected
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension DocsMainToolBar: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCanScrollTips()
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Const.iconCellId, for: indexPath)
        let item = items[indexPath.item]
        if let cell = cell as? DocsToolBarCell {
            cell.updateAppearance(image: item.image,
                                  enabled: item.isEnable,
                                  adminLimit: item.adminLimit,
                                  selected: item.isSelected,
                                  hasChildren: subPanelIdentifier == item.identifier,
                                  showOriginColor: item.imageNoTint)
        }
        _setupAccessibilityIdentifier(for: cell, toolItem: item)
        
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.item]
        guard item.isEnable else { return }

        let hasSubPanel = toolDelegate?.itemHasSubPanel(item) ?? false
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
            }
        }
        reloadItems()
        onTapticFeedback()
    }

    private func _setupAccessibilityIdentifier(for cell: UICollectionViewCell, toolItem: ToolBarItemInfo) {
        cell.accessibilityIdentifier = "docs.comment.toolbar." + toolItem.identifier
    }

    func reloadItems() {
        itemCollectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.itemCollectionView.layoutIfNeeded()
        }
    }

    /// 切换到keyboard面板
    private func displayKeyboard() {
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
