//
//  OpenCombineButton.swift
//  SpeedTest
//
//  Created by bytedance on 2020/9/4.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import OpenCombine

@available(iOS 13.0, *)
func testOpenCombineMap() {
    var subs = Set<AnyCancellable>()
    var sum = 0

    for _ in 0 ..< 100000 {
        AnyPublisher<Int, Never>.create { subscriber in
            for _ in 0 ..< 1 {
                _ = subscriber.receive(1)
            }
        }
        .map { $0 }
        .map { $0 }
        .map { $0 }
        .map { $0 }
        .map { $0 }
        .sink(receiveValue: { x in
            sum += x
        })
        .store(in: &subs)

    }

    subs.forEach { $0.cancel() }
}

@available(iOS 13.0, *)
func testOpenCombineFlatMap() {
    var subs = Set<AnyCancellable>()
    var sum = 0

    for _ in 0 ..< 100000 {
        AnyPublisher<Int, Never>.create { subscriber in
            for _ in 0 ..< 1 {
                _ = subscriber.receive(1)
            }
        }
        .flatMap { x in Just(x) }
        .flatMap { x in Just(x) }
        .flatMap { x in Just(x) }
        .flatMap { x in Just(x) }
        .flatMap { x in Just(x) }
        .sink(receiveValue: { x in
            sum += x
        })
        .store(in: &subs)

    }

    subs.forEach { $0.cancel() }
}

@available(iOS 13.0, *)
func testOpenCombineMerge() {
    var subs = Set<AnyCancellable>()
    var sum = 0

    for _ in 0 ..< 100000 {
        let publisher1 = PassthroughSubject<Int, Never>()
        AnyPublisher<Int, Never>.create { subscriber in
            for _ in 0 ..< 1 {
                _ = subscriber.receive(1)
            }
        }
        .merge(with: publisher1)
        .sink(receiveValue: { x in
            sum += x
        })
        .store(in: &subs)

    }

    subs.forEach { $0.cancel() }
}

@available(iOS 13.0, *)
func testOpenCombineLatest() {
    var subs = Set<AnyCancellable>()
    var sum = 0

    for _ in 0 ..< 100000 {
        let publisher1 = PassthroughSubject<Int, Never>()
        AnyPublisher<Int, Never>.create { subscriber in
            for _ in 0 ..< 1 {
                _ = subscriber.receive(1)
            }
        }
        .combineLatest(publisher1)
        .sink(receiveValue: { _ in
            sum += 1
        })
        .store(in: &subs)

    }

    subs.forEach { $0.cancel() }
}
