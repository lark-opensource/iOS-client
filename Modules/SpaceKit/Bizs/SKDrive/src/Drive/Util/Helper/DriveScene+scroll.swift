//
//  DriveScene+scroll.swift
//  SKDrive
//
//  Created by chensi(陈思) on 2022/9/14.
//  


import Foundation
import RxSwift
import RxCocoa
import UIKit

private var scrollObserverKey: UInt8 = 0

extension UIScrollView {
    
    func setupScrollObserver(tolerance: TimeInterval = 1,
                             onStart: @escaping () -> Void,
                             onStop: @escaping () -> Void) {
        
        let instance = ScrollObserver(tolerance: tolerance)
        instance.scrollStateChanged = { (oldValue, newValue) in
            if oldValue, !newValue {
                onStop()
            } else if !oldValue, newValue {
                onStart()
            }
        }
        objc_setAssociatedObject(self, &scrollObserverKey, instance, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        self.rx.didScroll.subscribe(onNext: { [weak instance] _ in
            instance?.onDidScroll()
        }).disposed(by: instance.disposeBag)
        
        self.rx.didEndScrollingAnimation.subscribe(onNext: { [weak instance] _ in
            instance?.onDidEndScrollingAnimation()
        }).disposed(by: instance.disposeBag)
    }
}

private class ScrollObserver: NSObject {
    
    /// 滚动停止多少秒后判定为滚动停止
    let tolerance: TimeInterval
    
    /// 滚动状态变化回调 (oldValue, newValue)
    var scrollStateChanged: ((Bool, Bool) -> Void)?
    
    /// 是否正在滚动
    private(set) var isScrolling = false {
        didSet {
            if isScrolling != oldValue {
                scrollStateChanged?(oldValue, isScrolling)
            }
        }
    }
    
    let disposeBag = DisposeBag()
    
    init(tolerance: TimeInterval) {
        self.tolerance = tolerance
    }
    
    @objc
    func onDidScroll() {
        isScrolling = true
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        let selector = #selector(onDidEndScrollingAnimation)
        self.perform(selector, with: nil, afterDelay: tolerance)
    }
    
    @objc
    func onDidEndScrollingAnimation() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        isScrolling = false
    }
}
