//
//  SheetOperationToolkitViewController.swift
//  SpaceKit
//
//  Created by Webster on 2019/11/11.
//  插入 和 操作 两个面板都用了这里

import SKCommon
import SKBrowser
import SKUIKit
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon

protocol SheetOperationToolkitViewControllerDelegate: AnyObject {
    func didClickItem(identifier: String, finishGuide: Bool, itemIsEnable: Bool, controller: SheetOperationToolkitViewController)
    func shouldDisplayBadge(identifier: String, controller: SheetOperationToolkitViewController) -> Bool
    func clearBadges(identifiers: [String], controller: SheetOperationToolkitViewController)
}

final class SheetOperationToolkitViewController: SheetToolkitFacadeViewController {
    
    weak var delegate: SheetOperationToolkitViewControllerDelegate?

    override var resourceIdentifier: String {
        return BadgedItemIdentifier.toolkitOperation.rawValue
    }

    private lazy var itemListView: SKOperationView = {
        let view = SKOperationView(frame: .zero, displayIcon: true)
        view.delegate = self
        view.clickToHighlight = true
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.addSubview(itemListView)
        itemListView.snp.makeConstraints { (make) in
            make.width.height.equalToSuperview()
            make.left.top.equalToSuperview()
        }
    }
    
    override func update(_ tapItem: SheetToolkitTapItem) {
        super.update(tapItem)
        
        let infos = tapItem.items.map { $1 }
        var adjustedInfos = infos
        
        // 先将 insertRowColumn 四个合并成一个
        var insertList = [ToolBarItemInfo]()
        let insertIds: [BarButtonIdentifier] = [.addRowUp, .addRowDown, .addColLeft, .addColRight]
        for identifier in insertIds {
            if let item = tapItem.info(for: identifier.rawValue) {
                insertList.append(item)
            }
        }
        adjustedInfos = infos.filter { (item) -> Bool in
            guard let identifier = BarButtonIdentifier(rawValue: item.identifier) else {
                return true
            }
            return !insertIds.contains(identifier)
        }
        if !insertList.isEmpty {
            let insertInfosWrapper = ToolBarItemInfo(identifier: BarButtonIdentifier.addRowColumn.rawValue)
            insertInfosWrapper.insertList = insertList
            insertInfosWrapper.parentIdentifier = BarButtonIdentifier.addRowColumn.rawValue
            adjustedInfos.insert(insertInfosWrapper, at: 0)
        }

        guard let aggregatedResult = adjustedInfos.aggregateByGroupID() as? [[ToolBarItemInfo]] else { return }
        
        itemListView.refresh(infos: aggregatedResult)
    }
}

extension SheetOperationToolkitViewController: SKOperationViewDelegate {
    var isInPopover: Bool { false }
    
    func didClickItem(identifier: String, finishGuide: Bool, itemIsEnable: Bool, disableReason: OperationItemDisableReason, at view: SKOperationView) {
        delegate?.didClickItem(identifier: identifier, finishGuide: finishGuide, itemIsEnable: itemIsEnable, controller: self)
    }

    func shouldDisplayBadge(identifier: String, at view: SKOperationView) -> Bool {
        return delegate?.shouldDisplayBadge(identifier: identifier, controller: self) ?? false
    }
}
