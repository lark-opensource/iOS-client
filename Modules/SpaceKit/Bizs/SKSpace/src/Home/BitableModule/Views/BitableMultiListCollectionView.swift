//
//  BitableMultiListCollectionView.swift
//  SKSpace
//
//  Created by ByteDance on 2023/11/29.
//

import UIKit
import UniverseDesignColor
import SnapKit
import SKResource
import SKUIKit
import SpaceInterface


public class BitableMultiListCollectionView: UICollectionView {
    //当前展示的子列
    weak var currentSubSection: BitableMultiListSubSection?
    //展示状态 内嵌？全屏
    var currentShowStyle: BitableMultiListShowStyle = .embeded
    var layoutConfig: BitableMultiListUIConfig?
    var isInAnimation: Bool = false
        
    //MARK: 响应事件
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if self.currentShowStyle == .embeded {
            self.next?.touchesBegan(touches, with: event)
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if self.currentShowStyle == .embeded {
            self.next?.touchesMoved(touches, with: event)
        }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if self.currentShowStyle == .embeded {
            self.next?.touchesCancelled(touches, with: event)
        }
    }
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if self.currentShowStyle == .embeded {
            self.next?.touchesEnded(touches, with: event)
        }
    }
    
    //MARK: publicMethod
    func didShowSubSection(_ section: BitableMultiListSubSection) {
         currentSubSection = section
    }
    
   func currentSectionIsNormalList() -> Bool {
       if let section = currentSubSection {
           let sectionState = section.listState
            if case .normal(_) = sectionState {
                return true
            } else {
                return false
            }
        }
       return false
    }
}
