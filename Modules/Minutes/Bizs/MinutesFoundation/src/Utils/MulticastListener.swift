//
//  MulticastListener.swift
//  MinutesFoudation
//
//  Created by panzaofeng on 28/12/15.
//  Copyright © 2022 panzaofeng. All rights reserved.
//

import Foundation

/**
 *  `MulticastListener` lets you easily create a "multicast listener" for a given protocol or class.
 */
public class MulticastListener<T> {
    ///lock
    private let lock = RwLock()
    
    /// The listeners hash table.
    private let listeners: NSHashTable<AnyObject>
    
    /**
     *  Use the property to check if no listeners are contained there.
     *
     *  - returns: `true` if there are no listeners at all, `false` if there is at least one.
     */
    public var isEmpty: Bool {
        var count: Int = 0
        lock.withRead {
            count = listeners.allObjects.count
        }
        return count == 0
    }
    
    /**
     *  Use this method to initialize a new `MulticastListener` specifying whether listener references should be weak or
     *  strong.
     *
     *  - parameter strongReferences: Whether listeners should be strongly referenced, false by default.
     *
     *  - returns: A new `MulticastListener` instance
     */
    public init(strongReferences: Bool = false) {
        
        listeners = strongReferences ? NSHashTable<AnyObject>() : NSHashTable<AnyObject>.weakObjects()
    }
    
    /**
     *  Use this method to initialize a new `MulticastListener` specifying the storage options yourself.
     *
     *  - parameter options: The underlying storage options to use
     *
     *  - returns: A new `MulticastListener` instance
     */
    public init(options: NSPointerFunctions.Options) {
        
        listeners = NSHashTable<AnyObject>(options: options, capacity: 0)
    }
    
    /**
     *  Use this method to add a listener.
     *
     *  Alternatively, you can use the `+=` operator to add a listener.
     *
     *  - parameter listener:  The listener to be added.
     */
    public func addListener(_ listener: T) {
        lock.withWrite {
            listeners.add(listener as AnyObject)
        }
    }
    
    /**
     *  Use this method to remove a previously-added listener.
     *
     *  Alternatively, you can use the `-=` operator to add a listener.
     *
     *  - parameter listener:  The listener to be removed.
     */
    public func removeListener(_ listener: T) {
        lock.withWrite {
            listeners.remove(listener as AnyObject)
        }
    }
    
    /**
     *  Use this method to invoke a closure on each listener.
     *
     *  Alternatively, you can use the `|>` operator to invoke a given closure on each listener.
     *
     *  - parameter invocation: The closure to be invoked on each listener.
     */
    public func invokeListeners(_ invocation: (T) -> ()) {
        lock.withRead {
            for listener in listeners.allObjects {
                if let listener = listener as? T {
                    invocation(listener)
                }
            }
        }
    }
}

/**
 *  Use this operator to add a listener.
 *
 *  This is a convenience operator for calling `addListener`.
 *
 *  - parameter left:   The multicast listener
 *  - parameter right:  The listener to be added
 */
public func +=<T>(left: MulticastListener<T>, right: T) {
    
    left.addListener(right)
}

/**
 *  Use this operator to remove a listener.
 *
 *  This is a convenience operator for calling `removeListener`.
 *
 *  - parameter left:   The multicast listener
 *  - parameter right:  The listener to be removed
 */
public func -=<T>(left: MulticastListener<T>, right: T) {
    
    left.removeListener(right)
}

/**
 *  Use this operator invoke a closure on each listener.
 *
 *  This is a convenience operator for calling `invokeListeners`.
 *
 *  - parameter left:   The multicast listener
 *  - parameter right:  The closure to be invoked on each listener
 *
 *  - returns: The `MulticastListener` after all its listeners have been invoked
 */
precedencegroup MulticastPrecedence {
    associativity: left
    higherThan: TernaryPrecedence
}
infix operator |> : MulticastPrecedence
public func |><T>(left: MulticastListener<T>, right: (T) -> ()) {
    
    left.invokeListeners(right)
}

