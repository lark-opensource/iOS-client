//
//  NoPermissionActionInterceptor.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/5/17.
//

import Foundation
import RxSwift
import RxCocoa
import LarkSecurityComplianceInfra
import LarkContainer
import LarkSecurityComplianceInterface

final class NoPermissionActionInterceptorImp: NoPermissionActionInterceptor {

    private let handlers = NSHashTable<NoPermissionActionInterceptorHandler>.weakObjects()
    private let http = DeviceManagerAPI()
    private let bag = DisposeBag()
    private let blockList: [NoPermissionRustActionModel.Action] = [
        .mfa,
        .network,
        .deviceCredibility,
        .deviceOwnership
    ]

    private let completed = BehaviorRelay<Void>(value: ())

    init() {
        completed
            .skip(1)
            .flatMapLatest { [weak self] () -> Observable<Void> in
                guard let `self` = self else { return .just(()) }
                return self.http
                    .ping()
                    .debug()
                    .mapToVoid()
            }
            .subscribe()
            .disposed(by: bag)
    }

    func addInterceptorHandler(_ handler: NoPermissionActionInterceptorHandler?) {
        DispatchQueue.main.async {
            guard let aHandler = handler else { return }
            Logger.info("will add handler: \(aHandler), \(aHandler.bizName) \(aHandler.bizPriority)")
            if !self.handlers.contains(aHandler) {
                self.handlers.add(aHandler)
                Logger.info("did add handler: \(aHandler), \(aHandler.bizName) \(aHandler.bizPriority)")
            }
        }
    }

    func removeInterceptorHandler(_ handler: NoPermissionActionInterceptorHandler?) {
        DispatchQueue.main.async {
            guard let aHandler = handler else { return }
            Logger.info("will remove handler: \(aHandler), \(aHandler.bizName) \(aHandler.bizPriority)")
            if self.handlers.contains(aHandler) {
                self.handlers.remove(aHandler)
                Logger.info("did remove handler: \(aHandler), \(aHandler.bizName) \(aHandler.bizPriority)")
            }
        }
    }

    func onInterceptorCompleted() {
        Logger.info("interceptor completed: \(self.handlers.count)")
        completed.accept(())
    }

    func handleModelAction(_ model: NoPermissionRustActionModel) -> Bool {

        let name = model.model?.name ?? ""
        let extra = model.model?.params ?? [:]
        guard blockList.contains(model.action) else { return  false}
        if let handler = handlers.allObjects.first(where: { $0.needIntercept() }) {
            var results = [NSString: NSNumber]()
            extra.forEach { element in
                results[element.key as NSString] = element.value.number
            }
            handler.onReceiveSecurityAction(name as NSString, extra: results)
            Logger.info("SCInterceptor handler: \(handler), \(handler.bizName) \(handler.bizPriority) model: \(model)")
            return true
        }
        return false
    }

}
