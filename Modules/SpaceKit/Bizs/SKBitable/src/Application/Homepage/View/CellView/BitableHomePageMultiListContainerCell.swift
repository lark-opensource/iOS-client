//
//  BitableHomePageMultiListCell.swift
//
//  Created by ByteDance on 2023/10/29.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import SnapKit
import SKResource
import UniverseDesignTheme

protocol BitableHomePageMultiListContainerCellDelegate: AnyObject {
    func multiListContainerCellDidSwipedUp ()
}

class BitableHomePageMultiListContainerCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    weak var delegate: BitableHomePageMultiListContainerCellDelegate?
    private var startTouchPoint: CGPoint?
    
    //MARK: lifeCycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    //MARK: privateMethod
    private func setUpViews() {
        contentView.isExclusiveTouch = true
        contentView.backgroundColor = BitableHomeLayoutConfig.multiListContainerBgColor()
        contentView.layer.borderWidth = 0.5
        contentView.layer.borderColor = BitableHomeLayoutConfig.multiListContainerBorderColor().cgColor
        contentView.layer.cornerRadius = BitableHomeLayoutConfig.multiListContainerCornerRadius
        contentView.layer.masksToBounds = true
        
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(clickToExpand))
        tapGesture.delegate = self
        self.contentView.addGestureRecognizer(tapGesture)
    }
    
    @objc
    func clickToExpand() {
        self.delegate?.multiListContainerCellDidSwipedUp()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if touches.count > 1 {
            return
        }
        if let touch = touches.first {
            let originPoint = touch.location(in: self)
            startTouchPoint = originPoint
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if touches.count > 1 {
            return
        }
        if let touch = touches.first, let startPoint = startTouchPoint {
            let currentPoint = touch.location(in: self)
            let diff = currentPoint.y - startPoint.y
            if diff < 0 {
                startTouchPoint = nil
                delegate?.multiListContainerCellDidSwipedUp()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        startTouchPoint = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        startTouchPoint = nil
    }
}
