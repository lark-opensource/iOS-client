//
//  MagicShareRuntimeImpl+Logic.swift
//  ByteView
//
//  Created by chentao on 2020/4/18.
//

import Foundation
import RxSwift

extension MagicShareRuntimeImpl {
    func bindLogic() {
        logic.automation
            .replies
            .subscribe(onNext: { [weak self] (reply) in
                switch reply {
                case .success(let input, let from, let to):
                    self?.debugLog(message: "logic transfrom successed \(input): \(from) -> \(to)")
                case .failure(let input, let state):
                    self?.debugLog(message: "logic transfrom failed \(input): \(state)")
                @unknown default:
                    break
                }
            })
            .disposed(by: disposeBag)

        logicInputSubject.asObservable()
            .filterByCombiningLatest(followDidRenderFinishObservable.filter({ $0 }).take(1))
            .bind(to: logic.inputObserver)
            .disposed(by: disposeBag)
    }

    func createAutomatonLogic() -> MagicShareRuntimeLogic {
        return MagicShareRuntimeLogic(
            startRecordProducer: startRecordProducer,
            stopRecordProducer: stopRecordProducer,
            startFollowProducer: startFollowProducer,
            stopFollowProducer: stopFollowProducer)
    }

    var startRecordProducer: MagicShareRuntimeLogic.LogicProducer {
        return { [weak self] in
            return Observable.create { [weak self] (observer) -> Disposable in
                self?.magicShareAPI.startRecord()
                self?.startPresenterNoValidFollowStatesTimeout()
                observer.onCompleted()
                return Disposables.create()
            }
            .subscribeOn(MainScheduler.instance)
        }
    }

    var stopRecordProducer: MagicShareRuntimeLogic.LogicProducer {
        return { [weak self] in
            return Observable.create { [weak self] (observer) -> Disposable in
                self?.magicShareAPI.stopRecord()
                self?.cancelPresenterNoValidFollowStatesTimeout()
                observer.onCompleted()
                return Disposables.create()
            }
            .subscribeOn(MainScheduler.instance)
        }
    }

    var startFollowProducer: MagicShareRuntimeLogic.LogicProducer {
        return { [weak self] in
            return Observable.create { [weak self] (observer) -> Disposable in
                self?.magicShareAPI.startFollow()
                self?.startFollowerNoValidFollowStatesTimeout()
                observer.onCompleted()
                return Disposables.create()
            }
            .subscribeOn(MainScheduler.instance)
        }
    }

    var stopFollowProducer: MagicShareRuntimeLogic.LogicProducer {
        return { [weak self] in
            return Observable.create { [weak self] (observer) -> Disposable in
                self?.magicShareAPI.stopFollow()
                self?.cancelFollowerNoValidFollowStatesTimeout()
                observer.onCompleted()
                return Disposables.create()
            }
            .subscribeOn(MainScheduler.instance)
        }
    }
}
