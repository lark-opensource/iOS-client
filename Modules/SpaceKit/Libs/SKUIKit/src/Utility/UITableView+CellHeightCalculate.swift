//
//  UITableView+CellHeightCalculate.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2020/3/14.
//  swiftlint:disable line_length

import Foundation
import SKFoundation

extension UITableView {

    /// 清掉所有高度缓存
    public func clearHeightCache() {
        heightIndexPathCache.clear()
    }

    /// 清掉对应cacheKey高度缓存
    public func clearHeightCacheFor(cacheKeys: [String]) {
        _ = cacheKeys.map { heightIndexPathCache.remove(for: $0) }
    }

    /// 获取cell高度, cacheKey为IndexPath
    public func getHeightForCell(cellId: String, cacheKey: String, configBlock: @escaping (_ cell: UITableViewCell) -> Void) -> Float {
        if cellId.isEmpty || cacheKey.isEmpty {
            return 0
        }

        if heightIndexPathCache.hasCache(for: cacheKey) {
            let height = heightIndexPathCache.height(for: cacheKey)
            return height
        }

        let height = calculateForCell(cellId: cellId, configBlock: configBlock)
        heightIndexPathCache.cache(height, for: cacheKey)

        return height
    }

    private func calculateForCell(cellId: String, configBlock: ((_ cell: UITableViewCell) -> Void)) -> Float {
        if cellId.isEmpty {
            return 0
        }
        if let calculateCell = getCalculateCell(cellId: cellId) {
            calculateCell.prepareForReuse()
            configBlock(calculateCell)
            return calculateHeightBySystem(for: calculateCell)
        } else {
            return 0
        }
    }

    private func getCalculateCell(cellId: String) -> UITableViewCell? {
        assert(cellId.isEmpty == false, "cellId cannot be nil \(cellId)")

        var calculateCell = calcultateCellCache[cellId]

        if calculateCell == nil {
            calculateCell = dequeueReusableCell(withIdentifier: cellId)
            if let calculateCell = calculateCell {
                calcultateCellCache[cellId] = calculateCell
            } else {
                assert(calculateCell != nil, "cellId should registered - \(cellId)")
            }
        }
        return calculateCell
    }


   private func calculateHeightBySystem(for calculateCell: UITableViewCell) -> Float {
        let tableViewWidth: Float = Float(frame.width)
        var cellBounds = calculateCell.bounds
        cellBounds.size.width = CGFloat(tableViewWidth)
        calculateCell.bounds = cellBounds

        var heightResult: Float = 0

        if tableViewWidth > 0 {
            let widthCrt = NSLayoutConstraint(item: calculateCell.contentView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: CGFloat(tableViewWidth))

            var edges = [NSLayoutConstraint]()

            widthCrt.priority = UILayoutPriority(rawValue: UILayoutPriority.RawValue(Int(UILayoutPriority.required.rawValue) - 1))

            let left = NSLayoutConstraint(item: calculateCell.contentView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: calculateCell, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: 0)
            let right = NSLayoutConstraint(item: calculateCell.contentView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: calculateCell, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: 0)
            let top = NSLayoutConstraint(item: calculateCell.contentView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: calculateCell, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0)
            let bottom = NSLayoutConstraint(item: calculateCell.contentView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: calculateCell, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0)
            edges = [left, right, top, bottom]
            calculateCell.addConstraints(edges)

            calculateCell.contentView.addConstraint(widthCrt)

            heightResult = Float(calculateCell.contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)

            calculateCell.contentView.removeConstraint(widthCrt)
            calculateCell.removeConstraints(edges)
         }

         if heightResult == 0 {
//            heightResult = Float(calculateCell.sizeThatFits(CGSize(width: Double(Float(tableViewWidth)), height: 0.0)).height)
            DocsLogger.info("tableViewWidth=\(tableViewWidth), heightResult=0, sizeThatFits =\(heightResult)")
         }

         if heightResult == 0 {
            heightResult = 44
         }

         return heightResult
     }
}

extension UITableView {

    private struct PrivatePropertyKey {
        static var heightCacheKey = "heightCacheKey"
        static var calcultateCellIdentifiersKey = "calcultateCellIdentifiersKey"
        static var usingOrientationKey = "orientationKey"
    }

//    private var heightLayoutCache: CellHeightCache<String> {
//        var heightCache = objc_getAssociatedObject(self, &PrivatePropertyKey.heightCacheKey) as? CellHeightCache<String>
//        if heightCache == nil {
//            heightCache = CellHeightCache()
//            objc_setAssociatedObject(self, &PrivatePropertyKey.heightCacheKey, heightCache!, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//        return heightCache!
//    }

   public var disableCacheOrientation: Bool {
        get {
            let ret = objc_getAssociatedObject(self, &PrivatePropertyKey.usingOrientationKey) as? Bool
            return ret ?? false
        }
        set {
            objc_setAssociatedObject(self, &PrivatePropertyKey.usingOrientationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var heightIndexPathCache: CellHeightCache<String> {
        var heightCache = objc_getAssociatedObject(self, &PrivatePropertyKey.heightCacheKey) as? CellHeightCache<String>
        if heightCache == nil {
            heightCache = CellHeightCache(usingOrientation: !self.disableCacheOrientation)
            objc_setAssociatedObject(self, &PrivatePropertyKey.heightCacheKey, heightCache!, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return heightCache!
    }


    private var calcultateCellCache: [String: UITableViewCell] {
        get {
            guard let tempCalcultateCellCache = objc_getAssociatedObject(self, &PrivatePropertyKey.calcultateCellIdentifiersKey) as? [String: UITableViewCell] else {
                let initCalcultateCellCache = [String: UITableViewCell]()
                objc_setAssociatedObject(self, &PrivatePropertyKey.calcultateCellIdentifiersKey, initCalcultateCellCache, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return initCalcultateCellCache
            }
            return tempCalcultateCellCache
        }
        set {
            objc_setAssociatedObject(self, &PrivatePropertyKey.calcultateCellIdentifiersKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }


}



private class CellHeightCache<T: Hashable> {

    private var cacheForPortrait = [T: Float]()
    private var cacheForLandscape = [T: Float]()
    private var cacheForCurrentOrientation: [T: Float] {
        get {
            if usingOrientation {
                return isLandscape ? cacheForLandscape : cacheForPortrait
            } else {
                return cacheForPortrait
            }
        }
        set {
            if usingOrientation {
                isLandscape ? (cacheForLandscape = newValue) : (cacheForPortrait = newValue)
            } else {
                cacheForPortrait = newValue
            }
        }
    }
    
    private var usingOrientation = true
    
    init(usingOrientation: Bool = true) {
        self.usingOrientation = usingOrientation
    }

    private var isLandscape: Bool {
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeRight, .landscapeLeft:
            return true
        default:
            return false
        }
    }

    func clear() {
        cacheForPortrait.removeAll()
        cacheForLandscape.removeAll()
    }

    func hasCache(for key: T) -> Bool {
        if let number = cacheForCurrentOrientation[key], number != -1 {
            return true
        }
        return false
    }

    func remove(for key: T) {
        cacheForCurrentOrientation.removeValue(forKey: key)
    }

    func cache(_ height: Float, for key: T) {
        cacheForCurrentOrientation[key] = height

    }

    func height(for key: T) -> Float {
        return cacheForCurrentOrientation[key] ?? 0
    }

}
