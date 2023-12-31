//
//  SKBannerContainer.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/3/17.
//

import UIKit
import SnapKit
import SKFoundation
import LarkUIKit

public protocol BannerItem: AnyObject {
    var uiDelegate: BannerUIDelegate? { get set }
    var itemType: SKBannerContainer.ItemType { get }
    var contentView: UIView { get }

    func layoutHorizontalIfNeeded(preferedWidth: CGFloat)
}

public protocol BannerUIDelegate: AnyObject {
    func preferedWidth(_ item: BannerItem) -> CGFloat
    func shouldUpdateHeight(_ item: BannerItem, newHeight: CGFloat)
    func shouldRemove(_ item: BannerItem)
}

public protocol ActionDeleagete: AnyObject {
    func didClose()
}


public protocol BannerContainerDelegate: AnyObject {
    func preferedWidth(_ banner: SKBannerContainer) -> CGFloat
    func shouldUpdateHeight(_ banner: SKBannerContainer, newHeight: CGFloat)
}

@objc public protocol BannerContainerObserver: AnyObject {
    func bannerContainer(_ bannerContainer: SKBannerContainer, heightDidChange height: CGFloat)
}

/// 所有Banner组件的容器(无网、Tips、公告栏、授权、etc...)
public final class SKBannerContainer: UIView {
    public weak var delegate: BannerContainerDelegate?
    private var observers: NSHashTable<BannerContainerObserver> = NSHashTable.weakObjects()
    // MARK: Data
    public private(set) var preferedHeight: CGFloat = 0.0 {
        willSet {
            if preferedHeight != newValue {
                notifyObserverPreferedHeightDidChange(height: newValue)
            }
        }
    }
    private var currentItem: BannerItem? {
        return items.first
    }
    private var currentView: UIView? {
        return items.first?.contentView
    }
    private var items: [BannerItem] = []
    // MARK: UI Widget

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        setupView()
        configure()
    }

    // MARK: External Interface
    public func setItem(_ item: BannerItem) {
        if let existedIdx = items.firstIndex(where: { return $0.itemType == item.itemType }) {
            let itemToBeRemove = items[existedIdx]
            _removeItem(itemToBeRemove)
            items.remove(at: existedIdx)
        }
        items.append(item)
        _setItem(item)
    }

    public func removeItem(_ item: BannerItem) {
        if let existedIdx = items.firstIndex(where: { return $0.itemType == item.itemType }) {
            let itemToBeRemove = items[existedIdx]
            _removeItem(itemToBeRemove)
            items.remove(at: existedIdx)
            if let newItem = items.first {
                _setItem(newItem)
            } else {
                preferedHeight = 0
                SKDisplay.topBannerHeight = 0
                delegate?.shouldUpdateHeight(self, newHeight: 0)
            }
        }
    }

    /// 强制移除所有容器内item，一般在deinit时使用避免内存泄露
    public func removeAll() {
        items.forEach { _removeItem($0) }
        items.removeAll()
        preferedHeight = 0
        delegate?.shouldUpdateHeight(self, newHeight: 0)
    }
    
//    // 监听preferedHeight变化
//    public func addObserver(_ obv: BannerContainerObserver) {
//        if !observers.contains(obv) {
//            observers.add(obv)
//        }
//    }
//    public func removeObserver(_ obv: BannerContainerObserver) {
//       observers.remove(obv)
//    }
    
    public func notifyObserverPreferedHeightDidChange(height: CGFloat) {
        observers.allObjects.forEach {
           $0.bannerContainer(self, heightDidChange: height)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if let preferedWidth = self.delegate?.preferedWidth(self) {
            currentItem?.layoutHorizontalIfNeeded(preferedWidth: preferedWidth)

        }
    }
}

// MARK: Internal Supporting Method
extension SKBannerContainer {
    private func _setItem(_ item: BannerItem) {
        item.uiDelegate = self

        self.items = items.sorted(by: { return $0.itemType.level < $1.itemType.level })
        if let firstItem = items.first, firstItem.itemType == item.itemType {
            // Prepare new items to show
            if items.count > 1 {
                let prevItem = items[1]
                if prevItem.contentView.superview == self {
                    prevItem.contentView.removeFromSuperview()
                    prevItem.contentView.snp.removeConstraints()
                }
            }
            if item.contentView.superview != self {
                addSubview(item.contentView)
                item.contentView.snp.makeConstraints { (make) in
                    make.leading.trailing.top.equalToSuperview()
                    make.height.equalTo(0)
                }
                if let preferedWidth = self.delegate?.preferedWidth(self) {
                    item.layoutHorizontalIfNeeded(preferedWidth: preferedWidth)
                }
            }
        }
    }

    private func _removeItem(_ item: BannerItem) {
        if item.contentView.superview == self {
            item.contentView.removeFromSuperview()
            item.contentView.snp.removeConstraints()
        }
        item.uiDelegate = nil
    }
}

extension SKBannerContainer: BannerUIDelegate {
    public func preferedWidth(_ item: BannerItem) -> CGFloat {
        return frame.width
    }

    public func shouldUpdateHeight(_ item: BannerItem, newHeight: CGFloat) {
        guard let currItem = currentItem else { return }
        if currItem.itemType == item.itemType && currItem.contentView.superview == self {
            preferedHeight = newHeight
            SKDisplay.topBannerHeight = newHeight
            delegate?.shouldUpdateHeight(self, newHeight: newHeight)
            currItem.contentView.snp.updateConstraints { (make) in
                make.height.equalTo(newHeight)
            }
            currItem.contentView.layoutIfNeeded()
        }
    }

    public func shouldRemove(_ item: BannerItem) {
        removeItem(item)
    }
}

extension SKBannerContainer {
    private func setupView() {

    }

    private func configure() {
        backgroundColor = .clear
    }
}

extension SKBannerContainer {
    public enum ItemType: Comparable {
        /// 全局的公告栏
        case bulletin
        /// 警告栏，当前为无网提示和无网同步提示
        case warning
        /// 授权栏，艾特其他人时显示
        case authority
        ///  密级banner
        case secretLevel
        /// 模板
        case template
        /// DLP
        case DLP

        // nolint: magic number
        /// Banner展示优先级，越低的优先展示，修改请与产品核对需求
        var level: Int {
            switch self {
            case .warning: return 100
            case .authority: return 200
            case .DLP: return 250
            case .bulletin: return 300
            case .secretLevel: return 400
            case .template: return 500
            }
        }
        // enable-lint

        public static func < (lhs: SKBannerContainer.ItemType, rhs: SKBannerContainer.ItemType) -> Bool {
            return lhs.level < rhs.level
        }
    }
}
