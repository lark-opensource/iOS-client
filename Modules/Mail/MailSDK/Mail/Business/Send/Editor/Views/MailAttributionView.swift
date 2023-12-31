//
//  MailAttributionView.swift
//  DocsSDK
//
//

import UIKit
import SnapKit
import LarkUIKit
import Homeric
import UniverseDesignTheme

protocol MailSubToolBarDelegate: AnyObject {
    // 点击返回按钮
    func clickBackItem(toolBar: MailAttributionView)
    // 刷新子工具条
    func updateSubToolBarStatus(status: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo])
    func setTitleView(_ titleView: UIView)
    func showAttachmentView()
    func insertAttachment(fileModel: MailSendFileModel)
    func resignEditorActive()
    func getFromVC() -> UIViewController?
}

extension MailSubToolBarDelegate {
    func clickBackItem(toolBar: MailAttributionView) {}
    func updateSubToolBarStatus(status: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo]) {}
    func showAttachmentView() {}
    func insertAttachment(fileModel: MailSendFileModel) {}
    func resignEditorActive() {}
    func getFromVC() -> UIViewController? { return nil }
    func clickCloseTxtAttrItem(toolBar: MailAttributionView) {}
}

enum MailAttributionTBMode {
    case common
    case floating
}

/// 文字格式面板
class MailAttributionView: EditorSubToolBarPanel {
    static let keyboardMark = "BACKBTN-001"
    static let nullMark = "NULL-002"
    private var keyBoardSelected = false
    private var mode: MailAttributionTBMode = .common
    private var jsService: EditorJSService = EditorJSService.setToolBarJsName
    private var items: [EditorToolBarItemInfo]
    private let attributionView: MailTextAttributionView
    private let fontTableView = UITableView(frame: .zero)
    private let toolBarTitleView = FontPanelNavigationView(frame: CGRect(x: 0, y: 0, width: Display.width, height: 44))
    private var itemStatus: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo]?
    private var subPanelIdentifier: String = MailAttributionView.keyboardMark
    private var backButton: EditorToolBarItemView = EditorToolBarItemView(frame: CGRect(origin: .zero, size: CGSize(width: Const.itemWidth, height: Const.itemWidth)))
    private lazy var feedbackGenerator = UISelectionFeedbackGenerator()

    private struct Const {
        static let attributionHeight: CGFloat = 324
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

    private lazy var layout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: Const.itemWidth, height: Const.itemWidth)
        layout.minimumLineSpacing = Const.itemPadding
        layout.sectionInset = UIEdgeInsets(top: 0, left: Const.horPadding, bottom: 0, right: Const.horPadding)
        return layout
    }()

    private lazy var itemCollectionView: UICollectionView = {
        let frame = CGRect(origin: .zero, size: CGSize(width: self.bounds.size.width, height: Const.inherentHeight))
        let cv = UICollectionView(frame: frame, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor.ud.bgBody
        cv.showsHorizontalScrollIndicator = false
        cv.register(EditorToolBarCell.self, forCellWithReuseIdentifier: Const.iconCellId)
        return cv
    }()

    init(frame: CGRect, items: [EditorToolBarItemInfo], status: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo]) {
        self.items = items
        let attributionFrame = CGRect(x: 0, y: 0, width: Display.width, height: Const.attributionHeight)
        let layout = ToolBarLayoutMapping.mailAttributeItems()
        attributionView = MailTextAttributionView(status: status, layouts: layout, frame: attributionFrame)
        self.itemStatus = status
        super.init(frame: frame)
        if #available(iOS 13.0, *) {
            let correctTrait = UITraitCollection(userInterfaceStyle: UDThemeManager.getRealUserInterfaceStyle())
            UITraitCollection.current = correctTrait
            overrideUserInterfaceStyle = UDThemeManager.getRealUserInterfaceStyle()
        }
        fontTableView.delegate = self
        fontTableView.dataSource = self
        fontTableView.rowHeight = 48
        attributionView.delegate = self
        setupView()
    }

    func setupView() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(attributionView)
        attributionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        fontTableView.backgroundColor = UIColor.ud.bgBody
        fontTableView.isHidden = true
        fontTableView.register(FontStatusCell.self, forCellReuseIdentifier: "font")
        fontTableView.separatorStyle = .none
        toolBarTitleView.isHidden = true
        addSubview(toolBarTitleView)
        addSubview(fontTableView)
        toolBarTitleView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        fontTableView.snp.makeConstraints { (make) in
            make.top.equalTo(toolBarTitleView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    /// 更新状态
    override func updateStatus(status: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo]) {
        self.itemStatus = status
        attributionView.updateStatus(status: status)
        guard let newItemStatus = self.itemStatus else { return }
        var newItems = [EditorToolBarItemInfo]()
        for item in items {
            guard let identifier = EditorToolBarButtonIdentifier(rawValue: item.identifier) else { continue }
            if let newItem = newItemStatus[identifier] {
                /// 更新item状态
                newItems.append(newItem)
            } else {
                /// 原有的item
                newItems.append(item)
            }
        }
        self.items = newItems
        reloadItems()
        fontTableView.reloadData()
    }

    // 点击返回
    @objc
    private func onClickBack() {
        toolDelegate?.clickBackItem(toolBar: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MailAttributionView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mailFontIdentifiers.count
    }
// swiftlint:disable init_font_with_name
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "font") as? FontStatusCell else { return FontStatusCell(style: .default, reuseIdentifier: "font") }
        let id = mailFontIdentifiers[indexPath.row]
        var hasSelected = false
        for identify in mailFontIdentifiers {
            if let temStatus = itemStatus,
               let selected = temStatus[identify]?.isSelected,
               selected == true {
                hasSelected = true
                break
            }
        }
        let fontName = id.rawValue
        cell.textLabel?.text = EditorToolBarButtonIdentifier.fontDisplayName(id: id)
        cell.textLabel?.font = UIFont(name: fontName, size: 16)
        if let size = cell.textLabel?.font.pointSize, Int(size) != 16 {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        }
        let status = itemStatus?[id]
        if status?.isSelected == true {
            cell.tickImageView.isHidden = false
        } else {
            cell.tickImageView.isHidden = true
        }
        let moreFontFG = FeatureManager.open(.moreFonts)
        if !hasSelected && ((id == .System &&
                                moreFontFG) ||
                                (id == .SansSerif &&
                                    !moreFontFG)) {
            cell.tickImageView.isHidden = false
        }
        return cell
    }
