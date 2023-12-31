import Foundation
extension Publisher {

    /// Collects elements by a given strategy, and emits a single array of the collection.
    ///
    /// If the upstream publisher finishes before filling the buffer, this publisher sends an array of all the items it has received. This may be fewer than `count` elements.
    /// If the upstream publisher fails with an error, this publisher forwards the error to the downstream receiver instead of sending its output.
    /// Note: When this publisher receives a request for `.max(n)` elements, it requests `.max(count * n)` from the upstream publisher.
    /// - Parameters:
    ///   - strategy: The strategy with which to collect and publish elements.
    ///   - options: `Scheduler` options to use for the strategy.
    /// - Returns: A publisher that collects elements by a given strategy, and emits a single array of the collection.
    public func collect<S: Scheduler>(_ strategy: Publishers.TimeGroupingStrategy<S>, options: S.SchedulerOptions? = nil) -> Publishers.CollectByTime<Self, S> {
        return .init(upstream: self, strategy: strategy, options: options)
    }
}

extension Publishers {

    /// A strategy for collecting received elements.
    ///
    /// - byTime: Collect and periodically publish items.
    /// - byTimeOrCount: Collect and publish items, either periodically or when a buffer reaches its maximum size.
    public enum TimeGroupingStrategy<Context> where Context: Scheduler {

        case byTime(Context, Context.SchedulerTimeType.Stride)

        case byTimeOrCount(Context, Context.SchedulerTimeType.Stride, Int)
    }

    /// A publisher that buffers and periodically publishes its items.
    public struct CollectByTime<Upstream: Publisher, Context: Scheduler>: Publisher {

        public typealias Output = [Upstream.Output]

        public typealias Failure = Upstream.Failure

        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream

        /// The strategy with which to collect and publish elements.
        public let strategy: Publishers.TimeGroupingStrategy<Context>

        /// `Scheduler` options to use for the strategy.
        public let options: Context.SchedulerOptions?

        public init(upstream: Upstream, strategy: Publishers.TimeGroupingStrategy<Context>, options: Context.SchedulerOptions?) {
            self.upstream = upstream
            self.strategy = strategy
            self.options = options
        }

        public func receive<S: Subscriber>(subscriber: S) where Upstream.Failure == S.Failure, S.Input == [Upstream.Output] {
            switch self.strategy {
            case .byTime:
                let s = ByTime(pub: self, sub: subscriber)
                self.upstream.subscribe(s)
            case .byTimeOrCount:
                let s = ByTimeOrCount(pub: self, sub: subscriber)
                self.upstream.subscribe(s)
            }
        }
    }
}

// MARK: - ByTimeOrCount
extension Publishers.CollectByTime {

    private final class ByTimeOrCount<S>: Subscription,
        Subscriber,
        CustomStringConvertible,
        CustomDebugStringConvertible
    where
        S: Subscriber,
        S.Input == Output,
        S.Failure == Failure {

        typealias Input = Upstream.Output
        typealias Failure = Upstream.Failure

        typealias Pub = Publishers.CollectByTime<Upstream, Context>
        typealias Sub = S

        let lock = UnfairRecursiveLock.allocate()
        let strategy: Publishers.TimeGroupingStrategy<Context>
        let sub: Sub

        let context: Context
        let time: Context.SchedulerTimeType.Stride
        let count: Int

        var state = SubscriptionStatus.awaitingSubscription
        var buffer: [Input] = []
        var timeoutTask: Cancellable?

        init(pub: Pub, sub: Sub) {
            self.strategy = pub.strategy
            self.sub = sub

            guard case .byTimeOrCount(let context, let time, let count) = pub.strategy else {
                fatalError("something is wrong here")
            }
            self.context = context
            self.time = time
            self.count = count
            self.rescheduleTimeoutTask()
        }

        deinit {
            lock.deallocate()
        }

        func rescheduleTimeoutTask() {
            self.lock.lock()
            self.timeoutTask?.cancel()
            self.timeoutTask = self.context.schedule(
                after: self.context.now.advanced(by: self.time),
                interval: self.time) {
                self.lock.lock()
                guard case .subscribed = self.state else {
                    self.lock.unlock()
                    return
                }

                let buffer = self.buffer
                self.buffer.removeAll(keepingCapacity: true)
                self.lock.unlock()

                self.rescheduleTimeoutTask()

                if buffer.isEmpty {
                    return
                }

                _ = self.sub.receive(buffer)
            }
            self.lock.unlock()
        }

        func request(_ demand: Subscribers.Demand) {
            self.lock.lock()
            self.state.subscription?.request(demand * self.count)
            self.lock.unlock()
        }

        func cancel() {
            self.lock.lock()
            guard case .subscribed = state else {
                self.lock.unlock()
                return
            }

            state = .terminal
            self.lock.unlock()
        }

        func receive(subscription: Subscription) {
            self.lock.lock()
            guard state.isAwaitingSubscription else {
                subscription.cancel()
                return
            }
            state = .subscribed(subscription)
            self.lock.unlock()
            self.sub.receive(subscription: self)
        }

        func receive(_ input: Input) -> Subscribers.Demand {
            self.lock.lock()
            guard case .subscribed = state else {
                self.lock.unlock()
                return .none
            }

            self.buffer.append(input)

            guard self.buffer.count == self.count else {
                self.lock.unlock()
                return .none
            }

            let output = self.buffer
            self.buffer.removeAll(keepingCapacity: true)
            self.lock.unlock()
            self.rescheduleTimeoutTask()
            self.context.schedule {
                let newDemand = self.sub.receive(output)
                if newDemand > 0 {
                    self.request(newDemand)
                }
            }
            return .none
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            self.lock.lock()
            
            guard let subscription = state.subscription else {
                self.lock.unlock()
                return
            }

            let task = self.timeoutTask
            self.timeoutTask = nil
            state = .terminal
            self.lock.unlock()

            subscription.cancel()
            task?.cancel()

            var output: [Input]?
            if case .finished = completion, !self.buffer.isEmpty {
                output = self.buffer
            }
            self.buffer = []

            self.context.schedule {
                if let output = output {
                    _ = self.sub.receive(output)
                }
                self.sub.receive(completion: completion)
            }
        }

        var description: String {
            return "CollectByTime"
        }

        var debugDescription: String {
            return "CollectByTime"
        }
    }
}

