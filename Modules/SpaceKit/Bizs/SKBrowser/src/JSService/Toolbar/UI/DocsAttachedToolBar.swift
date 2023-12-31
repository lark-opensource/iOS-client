//
//  DocsAttachedToolBar.swift
//  DocsSDK
//
//  Created by Gill on 2020/5/27.
//

import UIKit
import SnapKit
import SKResource
import UniverseDesignColor

// MARK: - DocsAttachedToolBar
public final class DocsAttachedToolBar: UIView {
    private(set) var items: [ToolBarItemInfo] = []
    private(set) var orientation: ToolbarOrientation
    private(set) var identifier: String
    private let collectionImpl: DocsAttachedToolBarCollectionViewImpl
    public var contentoffSet: CGPoint {
        return collectionImpl.contentOffset
    }

    private var itemCollectionView: UICollectionView {
        return self.collectionImpl.itemCollectionView
    }
    
    private lazy var leftMaskView = UIView(frame: CGRect(x: 0, y: 0, width: 46, height: 46)).construct { it in
        let layer = CAGradientLayer()
        layer.position = it.center
        layer.bounds = it.bounds
        layer.needsDisplayOnBoundsChange = true
        layer.cornerRadius = 7
        layer.masksToBounds = true
        it.layer.addSublayer(layer)
        layer.ud.setColors([
            UDColor.N00.withAlphaComponent(0.94),
            UDColor.N00.withAlphaComponent(0.70),
            UDColor.N00.withAlphaComponent(0.00)
        ])
        layer.locations = [0, 0.63, 1]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
    }
    
    private lazy var rightMaskView = UIView(frame: CGRect(x: 0, y: 0, width: 46, height: 46)).construct { it in
        let layer = CAGradientLayer()
        layer.position = it.center
        layer.bounds = it.bounds
        layer.needsDisplayOnBoundsChange = true
        layer.cornerRadius = 7
        layer.masksToBounds = true
        it.layer.addSublayer(layer)
        layer.ud.setColors([
            UDColor.N00.withAlphaComponent(0.00),
            UDColor.N00.withAlphaComponent(0.70),
            UDColor.N00.withAlphaComponent(0.94)
        ])
        layer.locations = [0, 0.37, 1]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
    }

    public func scrollToItem(_ itemIdentifiID: String?) {
        collectionImpl.scrollToItem(itemIdentifiID)
    }

    lazy var shadowLayer: CALayer = {
        let layer = CALayer()
        layer.cornerRadius = 4
        return layer
    }()

    init(_ items: [ToolBarItemInfo],
         identifier: String,
         orientation: ToolbarOrientation,
         at point: CGPoint? = nil,
         hostViewWidth: CGFloat) {
        self.items = items
        self.identifier = identifier
        self.orientation = orientation
        self.collectionImpl = DocsAttachedToolBarCollectionViewImpl.impl(for: orientation, items: items)
        super.init(frame: .zero)
        
        addSubview(itemCollectionView)
        layer.insertSublayer(shadowLayer, below: itemCollectionView.layer)
        let shouldAddMasks = collectionImpl.makeConstraints(at: point, hostViewWidth: hostViewWidth)
        if shouldAddMasks {
            setupSidesMask()
        }
        shadowLayer.ud.setBorderColor(UDColor.bgBody)
        shadowLayer.ud.setShadow(type: .s4Down)
        collectionImpl.onCollectionDidScroll { [weak self] (scrollToLeft, scrollToRight) in
            if !scrollToLeft, !scrollToRight {
                self?.leftMaskView.isHidden = true
                self?.rightMaskView.isHidden = true
            } else {
                self?.leftMaskView.isHidden = scrollToLeft
                self?.rightMaskView.isHidden = scrollToRight
            }
        }
    }
    
    private func setupSidesMask() {
        addSubview(leftMaskView)
        addSubview(rightMaskView)
        leftMaskView.isUserInteractionEnabled = false
        rightMaskView.isUserInteractionEnabled = false
        leftMaskView.snp.makeConstraints { (make) in
            make.left.top.equalTo(itemCollectionView).inset(1)
            make.width.height.equalTo(46)
        }
        rightMaskView.snp.makeConstraints { (make) in
            make.right.top.equalTo(itemCollectionView).inset(1)
            make.width.height.equalTo(46)
        }

        leftMaskView.isHidden = true
        rightMaskView.isHidden = true
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        shadowLayer.frame = itemCollectionView.frame
    }

    func setContentOffset(offSet: CGPoint) {
        self.collectionImpl.contentOffset = offSet
    }

    func onDidSelect(_ handler: @escaping (ToolBarItemInfo, DocsAttachedToolBar, Any?) -> Void) {
        collectionImpl.onCollectionDidSelect { [weak self] (_, index, value) in
            guard let self = self else { return }
            let item = self.items[index]
            guard item.isEnable else { return }
            if value.isEmpty == false {
                handler(item, self, value)
            } else {
                handler(item, self, item.value)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
