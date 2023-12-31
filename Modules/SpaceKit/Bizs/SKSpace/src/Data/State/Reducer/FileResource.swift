//
//  MainStore.swift
//  FileResource
//
//  Created by weidong fu on 22/1/2018.
//

import Foundation
import ReSwift
import SKFoundation
import SKCommon

final class SpaceStore: Store<ResourceState> {

    override func dispatch(_ action: Action) {
        if DispatchQueue.isDataQueue {
            super.dispatch(action)
        } else {
            DispatchQueue.dataQueueAsyn {
                super.dispatch(action)
            }
        }
    }

    public func dispatch(_ action: Action, callback: ((ResourceState) -> Void)?) {
        if DispatchQueue.isDataQueue {
            super.dispatch(action)
            callback?(self.state)
        } else {
            DispatchQueue.dataQueueAsyn {
                super.dispatch(action)
                callback?(self.state)
            }
        }
    }
}

private let singletonStore = SpaceStore(reducer: FileResource.fileResourceReducer,
                                state: ResourceState(),
                                middleware: [loggerMiddleware])
public final class FileResource {
    private(set) var mainStore: SpaceStore

    public init() {
        self.mainStore = singletonStore
    }

    public func dispatch(_ action: Action, callback: ((ResourceState) -> Void)?) {
        self.mainStore.dispatch(action, callback: callback)
    }

    public func subscribe<S: StoreSubscriber>(_ subscriber: S) where S.StoreSubscriberStateType == ResourceState {
        DispatchQueue.dataQueueAsyn {
            self.mainStore.subscribe(subscriber)
        }
    }

    public func subscribe<SelectedState, S: StoreSubscriber>(
        _ subscriber: S, transform: ((Subscription<ResourceState>) -> Subscription<SelectedState>)?
    ) where S.StoreSubscriberStateType == SelectedState {
        DispatchQueue.dataQueueAsyn {
            self.mainStore.subscribe(subscriber, transform: transform)
        }
    }

    public func unsubscribe(_ subscriber: AnyStoreSubscriber) {
        DispatchQueue.dataQueueAsyn {
            self.mainStore.unsubscribe(subscriber)
        }
    }

}
