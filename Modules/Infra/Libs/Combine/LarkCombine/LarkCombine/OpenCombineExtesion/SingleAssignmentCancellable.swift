//
//  SingleAssignmentCancellable.swift
//  LarkCombine
//
//  Created by 王元洵 on 2020/12/20.
//

import Foundation
import OpenCombine

/**
Represents a Cancellable resource which only allows a single assignment of its underlying Cancellable resource.

If an underlying Cancellable resource has already been set, future attempts to set the underlying Cancellable resource will throw an exception.
*/
public final class SingleAssignmentCancellable : Cancellable {

    private enum CancelState: Int32 {
        case cancelled = 1
        case cancellableSet = 2
    }

    // state
    private let _state = AtomicInt(0)
    private var _Cancellable = nil as Cancellable?

    /// - returns: A value that indicates whether the object is disposed.
    public var isCancelled: Bool {
        return isFlagSet(self._state, CancelState.cancelled.rawValue)
    }

    /// Initializes a new instance of the `SingleAssignmentCancellable`.
    public init() {
    }

    /// Gets or sets the underlying Cancellable. After disposal, the result of getting this property is undefined.
    ///
    /// **Throws exception if the `SingleAssignmentCancellable` has already been assigned to.**
    public func setCancellable(_ Cancellable: Cancellable) {
        self._Cancellable = Cancellable

        let previousState = fetchOr(self._state, CancelState.cancellableSet.rawValue)

        if (previousState & CancelState.cancellableSet.rawValue) != 0 {
            fatalError("oldState.Cancellable != nil")
        }

        if (previousState & CancelState.cancelled.rawValue) != 0 {
            Cancellable.cancel()
            self._Cancellable = nil
        }
    }

    /// Disposes the underlying Cancellable.
    public func cancel() {
        let previousState = fetchOr(self._state, CancelState.cancelled.rawValue)

        if (previousState & CancelState.cancelled.rawValue) != 0 {
            return
        }

        if (previousState & CancelState.cancellableSet.rawValue) != 0 {
            guard let Cancellable = self._Cancellable else {
                fatalError("Cancellable not set")
            }
            Cancellable.cancel()
            self._Cancellable = nil
        }
    }

}
