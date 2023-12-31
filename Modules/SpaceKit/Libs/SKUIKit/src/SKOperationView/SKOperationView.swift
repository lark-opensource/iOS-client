//
//  SKOperationView.swift
//  SKUIKit
//
//  Created by zoujie.andy on 2021/12/13.
//

import Foundation
import SnapKit
import SKResource
import RxSwift
import RxCocoa
import UniverseDesignColor
import UniverseDesignIcon
import UIKit
import SKFoundation

public protocol SKOperationViewDelegate: AnyObject {
    var isInPopover: Bool { get }
    func didClickItem(identifier: String, finishGuide: Bool, itemIsEnable: Bool, disableReason: OperationItemDisableReason, at view: SKOperationView)
    func shouldDisplayBadge(identifier: String, at view: SKOperationView) -> Bool
}

extension SKOperationView {
    public enum Const {
        public static let itemHeight: CGFloat = 48
        static var contentInset: UIEdgeInsets {
            UIEdgeInsets(horizontal: 0, vertical: 8)
        }
        static var sectionInset: UIEdgeInsets {
            UIEdgeInsets(horizontal: 16, vertical: 8)
        }
    }

    public static func estimateContentHeight(infos: [[SKOperationItem]]) -> CGFloat {
        estimateContentHeight(sectionsCount: infos.map(\.count))
    }

    public static func estimateContentHeight(sectionsCount: [Int]) -> CGFloat {
        let sectionCount = CGFloat(sectionsCount.count)
        let itemCount = CGFloat(sectionsCount.reduce(0, +))
        return sectionCount * (Const.sectionInset.top + Const.sectionInset.bottom)
            + itemCount * Const.itemHeight
            + Const.contentInset.top + Const.contentInset.bottom
    }
}

public final class SKOperationView: UIView {
    
    public weak var delegate: SKOperationViewDelegate?
    private var itemInfo: [[SKOperationItem]] = []
    private var displayItemIcon: Bool = true
    private let reuseIdentifier = "com.bytedance.ee.docs.operation"
    private let customCellIdentifier = "com.bytedance.ee.docs.operation.customView"
    private let customCellIdentifier2 = "com.bytedance.ee.docs.operation.customView2"

    public var guideViewIdentifiers: [String]? {
        guard let views = collectionView.visibleCells as? [SKOperationCell] else { return nil }
        var identifiers = [String]()
        for view in views where view.redPoint.isHidden == false {
            identifiers.append(view.buttonIdentifier)
        }
        return identifiers
    }

    private(set) lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = Const.sectionInset
        let view = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.contentInset = Const.contentInset
        view.register(SKOperationCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        view.register(SKInsertRowColumnCell.self, forCellWithReuseIdentifier: SKInsertRowColumnCell.reuseIdentifier)
        view.register(SKCustomOperationView.self, forCellWithReuseIdentifier: customCellIdentifier)
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            view.register(SKCustomOperationView.self, forCellWithReuseIdentifier: customCellIdentifier2)
        }
        view.backgroundColor = .clear
        view.delaysContentTouches = false
        view.dataSource = self
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    /// 是否点击高亮
    public var clickToHighlight = false

