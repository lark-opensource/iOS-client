//
//  EventEditModelManager.swift
//  Calendar
//
//  Created by huoyunjie on 2022/2/16.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer

// 对外暴露 rxModel
protocol ModelContent {
    associatedtype ContentType
    var rxModel: BehaviorRelay<ContentType>? { get }
}

protocol ModelManager: AnyObject {
    /// 标识
    var identifier: String { get }
    /// 依赖的 model
    var relyModel: [String] { get }
    /// init_method 初始化完成信号
    var initCompleted: BehaviorSubject<Void> { get }
    /// 初始化执行的方法
    var initMethod: ((AnyObserver<Void>) -> Void) { get }
    /// 初始化后执行的方法
    var initLater: (() -> Void)? { get }
    /// 初始化流程的垃圾袋
    var initBag: DisposeBag { get }
}

// MARK: 初始化流程
extension ModelManager {
    private func beginInit() {
        Observable<Void>.create { [weak self] observer in
            self?.initMethod(observer)
            return Disposables.create()
        }.subscribe(onCompleted: { [weak self] in
            self?.initCompleted.onCompleted()
        }).disposed(by: self.initBag)
    }
    private func waitRelyModelInitCompleted(relyModel: [BehaviorSubject<Void>], completed: @escaping () -> Void) {
        if relyModel.isEmpty {
            completed()
        } else {
            Observable.combineLatest(relyModel)
                .subscribe(onCompleted: {
                    completed()
                }).disposed(by: self.initBag)
        }
    }

    func setup(modelsKeyMap: [ModelManager]) {
        var rely_completed = modelsKeyMap
            .filter({ relyModel.contains($0.identifier) })
            .map({ $0.initCompleted })
        waitRelyModelInitCompleted(relyModel: rely_completed) { [weak self] in
            self?.beginInit()
        }
    }

}

// MARK: 循环依赖检测
extension ModelManager {
    private func rely(model: ModelManager, all_models: inout [ModelManager], modelsMap: [ModelManager]) -> Bool {
        if all_models.contains(where: { $0 === model }) {
            return true
        }
        for rely in modelsMap.filter({ relyModel.contains($0.identifier ) }) {
            all_models.append(rely)
            if rely.rely(model: model, all_models: &all_models, modelsMap: modelsMap) { return true }
        }
        return false
    }

    func loopDetect(modelsMap: [ModelManager]) {
        var all_models = [ModelManager]()
        if rely(model: self, all_models: &all_models, modelsMap: modelsMap) {
            assertionFailure()
        }
    }
}

class EventEditModelManager<ContentType>: ModelManager, ModelContent, UserResolverWrapper {
    var identifier: String

    var relyModel: [String]

    var initCompleted: BehaviorSubject<Void> = .init(value: ())

    var initMethod: ((AnyObserver<Void>) -> Void) = { $0.onCompleted() }

    var initLater: (() -> Void)?

    var initBag: DisposeBag = DisposeBag()

    var rxModel: BehaviorRelay<ContentType>?

    let userResolver: UserResolver

    init(userResolver: UserResolver, identifier: String, rely: [String] = [], rxModel: BehaviorRelay<ContentType>? = nil) {
        self.userResolver = userResolver
        self.identifier = identifier
        self.relyModel = rely
        self.rxModel = rxModel
    }
}
