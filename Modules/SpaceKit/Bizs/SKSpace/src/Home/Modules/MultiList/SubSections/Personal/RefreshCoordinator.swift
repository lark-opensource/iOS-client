//
//  RefreshCoordinator.swift
//  SKSpace
//
//  Created by majie.7 on 2023/5/28.
//

import Foundation
import RxSwift
import SKFoundation

public class RefreshCoordinator {

    public typealias Event = (SingleEvent<Completion>) -> Void
    public typealias Completion = () -> Void

    private var events: [Event] = []
    private let disposeBag = DisposeBag()
    
    public init(events: [RefreshCoordinator.Event] = []) {
        self.events = events
    }

    public func enqueue() -> Single<Completion> {
        Single.create { [self] event in
            events.append(event)
            if events.count == 1 {
                event(.success {
                    DispatchQueue.main.async {
                        self.next()
                    }
                })
            }
            return Disposables.create()
        }
        .subscribeOn(MainScheduler.instance)
    }

    private func next() {
        events.remove(at: 0)
        if let nextEvent = events.first {
            nextEvent(.success {
                DispatchQueue.main.async {
                    self.next()
                }
            })
        }
    }
}

class Section {

    let coordinator: RefreshCoordinator

    init(coordinator: RefreshCoordinator) {
        self.coordinator = coordinator
    }

    func refresh() {
        coordinator.enqueue().subscribe(onSuccess: { completion in
            print("first start")
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) {
                print("first complete")
                completion()
            }
        })
    }
}

    
