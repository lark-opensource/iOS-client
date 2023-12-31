//
//  ThreadSafeLazy.swift
//  LarkFoundation
//
//  Created by qihongye on 2019/12/23.
//
// https://bytedance.feishu.cn/docs/doccn1eaaG07YUqnMTKrDdjtqWc

import Foundation

/**
 Another way, they have similar performance
 @propertyWrapper
 struct ThreadSafeLazy2<Value> {
     enum State {
         case uninitialized(() -> Value)
         case initialized(Value)
     }

     private var state: State
     private var mutex = pthread_mutex_t()

     public init(value: @autoclosure @escaping () -> Value) {
         state = .uninitialized(value)
         pthread_mutex_init(&mutex, nil)
     }

     public var wrappedValue: Value {
         mutating get {
             switch state {
             case .initialized(let value):
                 return value
             case .uninitialized(let initializer):
                 pthread_mutex_lock(&mutex)
                 defer {
                     pthread_mutex_unlock(&mutex)
                 }
                 if case let .initialized(value) = state {
                     return value
                 }
                 let value = initializer()
                 state = .initialized(value)
                 return value
             }
         }
         set {
             state = .initialized(newValue)
         }
     }
 }
 这里我认为wrapper在state = .initialized(value)时无法保证其他线程不能读。这里可能会有多线程问题
 */

@propertyWrapper
public struct ThreadSafeLazy<Value> {
    enum State {
        case uninitialized(() -> Value)
        case initialized(Value)
    }

    private var state: State
    private var lock = pthread_rwlock_t()
    private var mutex = pthread_mutex_t()

    public init(value: @autoclosure @escaping () -> Value) {
        state = .uninitialized(value)
        pthread_mutex_init(&mutex, nil)
        pthread_rwlock_init(&lock, nil)
    }

    public init(value: @escaping () -> Value) {
        state = .uninitialized(value)
        pthread_mutex_init(&mutex, nil)
        pthread_rwlock_init(&lock, nil)
    }

    public var wrappedValue: Value {
        mutating get {
            pthread_rwlock_tryrdlock(&lock)
            switch state {
            case .initialized(let value):
                pthread_rwlock_unlock(&lock)
                return value
            case .uninitialized(let initializer):
                pthread_mutex_lock(&mutex)
                pthread_rwlock_unlock(&lock)
                defer {
                    pthread_mutex_unlock(&mutex)
                }
                if case let .initialized(value) = state {
                    return value
                }
                pthread_rwlock_trywrlock(&lock)
                let value = initializer()
                state = .initialized(value)
                pthread_rwlock_unlock(&lock)
                return value
            }
        }
        set {
            state = .initialized(newValue)
        }
    }
}
