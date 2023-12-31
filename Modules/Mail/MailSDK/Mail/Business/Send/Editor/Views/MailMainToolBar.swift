//
//  MailMainToolBar.swift
//  MailSDK
//
//  Created by majx on 2019/6/13.
//

import Foundation
import UniverseDesignButton
import UniverseDesignIcon

protocol MailMainToolBarDelegate: AnyObject {
    /// 是否有子面板
    func itemHasSubPanel(_ item: EditorToolBarItemInfo, mainBar: MailMainToolBar) -> Bool
    /// 显示二级工具条
    func showSubToolBar(subBar: MailSubToolBar)
    /// 二级工具条 item 选中
    func subToolBarSelect(item: EditorToolBarItemInfo, update value: String?, view: EditorSubToolBarPanel)
}

// MARK: - Mail 一级工具条的构建
class MailMainToolBar: EditorMainToolBarPanel {
    var isSubPanelShow = false
    static let keyboardMark = "KEYBOARD-001"
    static let nullMark = "NULL-001"
    weak var toolDelegate: MailMainToolBarDelegate?
    weak var sendVC: MailSendController?
    private var keyBoardSelected = false
    private var currentTitleView: UIView?
    let topLine = UIView()
    let bottomLine = UIView()
    let lineHeight = 1.0 / UIScreen.main.scale
    let lineHeightOffset = (1.0 / UIScreen.main.scale) / 2
    private var jsService: EditorJSService = EditorJSService.setToolBarJsName
    private var items: [EditorToolBarItemInfo] = [EditorToolBarItemInfo]()
    // 字体初始状态是否可选
    var isAttributionEnabled = false
    var isInQuote = false {
        didSet {
            if isInQuote {
                removeSubToolBar()
            }
        }
    }
    /// 子面板的 Identifier（键盘/图片选择器等等）
    private var subPanelIdentifier: String = MailMainToolBar.keyboardMark
    /// 二级工具条
    private var subToolBar: EditorSubToolBarPanel?
    /// 震动反馈
    private lazy var feedbackGenerator = UISelectionFeedbackGenerator()
    /// 样式配置
    private struct Style {
        static let itemWidth: CGFloat = 44
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

