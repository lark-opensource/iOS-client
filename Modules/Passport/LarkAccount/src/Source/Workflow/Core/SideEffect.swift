internal typealias ResolutionOrRejection<T> = (T) -> Void

internal typealias Executor<Success, Failure> = (@escaping ResolutionOrRejection<Success>, @escaping ResolutionOrRejection<Failure>) -> Void where Failure : Error

// (T) -> <U, E: Error>
internal typealias Monad<T, U, E> = (T) -> SideEffect<U, E> where E : Error

// (T: Error) -> <S, U: Error>
internal typealias MonadErrorHandler<T, U, S> = (T) -> SideEffect<S, U> where T : Error, U : Error

// (<T, E: Error>, <U, E: Error>) -> <S, E: Error>
internal typealias ZipTransform<T, U, E, S> = (Result<T, E>, Result<U, E>) -> Result<S, E> where E : Error

// (T) -> (A, B)
internal typealias InputTransform<T, A, B> = (T) -> (A, B)

internal enum WorkflowError: Error {
    case rollbackError(rawError: Error)
}

internal class Task<T, U, E> where E : Error {

    var state: (T, U)?

    let runnable: Monad<T, U, E>

    let rollback: ((T, U)) -> SideEffect<Void, E>

    init(runnable: @escaping Monad<T, U, E>, rollback: @escaping ((T, U)) -> SideEffect<Void, E>) {
        self.runnable = runnable
        self.rollback = rollback
    }
}

private enum SideEffectState<Success, Failure> where Failure : Error {
    
    case result(Result<Success, Failure>)
    
    case executor(Executor<Success, Failure>)
}

internal struct SideEffect<Success, Failure> where Failure : Error {
    
    private let sideEffectState: SideEffectState<Success, Failure>
    
    internal func execute(successCallback: ((Success) -> Void)?, failureCallback: ((Failure) -> Void)?) {
        switch sideEffectState {
        case .executor(let executor):
            SuiteLoginUtil.runOnMain {
                executor({ args in
                    SuiteLoginUtil.runOnMain {
                        successCallback?(args)
                    }
                }, { error in
                    SuiteLoginUtil.runOnMain {
                        failureCallback?(error)
                    }
                })
            }
        case .result(let result):
            switch result {
            case .success(let success):
                SuiteLoginUtil.runOnMain {
                    successCallback?(success)
                }
            case .failure(let failure):
                SuiteLoginUtil.runOnMain {
                    failureCallback?(failure)
                }
            }
        }
    }
    
    public init(success: Success) {
        sideEffectState = .result(.success(success))
    }
    
    public init(failure: Failure) {
        sideEffectState = .result(.failure(failure))
    }
    
    public init(executor: @escaping Executor<Success, Failure>) {
        sideEffectState = .executor(executor)
    }
    
    public func execute() {
        self.execute { _ in
        } failureCallback: { _ in
        }
    }
    
    public func then<T>(transform: @escaping Monad<Success, T, Failure>) -> SideEffect<T, Failure> {
        switch sideEffectState {
        case .result(let result):
            switch result {
            case .success(let success):
                return transform(success)
            case .failure(let failure):
                return SideEffect<T, Failure>(failure: failure)
            }
        case .executor(let executor):
            return .init { resolution, rejection in
                executor({ args in
                    SuiteLoginUtil.runOnMain {
                        let newPromise = transform(args)
                        newPromise.execute {
                            resolution($0)
                        } failureCallback: {
                            rejection($0)
                        }
                    }
                }, { error in
                    SuiteLoginUtil.runOnMain {
                        rejection(error)
                    }
                })
            }
        }
    }
    
    public func `catch`<T>(transform: @escaping MonadErrorHandler<Failure, T, Success>) -> SideEffect<Success, T> {
        switch sideEffectState {
        case .result(let result):
            switch result {
            case .success(let success):
                return SideEffect<Success, T>(success: success)
            case .failure(let failure):
                return transform(failure)
            }
        case .executor(let executor):
            return .init { resolution, rejection in
                executor({ args in
                    SuiteLoginUtil.runOnMain {
                        resolution(args)
                    }
                }, { error in
                    SuiteLoginUtil.runOnMain {
                        let newPromise = transform(error)
                        newPromise.execute {
                            resolution($0)
                        } failureCallback: {
                            rejection($0)
                        }
                    }
                })
            }
        }
    }
    
    internal func zip<T>(sideEffect: SideEffect<T, Failure>) -> ParallelMonad<Success, T, Failure> {
        if case .result(let result) = sideEffectState, case .result(let sideEffectResult) = sideEffect.sideEffectState {
            return ParallelMonad(resultA: result, resultB: sideEffectResult)
        }
        
        return ParallelMonad { completion in
            var result: Result<Success, Failure>? = nil
            var sideEffectResult: Result<T, Failure>? = nil
            
            let checkCompletion = {
                if let result = result, let sideEffectResult = sideEffectResult {
                    completion(result, sideEffectResult)
                }
            }
            execute {
                result = .success($0)
                checkCompletion()
            } failureCallback: {
                result = .failure($0)
                checkCompletion()
            }
            sideEffect.execute {
                sideEffectResult = .success($0)
                checkCompletion()
            } failureCallback: {
                sideEffectResult = .failure($0)
                checkCompletion()
            }
        }
    }
}

//public func compose<T, U, E, S>(taskA: (Monad<T, U, E>, Monad<U, T, E>), taskB: (Monad<U, S, E>, Monad<S, U, E>)) -> (Monad<T, S, E>, Monad<S, T, E>) {
//    return taskA --> taskB
//}

//internal func parallel<T, U, E, S, A, B, C>(taskA: (Monad<A, U, E>, Monad<U, A, E>), taskB: (Monad<B, S, E>, Monad<S, B, E>), inputTransform: (InputTransform<T, A, B>, ZipTransform<A, B, E, T>), outputTransform: (ZipTransform<U, S, E, C>, InputTransform<C, U, S>)) -> (Monad<T, C, E>, Monad<C, T, E>) {
//    return inputTransform -< taskA ==== taskB >- outputTransform
//}
