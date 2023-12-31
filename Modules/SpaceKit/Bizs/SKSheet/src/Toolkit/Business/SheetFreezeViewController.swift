//
//  SheetFreezeViewController.swift
//  SpaceKit
//
//  Created by Webster on 2019/8/19.
//

import Foundation
import SKCommon
import SKBrowser
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

protocol SheetFreezeViewControllerDelegate: AnyObject {
    func freezeDidRequstUpdate(identifier: String, value: String?, controller: SheetFreezeViewController)
}

class SheetFreezeViewController: SheetScrollableToolkitViewController {
    weak var delegate: SheetFreezeViewControllerDelegate?

    override var resourceIdentifier: String {
        return BadgedItemIdentifier.freeze.rawValue
    }

    private lazy var freezeLayout: AdjustAttributionPanel.PanelLayout = {
        var layout = AdjustAttributionPanel.PanelLayout()
        layout.displayIcon = true
        return layout
    }()

    private lazy var freezeRowView: AdjustAttributionPanel = {
        let view = AdjustAttributionPanel(frame: .zero,
                                          value: "0",
                                          title: "冻结行",
                                          layout: freezeLayout,
                                          showsBottomLine: true,
                                          bgColor: UDColor.bgBodyOverlay)
        view.iconView.image = UDIcon.freezeRowOutlined.ud.withTintColor(UIColor.ud.iconN1)
        view.delegate = self
        view.layer.cornerRadius = 8
        view.layer.maskedCorners = .top
        view.layer.masksToBounds = true
        view.isAccessibilityElement = true
        view.accessibilityIdentifier = "sheets.toolkit.freezeToRow"
        view.accessibilityLabel = "sheets.toolkit.freezeToRow"
        return view
    }()

    private lazy var freezeColView: AdjustAttributionPanel = {
        let view = AdjustAttributionPanel(frame: .zero,
                                          value: "0",
                                          title: "冻结列",
                                          layout: freezeLayout,
                                          showsBottomLine: false,
                                          bgColor: UDColor.bgBodyOverlay)
        view.iconView.image = UDIcon.freeze1ColumnOutlined.ud.withTintColor(UIColor.ud.iconN1)
        view.delegate = self
        view.layer.cornerRadius = 8
        view.layer.maskedCorners = .bottom
        view.layer.masksToBounds = true
        view.isAccessibilityElement = true
        view.accessibilityIdentifier = "sheets.toolkit.freezeToCol"
        view.accessibilityLabel = "sheets.toolkit.freezeToCol"
        return view
    }()

    private lazy var tempUnfreezeButton: SheetTouchFeedbackTextButton = {
        let btn = SheetTouchFeedbackTextButton { [weak self] in
            self?.onTapUnfreeze()
        }
        return btn
    }()

    init(info: ToolBarItemInfo) {
        super.init()
        itemInfo = info
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.addSubview(freezeRowView)
        scrollView.addSubview(freezeColView)
        scrollView.addSubview(tempUnfreezeButton)

        freezeRowView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(scrollView.contentLayoutGuide).inset(itemSpacing)
            make.height.equalTo(itemHeight)
        }
        
        freezeColView.snp.makeConstraints { (make) in
            make.left.right.equalTo(freezeRowView)
            make.height.equalTo(itemHeight)
            make.top.equalTo(freezeRowView.snp.bottom)
        }
        
