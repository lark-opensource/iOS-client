//
//  UndoManager+Extension.swift
//  LarkUIKit
//
//  Created by SuPeng on 12/18/18.
//

import Foundation
import RxSwift

extension UndoManager {
    func registerAndNotifyUndo<TargetType>(withTarget target: TargetType,
                                           handler: @escaping (TargetType) -> Void) where TargetType: AnyObject {
        registerUndo(withTarget: target, handler: handler)
        NotificationCenter.default.post(name: NSNotification.Name.NSUndoManagerDidUndoChange, object: self)
    }

    var canUndoObservale: Observable<Bool> {
        let canBeRevertSubject = PublishSubject<Bool>()
        _ = NotificationCenter.default
            .rx
            .notification(NSNotification.Name.NSUndoManagerDidUndoChange, object: self)
            .map { ($0.object as? UndoManager)?.canUndo ?? false }
            .asDriver(onErrorJustReturn: false)
            .drive(canBeRevertSubject)
        return canBeRevertSubject.asObservable().startWith(canUndo)
    }
}