    private lazy var itemCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: Style.itemWidth, height: Style.itemWidth)
        layout.minimumLineSpacing = Style.itemPadding

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(EditorToolBarCell.self, forCellWithReuseIdentifier: Style.iconCellId)
        collectionView.register(EditorToolBarFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "footer")
        return collectionView
    }()
    private lazy var keyboardButton: UIButton = {
        let button = UIButton(frame: CGRect(x: frame.size.width - Style.staticHorPadding - Style.itemWidth, y: 0,
                                            width: Style.itemWidth, height: Style.inherentHeight))
        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.setImage(UDIcon.keyboardDisplayOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ud.iconN1
        button.addTarget(self, action: #selector(keyboardButtonClicked), for: .touchUpInside)
        return button
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(_ items: [EditorToolBarItemInfo], service: EditorJSService) {
        super.init(frame: .zero)
        self.items = items
        self.jsService = service
        self.backgroundColor = UIColor.ud.bgBody
        self.feedbackGenerator.prepare()
        self.addSubview(itemCollectionView)
        self.itemCollectionView.reloadData()
        self.addSubview(keyboardButton)
        self.resetPanelIdentifier()
        topLine.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(topLine)
        bottomLine.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(bottomLine)
        addObsever()
    }

    func addObsever() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc
    func keyboardButtonClicked() {
        isSubPanelShow ? sendVC?.recoverFocusStatus() : hideKeyboard()
        if isSubPanelShow {
            subPanelIdentifier = MailMainToolBar.keyboardMark
            sendVC?.scrollContainer.webView.inputAccessory.realInputView = nil
            
        }
        isSubPanelShow = false
        reloadKeyboardIfNeeded()
        reloadItems()
    }

    func reloadKeyboardIfNeeded() {
        var img = isSubPanelShow ? UDIcon.keyboardOutlined : UDIcon.keyboardDisplayOutlined
        keyboardButton.setImage(img.withRenderingMode(.alwaysTemplate), for: .normal)
    }

    @objc
    func keyboardShow() {
        isHidden = false
        reloadKeyboardIfNeeded()
        DispatchQueue.main.async {
            // Must call this in main async, otherwise the tool bar will be untouchable in some keyboard type
            self.itemCollectionView.reloadData()
        }
    }

    @objc
    func keyboardHide() {
        isHidden = true
        resetPanelIdentifier()
        itemCollectionView.reloadData()
    }

    override func layoutSubviews() {
        itemCollectionView.frame = CGRect(x: Style.staticHorPadding, y: 0,
                                          width: frame.size.width - Style.staticHorPadding * 2 - Style.itemWidth,
                                          height: Style.inherentHeight)
        topLine.frame = CGRect(x: 0, y: 0 + lineHeightOffset, width: frame.size.width, height: lineHeight)
        bottomLine.frame = CGRect(x: 0, y: Style.inherentHeight - lineHeight + lineHeightOffset, width: frame.size.width, height: lineHeight)
        keyboardButton.frame = CGRect(x: frame.size.width - Style.staticHorPadding - Style.itemWidth, y: 0,
                                      width: Style.itemWidth, height: Style.inherentHeight)
    }

    /// 是否正在显示子面板
    var isDisplaySubPanel: Bool {
        return subPanelIdentifier != MailMainToolBar.keyboardMark
    }

    /// 重置面板
    func reset() {
        resetPanelIdentifier()
        itemCollectionView.reloadData()
    }

    /// 重设子面板的标示（默认为键盘）
    private func resetPanelIdentifier() {
        subPanelIdentifier = MailMainToolBar.keyboardMark
        isSubPanelShow = false
    }

    /// 更新单个操作的状态
    func updateItemStatus(newItem: EditorToolBarItemInfo) {
        for item in items where newItem.identifier == item.identifier {
            item.isEnable = newItem.isEnable
            item.isSelected = newItem.isSelected
            if item.identifier == EditorToolBarButtonIdentifier.attr.rawValue, isInQuote {
                item.isEnable = false
            }
            itemCollectionView.reloadData()
            break
        }
        if newItem.identifier == EditorToolBarButtonIdentifier.attr.rawValue, newItem.isEnable == false {
            displayKeyBoard()
            currentTitleView?.isHidden = true
        }
    }

    /// 更新 ToolBar 状态
    override func refreshStatus(status: [EditorToolBarItemInfo], service: EditorJSService, isInQuote: Bool, permissionCode: MailPermissionCode?) {
        if let idx = status.firstIndex(where: { $0.identifier == "attribution" }) {
            status[idx].isEnable = !isInQuote && isAttributionEnabled
        }
        if let idx = status.firstIndex(where: { $0.identifier == EditorToolBarButtonIdentifier.insertImage.rawValue }) {
            status[idx].isEnable = isAttributionEnabled
        }
        
        self.isInQuote = isInQuote
        if service != jsService {
            resetPanelIdentifier()
            jsService = service
        }

        let oldData = self.items
        if let action = sendVC?.action,
            action == .outOfOffice {
            // ooo 屏蔽calendar和signature
            self.items = status.filter({ item in
                return item.identifier != EditorToolBarButtonIdentifier.calendar.rawValue &&
                item.identifier != EditorToolBarButtonIdentifier.signature.rawValue
            })
        } else {
            self.items = status
        }
        
        /// 如果前端有返回选中的，则选中操作
        if let selected = selectedItems(),
            let reallyDelegate = toolDelegate,
            reallyDelegate.itemHasSubPanel(selected, mainBar: self) {
            delegate?.didClickedItem(selected, panel: self, emptyClick: false)
            subPanelIdentifier = selected.identifier
            itemCollectionView.reloadData()
            return
        }
        let oldIndex = index(of: subPanelIdentifier, datas: oldData)
        let nowIndex = index(of: subPanelIdentifier, datas: self.items)

        if hasHightLightPanel(),
            oldData.count == self.items.count,
            oldIndex >= 0,
            nowIndex >= 0,
            oldIndex == nowIndex,
        items[nowIndex].isEnable { } else {
            displayKeyBoard()
        }
        reloadItems()
    }

    private func hasHightLightPanel() -> Bool {
        return subPanelIdentifier != MailMainToolBar.nullMark && subPanelIdentifier != MailMainToolBar.keyboardMark
    }

    private func index(of identifier: String, datas: [EditorToolBarItemInfo]) -> Int {
        let index = datas.firstIndex { return $0.identifier == identifier }
        return index ?? -1
    }

    private func selectedItems() -> EditorToolBarItemInfo? {
        var selected: EditorToolBarItemInfo?
        for item in self.items where item.isSelected {
            selected = item
            break
        }
        return selected
    }
}

extension MailMainToolBar: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header =
                collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                                                withReuseIdentifier: "footer",
                                                                for: indexPath) as? EditorToolBarFooter
        else {
            return UICollectionReusableView()
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    /// 设置操作项及其状态
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Style.iconCellId, for: indexPath) as? EditorToolBarCell else {
            return UICollectionViewCell()
        }
//        if indexPath.section == 0 {
//            var imgStr = isKeyboardShow ? "tb_kb_down" : "tb_kb_up"
//            if isSubPanelShow {
//                imgStr = "tb_kb_up"
//            }
//            cell.update(image: I18n.image(named: imgStr)!, false)
//            cell.isEnabled = true
//        } else {
            let item = items[indexPath.item]
            /// 更新icon及高亮状态
            cell.isEnabled = item.isEnable
            let isSelected = subPanelIdentifier == item.identifier
            if let image = item.image {
                cell.update(image: image,
                            isSelected,
                            useOrigin:item.identifier == EditorToolBarButtonIdentifier.inlineAI.rawValue )
            }
            _setupAccessibilityIdentifier(for: cell, toolItem: item)
//        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let item = items[indexPath.item]
            /// 首先确保当前操作可用
            guard item.isEnable else { return }
            /// 如果有子面板，则隐藏键盘
            let hasSubPanel = toolDelegate?.itemHasSubPanel(item, mainBar: self) ?? false
            if hasSubPanel {
                /// 如果当前面板已打开，再次点击后则关闭面板，显示键盘
                if subPanelIdentifier == item.identifier {
                    delegate?.didClickedItem(item, panel: self, emptyClick: true)
                    displayKeyBoard()
                    isSubPanelShow = false
                } else {
                    isSubPanelShow = true
                    /// 如果当前面板未打开，则打开子面板，隐藏键盘
                    subPanelIdentifier = item.identifier
                    delegate?.didClickedItem(item, panel: self, emptyClick: false)
                }
            } else if item.identifier == "signature" {
                delegate?.didClickSignatureItem(item)
            } else if item.identifier == "attachment" {
                delegate?.didClickAttachmentItem(item)
            } else if item.identifier == "calendar" {
                delegate?.didClickCalendarItem(item)
            } else if item.identifier == "inlineAI" {
                delegate?.didClickAIItem(item)
            } else {
                mailAssertionFailure("other tool bar must have sub panel")
            }
//        }
        /// 刷新items, 并震动反馈
        reloadKeyboardIfNeeded()
        reloadItems()
        onTapticFeedback()
    }
}