        tempUnfreezeButton.snp.makeConstraints { (make) in
            make.left.right.equalTo(freezeColView)
            make.height.equalTo(itemHeight)
            make.top.equalTo(freezeColView.snp.bottom).offset(itemSpacing)
            make.bottom.equalTo(scrollView.contentLayoutGuide)
        }
    }

    override func didReceivedTapGesture(view: SheetToolkitNavigationBar) {
        delegate?.freezeDidRequstUpdate(identifier: SheetToolkitNavigationController.backIdentifier, value: nil, controller: self)
        super.didReceivedTapGesture(view: view)
    }

    func update(_ info: ToolBarItemInfo) {
        itemInfo = info
        navigationBar.setTitleText(info.title)
        updateFreezeRowView(info: childrenInfo(type: BarButtonIdentifier.freezeRow))
        updateFreezeColView(info: childrenInfo(type: BarButtonIdentifier.freezeCol))
        updateUnfreezeButton(info: childrenInfo(type: BarButtonIdentifier.tmpToggleFreeze))
        freezeRowView.updateButtonStatus()
        freezeColView.updateButtonStatus()
    }

    private func updateFreezeRowView(info: ToolBarItemInfo?) {
        let height = (info == nil) ? 0 : itemHeight
        if let value = info?.value {
            freezeRowView.updateValue(value: value)
        }
        let isEnable = info?.isEnable ?? true
        freezeRowView.isEnable = isEnable
        let enableImage = UDIcon.freezeRowOutlined.ud.withTintColor(UIColor.ud.iconN1)
        freezeRowView.iconView.image = isEnable ? enableImage : UDIcon.freezeRowOutlined.ud.withTintColor(UIColor.ud.N400)
        freezeRowView.titleLabel.text = info?.title
        freezeRowView.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
    }

    private func updateFreezeColView(info: ToolBarItemInfo?) {
        let height = (info == nil) ? 0 : itemHeight
        if let value = info?.value {
            freezeColView.updateValue(value: value)
        }
        freezeColView.isEnable = info?.isEnable ?? true
        let isEnable = info?.isEnable ?? true
        freezeColView.isEnable = isEnable
        let enableImage = UDIcon.freeze1ColumnOutlined.ud.withTintColor(UIColor.ud.iconN1)
        freezeColView.iconView.image = isEnable ? enableImage : UDIcon.freeze1ColumnOutlined.ud.withTintColor(UIColor.ud.N400)
        freezeColView.titleLabel.text = info?.title
        freezeColView.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
    }

    private func updateUnfreezeButton(info: ToolBarItemInfo?) {
        let height = (info == nil) ? 0 : itemHeight
        tempUnfreezeButton.setTitle(info?.title, for: .normal)
        tempUnfreezeButton.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
    }

    private func childrenInfo(type: BarButtonIdentifier) -> ToolBarItemInfo? {
        guard let children = itemInfo.children else { return nil }
        var dstInfo: ToolBarItemInfo?
        let maybeToolInfos = children.filter({ $0.identifier == type.rawValue })
        if maybeToolInfos.count > 0 {
            dstInfo = maybeToolInfos[0]
        }
        return dstInfo
    }

    private func onTapUnfreeze() {
        delegate?.freezeDidRequstUpdate(identifier: BarButtonIdentifier.tmpToggleFreeze.rawValue, value: nil, controller: self)
    }
}

extension SheetFreezeViewController: AdjustAttributionPanelDelegate {
    func nextBiggerValue(in panel: AdjustAttributionPanel, value: String) -> String {
        guard let freezeInfo = fetchFreezeInfo(view: panel) else { return "0" }
        guard let currentValue = Int(value), freezeInfo.minValue != nil, let maxV = freezeInfo.maxValue else {
            return ""
        }
        return String(min((currentValue + 1), maxV), radix: 10)
    }

    func nextSmallValue(in panel: AdjustAttributionPanel, value: String) -> String {
        guard let freezeInfo = fetchFreezeInfo(view: panel) else { return "0" }
        guard let currentValue = Int(value), let minV = freezeInfo.minValue, freezeInfo.maxValue != nil else {
            return ""
        }
        return String(max((currentValue - 1), minV), radix: 10)
    }

    func canBiggerNow(in panel: AdjustAttributionPanel, value: String) -> Bool {
        guard let freezeInfo = fetchFreezeInfo(view: panel) else { return false }
        guard let currentValue = Int(value), freezeInfo.minValue != nil, let maxV = freezeInfo.maxValue else {
            return false
        }
        return currentValue < maxV
    }

    func canSmallNow(in panel: AdjustAttributionPanel, value: String) -> Bool {
        guard let freezeInfo = fetchFreezeInfo(view: panel) else { return false }
        guard let currentValue = Int(value), let minV = freezeInfo.minValue, freezeInfo.maxValue != nil else {
            return false
        }
        return currentValue > minV
    }

    func hasUpdateValue(value: String, in panel: AdjustAttributionPanel) {
        var type: BarButtonIdentifier = .freezeRow
        if panel === freezeColView { type = .freezeCol }
        delegate?.freezeDidRequstUpdate(identifier: type.rawValue, value: value, controller: self)
    }

    private func fetchFreezeInfo(view: AdjustAttributionPanel) -> ToolBarItemInfo? {
        var type: BarButtonIdentifier = .freezeRow
        if view === freezeColView { type = .freezeCol }
        return childrenInfo(type: type)
    }
}
