//
//  UIView+Animation.swift
//  ByteView
//
//  Created by ByteDance on 2019/12/24.
//

import Foundation
import RxSwift
extension Reactive where Base: UIView {

    func fadeOut(duration: TimeInterval) -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
            UIView.animate(withDuration: duration, animations: {
                self.base.alpha = 0
            }, completion: { (_) in
                observer.onNext(())
                observer.onCompleted()
            })
            return Disposables.create()
        }
    }

    func fadeIn(duration: TimeInterval) -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
            UIView.animate(withDuration: duration, animations: {
                self.base.alpha = 1
            }, completion: { (_) in
                observer.onNext(())
                observer.onCompleted()
            })
            return Disposables.create()
        }
    }

    func hidden(duration: TimeInterval) -> Observable<Void> {
       return Observable.create { (observer) -> Disposable in
           UIView.animate(withDuration: duration, animations: {
            self.base.isHidden = true
           }, completion: { (_) in
               observer.onNext(())
               observer.onCompleted()
           })
           return Disposables.create()
       }
   }

    func cancelHidden(duration: TimeInterval) -> Observable<Void> {
       return Observable.create { (observer) -> Disposable in
           UIView.animate(withDuration: duration, animations: {
               self.base.isHidden = false
           }, completion: { (_) in
               observer.onNext(())
               observer.onCompleted()
           })
           return Disposables.create()
       }
   }
}