// MARK: - ByTime
extension Publishers.CollectByTime {

    private final class ByTime<S>: Subscription,
        Subscriber,
        CustomStringConvertible,
        CustomDebugStringConvertible
    where
        S: Subscriber,
        S.Input == Output,
        S.Failure == Failure {

        typealias Input = Upstream.Output
        typealias Failure = Upstream.Failure

        typealias Pub = Publishers.CollectByTime<Upstream, Context>
        typealias Sub = S

        let lock = UnfairRecursiveLock.allocate()
        let sub: Sub

        let context: Context
        let time: Context.SchedulerTimeType.Stride

        var state = SubscriptionStatus.awaitingSubscription
        var demand: Subscribers.Demand = .none
        var buffer: [Input] = []
        var timeoutTask: Cancellable?

        init(pub: Pub, sub: Sub) {
            self.sub = sub

            guard case .byTime(let context, let time) = pub.strategy else {
                fatalError("something is wrong here")
            }
            self.context = context
            self.time = time

            self.rescheduleTimeoutTask()
        }

        deinit {
            lock.deallocate()
        }

        func rescheduleTimeoutTask() {
            self.lock.lock()
            self.timeoutTask?.cancel()
            self.timeoutTask = self.context.schedule(
                after: self.context.now.advanced(by: self.time),
                interval: self.time) {
                self.lock.lock()
                guard case .subscribed = self.state else {
                    self.lock.unlock()
                    return
                }

                defer {
                    self.rescheduleTimeoutTask()
                }

                guard self.demand > 0 else {
                    self.lock.unlock()
                    return
                }

                let buffer = self.buffer
                self.buffer.removeAll(keepingCapacity: true)

                if buffer.isEmpty {
                    self.lock.unlock()
                    return
                }
                self.demand -= 1
                self.lock.unlock()

                let more = self.sub.receive(buffer)

                if more > 0 {
                    self.lock.lock()
                        self.demand += more
                    self.lock.unlock()
                }
            }
            self.lock.unlock()
        }

        func request(_ demand: Subscribers.Demand) {
            self.lock.lock()
            guard let subscription = self.state.subscription else {
                self.lock.unlock()
                return
            }
            self.demand += demand
            self.lock.unlock()

            subscription.request(.max(1))
        }

        func cancel() {
            self.lock.lock()
            guard case .subscribed = state else {
                self.lock.unlock()
                return
            }

            state = .terminal
            self.lock.unlock()
        }

        func receive(subscription: Subscription) {
            self.lock.lock()
            guard state.isAwaitingSubscription else {
                subscription.cancel()
                return
            }
            state = .subscribed(subscription)
            self.lock.unlock()
            self.sub.receive(subscription: self)
        }

        func receive(_ input: Input) -> Subscribers.Demand {
            self.lock.lock()
            guard case .subscribed = self.state else {
                self.lock.unlock()
                return .none
            }

            self.buffer.append(input)
            self.lock.unlock()

            return .max(1)
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            self.lock.lock()
            guard let subscription = state.subscription else {
                self.lock.unlock()
                return
            }

            let task = self.timeoutTask
            self.timeoutTask = nil
            self.lock.unlock()

            subscription.cancel()
            task?.cancel()

            var output: [Input]?
            if case .finished = completion, !self.buffer.isEmpty {
                output = self.buffer
            }
            self.buffer = []

            self.context.schedule {
                if let output = output {
                    _ = self.sub.receive(output)
                }
                self.sub.receive(completion: completion)
            }
        }

        var description: String {
            return "CollectByTime"
        }

        var debugDescription: String {
            return "CollectByTime"
        }
    }
}