extension MailMainToolBar {
    /// 震动反馈
    private func onTapticFeedback() {
        feedbackGenerator.selectionChanged()
    }

    /// 设置cell的identifier
    private func _setupAccessibilityIdentifier(for cell: UICollectionViewCell, toolItem: EditorToolBarItemInfo) {
        cell.accessibilityIdentifier = "docs.comment.toolbar." + toolItem.identifier
    }

    /// 刷新全部操作项
    func reloadItems() {
        itemCollectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.itemCollectionView.layoutIfNeeded()
        }
    }

    /// 显示键盘
    private func displayKeyBoard() {
        resetPanelIdentifier()
        sendVC?.requestDisplayKeyBoard()
    }

    private func hideKeyboard() {
        resetPanelIdentifier()
        sendVC?.requestHideKeyBoardIfNeed()
    }
}

// MARK: - EditorSubToolBarPanelDelegate
extension MailMainToolBar: EditorSubToolBarPanelDelegate {
    func select(item: EditorToolBarItemInfo, update value: String?, view: EditorSubToolBarPanel) {
        toolDelegate?.subToolBarSelect(item: item, update: value, view: view)
    }
}

extension MailMainToolBar: MailSubToolBarDelegate {
    func setTitleView(_ titleView: UIView) {
        if currentTitleView == nil {
            currentTitleView = titleView
            addSubview(titleView)
        } else {
            currentTitleView?.isHidden = false
        }
    }

    func clickBackItem(toolBar: MailAttributionView) {
        // TODO Attach
        removeSubToolBar()
    }
    
    func removeSubToolBar() {
        if let toolbar = subToolBar {
            let animateTime: Double = 0.15
            UIView.animate(withDuration: animateTime, animations: {
                toolbar.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: 1.3, tx: Style.itemWidth, ty: 0)
                toolbar.alpha = 0.0
            }) { (_) in
                toolbar.removeFromSuperview()
                self.subToolBar = nil
            }
        }
        currentTitleView?.isHidden = true
    }

    func updateSubToolBarStatus(status: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo]) {
        if let toolbar = subToolBar {
            toolbar.updateStatus(status: status)
        }
    }
    func showAttachmentView() {
        sendVC?.didClickAttachment()
    }
    func insertAttachment(fileModel: MailSendFileModel) {
        sendVC?.insertAttachment(fileModel: fileModel)
    }

    func resignEditorActive() {
        sendVC?.requestHideKeyBoard()
    }

    func getFromVC() -> UIViewController? {
        return sendVC
    }
}
