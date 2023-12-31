//
//  RxButton.swift
//  SpeedTest
//
//  Created by bytedance on 2020/9/4.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import RxSwift

func testRxMap() {
    var sum = 0
    var disposes: [Disposable] = []
    for _ in 0 ..< 100000 {
        let subscription = Observable<Int>
            .create { observer in
                for _ in 0 ..< 1 {
                    observer.on(.next(1))
                }
                return Disposables.create()
        }
        .map { $0 }
        .map { $0 }
        .map { $0 }
        .map { $0 }
        .map { $0 }
        .subscribe(onNext: { x in
            sum += x
        })

        disposes.append(subscription)
    }
    disposes.forEach { $0.dispose() }
}

func testRxFlatMap() {
    var sum = 0
    var disposes: [Disposable] = []
    for _ in 0 ..< 100000 {
        let subscription = Observable<Int>.create { observer in
            for _ in 0 ..< 1 {
                observer.on(.next(1))
            }
            return Disposables.create()
        }
        .flatMap { x in Observable.just(x) }
        .flatMap { x in Observable.just(x) }
        .flatMap { x in Observable.just(x) }
        .flatMap { x in Observable.just(x) }
        .flatMap { x in Observable.just(x) }
        .subscribe(onNext: { x in
            sum += x
        })

        disposes.append(subscription)
    }
    disposes.forEach { $0.dispose() }
}

func testRxMerge() {
    var sum = 0
    var disposes: [Disposable] = []
    for _ in 0 ..< 100000 {
        let subject0 = PublishSubject<Int>()
        let subject1 = PublishSubject<Int>()

        let disposable = Observable.of(subject0, subject1)
            .merge()
            .subscribe(onNext: { x in
                sum += x
                return
            })

        subject1.onNext(1)

        disposes.append(disposable)
    }
    disposes.forEach { $0.dispose() }
}

func testRxLatest() {
    var sum = 0
    var disposes: [Disposable] = []
    for _ in 0 ..< 100000 {
        let subject0 = PublishSubject<Int>()
        let subject1 = PublishSubject<Int>()

        let disposable = Observable.combineLatest(subject0, subject1)
            .subscribe(onNext: { x in
                sum += 1
                return
            })

        subject1.onNext(1)

        disposes.append(disposable)
    }
    disposes.forEach { $0.dispose() }
}