// swiftlint:enable init_font_with_name

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard let item = itemStatus?[mailFontIdentifiers[indexPath.row]] else {
            mailAssertionFailure("fail to find font")
            return
        }
        panelDelegate?.select(item: item, update: nil, view: self)
    }
}

extension MailAttributionView: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Const.iconCellId, for: indexPath) as? EditorToolBarCell else { return UICollectionViewCell() }
        let item = items[indexPath.item]
        cell.isSelected = item.isSelected
        if let image = item.image {
            cell.update(image: image, false, useOrigin: item.identifier == EditorToolBarButtonIdentifier.inlineAI.rawValue)
        }
        cell.isEnabled = item.isEnable
        _setupAccessibilityIdentifier(for: cell, toolItem: item)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.item]
        guard item.isEnable else { return }
        guard EditorToolBarButtonIdentifier(rawValue: item.identifier) != nil else {
            return
        }

        MailTracker.log(event: Homeric.EMAIL_DRAFT_TOOLBAR, params: ["action": item.identifier, "source": "toolbar"])
        panelDelegate?.select(item: item, update: nil, view: self)
    }

    private func _setupAccessibilityIdentifier(for cell: UICollectionViewCell, toolItem: EditorToolBarItemInfo) {
        cell.accessibilityIdentifier = "docs.comment.subtoolbar." + toolItem.identifier
    }

    private func reloadItems() {
        itemCollectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.itemCollectionView.layoutIfNeeded()
        }
    }
}

extension MailAttributionView: TextAttributionViewDelegate {
    func didClickTxtAttributionView(view: MailTextAttributionView, button: AttributeButton) {
        guard let sId = button.itemInfo?.identifier, let barId = EditorToolBarButtonIdentifier(rawValue: sId) else {
            mailAssertionFailure("fail to find sid: \(String(describing: button.itemInfo?.identifier))")
            return
        }
        if let item = itemStatus?[barId] {
            panelDelegate?.select(item: item, update: nil, view: self)
        }
    }

    func didClickFontButton() {
        fontTableView.isHidden = false
        toolBarTitleView.isHidden = false
        toolBarTitleView.backButton.addTarget(self, action: #selector(dismissFontPanel), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFontPanel))
        toolBarTitleView.titleLabel.isUserInteractionEnabled = true
        toolBarTitleView.titleLabel.addGestureRecognizer(tap)
    }

    func didClickCloseTxtAttrPanelButton() {
        toolDelegate?.clickCloseTxtAttrItem(toolBar: self)
    }

    @objc
    func dismissFontPanel() {
        fontTableView.isHidden = true
        toolBarTitleView.isHidden = true
    }
}
