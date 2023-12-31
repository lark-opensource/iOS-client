//
//  MockEmotionResouceDependency.swift
//  LarkEmotionDev
//
//  Created by 李勇 on 2021/3/4.
//

import UIKit
import Foundation
@testable import LarkEmotion
import ThreadSafeDataStructure

extension EmotionResouce {
     func getAllResouces() -> [String: Resouce] {
        pthread_rwlock_rdlock(&resouceLock)
        defer { pthread_rwlock_unlock(&resouceLock) }
        return self.allResouces
    }
}

class MockEmotionResouceDependency: EmotionResouceDependency {
    private(set) var number: SafeAtomic<Int> = 0 + .semaphore

    func fetchImage(key: String, callback: @escaping (UIImage) -> Void) {
        print("10 获取key对应图片 \(Thread.current)")
        DispatchQueue.global().async {
            callback(UIImage())
        }
    }

    func fetchResouce(callback: @escaping ([String: Resouce]) -> Void) {
        print("11 拉取远端服务端资源 \(Thread.current)")
        DispatchQueue.global().async {
            var resouces: [String: Resouce] = [:]
            for _ in 0..<10 {
                resouces["\(self.number.value)"] =
                    Resouce(i18n: "\(self.number.value)", imageKey: "\(self.number.value)")
                self.number.value += 1
            }
            callback(resouces)
        }
    }
}