    public init(frame: CGRect,
         displayIcon: Bool = true) {
        super.init(frame: frame)
        self.displayItemIcon = displayIcon
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func refresh(infos: [[SKOperationItem]]) {
        itemInfo = infos
        collectionView.reloadData()
    }

    public func relayout() {
        collectionView.collectionViewLayout.invalidateLayout()
    }

    public func setCollectionViewBackgroundColor(color: UIColor) {
        collectionView.backgroundColor = color
    }

    public func setCollectionViewScrollEnable(enable: Bool) {
        collectionView.isScrollEnabled = enable
    }
}

extension SKOperationView: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        DocsLogger.info("SKOperationView cell section count:\(itemInfo.count)")
        return itemInfo.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section < itemInfo.count else {
            return 0
        }
        DocsLogger.info("SKOperationView cell section item count:\(itemInfo[section].count)")
        return itemInfo[section].count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        guard indexPath.section < itemInfo.count,
//              indexPath.item < itemInfo[indexPath.section].count else { return UICollectionView(frame: .zero) }
        let item = itemInfo[indexPath.section][indexPath.item]
        /*
        let identifier = (item.insertList != nil) ? SKInsertRowColumnCell.reuseIdentifier : (item.identifier == "customView" ? customCellIdentifier : reuseIdentifier)
         */
        // 下边逻辑补充customView2相关逻辑，不修改其余线上逻辑，此处架构trick，通过hardcode自定义，建议负责同学通过接口支持自定义cell
        let identifier: String
        if item.insertList != nil {
            identifier = SKInsertRowColumnCell.reuseIdentifier
        } else {
            if item.identifier == "customView" {
                identifier = customCellIdentifier
            } else if item.identifier == "customView2" {
                identifier = customCellIdentifier2
            } else {
                identifier = reuseIdentifier
            }
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        if let dstCell = cell as? SKOperationCell {
            updateOperationCell(dstCell, indexPath: indexPath)
        } else if let dstCell = cell as? SKInsertRowColumnCell, let items = item.insertList {
            dstCell.config(items)
            dstCell.delegate = self
        } else if let customCell = cell as? SKCustomOperationView {
            customCell.setCustomView(view: item.customView)
            customCell.layoutIfNeeded()
            DispatchQueue.main.async {
                item.customViewLayoutCompleted()
            }
        }
        return cell
    }
    
    func updateOperationCell(_ cell: SKOperationCell, indexPath: IndexPath) {
        guard indexPath.section < itemInfo.count,
              indexPath.item < itemInfo[indexPath.section].count else { return }
        let item = itemInfo[indexPath.section][indexPath.item]
        cell.isInPopover = delegate?.isInPopover ?? false
        if item.titleAlignment != .center {
            cell.updateDisplayIcon(display: displayItemIcon)
        }
        cell.configBy(item)
        let showGuide = delegate?.shouldDisplayBadge(identifier: item.identifier, at: self) ?? false
        cell.redPoint.isHidden = !showGuide || !item.shouldShowWarningIcon
        let isSectionFirstItem = indexPath.item == 0
        let isSectionLastItem = indexPath.item == (itemInfo[indexPath.section].count - 1)
        var corners: CACornerMask = []
        if isSectionFirstItem {
            corners.insert(.top)
        }
        if isSectionLastItem {
            corners.insert(.bottom)
            cell.lineView.isHidden = true
        } else {
            cell.lineView.isHidden = false
        }
        cell.roundingCorners = corners
    }
}

extension SKOperationView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard indexPath.section < itemInfo.count,
              indexPath.item < itemInfo[indexPath.section].count else {
                  return .zero
              }
        let item = itemInfo[indexPath.section][indexPath.item]
        var height: CGFloat = Const.itemHeight
        if let customViewHeight = item.customViewHeight {
            height = customViewHeight
        }
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            if item.identifier == "customView2" {
                height = 50
            }
        }
        return CGSize(width: collectionView.frame.width, height: height)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension SKOperationView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? SKOperationCell else { return }
        let info = itemInfo[indexPath.section][indexPath.item]
        let displayGuide = !cell.redPoint.isHidden
        cell.redPoint.isHidden = true
        if clickToHighlight {
            cell.isHighlighted = true
        }
        delegate?.didClickItem(identifier: info.identifier, finishGuide: displayGuide, itemIsEnable: info.isEnable, disableReason: info.disableReason, at: self)
        if let clickHandler = info.clickHandler {
            clickHandler()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        let item = itemInfo[indexPath.section][indexPath.item]
        return !(item.insertList != nil)
    }
}

class SKCustomOperationView: UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCustomView(view: UIView?) {
        guard let view = view, view.superview == nil else {
            return
        }

        contentView.addSubview(view)

        view.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
    }
}
