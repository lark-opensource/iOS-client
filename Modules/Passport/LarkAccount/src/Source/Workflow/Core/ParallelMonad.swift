internal typealias ParallelResultTuple<T, U, E> = (Result<T, E>, Result<U, E>) where E : Error

internal typealias ParallelCompletion<T, U, E> = (Result<T, E>, Result<U, E>) -> Void where E : Error

internal typealias ParallelExecutor<T, U, E> = (@escaping ParallelCompletion<T, U, E>) -> Void where E : Error

public typealias ParallelCombine<T, U, E, S> = (Result<T, E>, Result<U, E>) -> Result<S, E> where E : Error

private enum ParallelState<T, U, E> where E : Error {
    case result(ParallelResultTuple<T, U, E>)
    case executor(ParallelExecutor<T, U, E>)
}

public struct ParallelMonad<T, U, E> where E : Error {
    
    private let parallelState: ParallelState<T, U, E>
    
    internal init(resultA: Result<T, E>, resultB: Result<U, E>) {
        parallelState = .result((resultA, resultB))
    }
    
    internal init(executor: @escaping ParallelExecutor<T, U, E>) {
        parallelState = .executor(executor)
    }
    
    internal func map<A, B>(transform: @escaping (Result<T, E>, Result<U, E>) -> ParallelResultTuple<A, B, E>) -> ParallelMonad<A, B, E> {
        switch parallelState {
        case .result(let parallelResultTuple):
            let newParallelResultTuple = transform(parallelResultTuple.0, parallelResultTuple.1)
            
            return ParallelMonad<A, B, E>(resultA: newParallelResultTuple.0, resultB: newParallelResultTuple.1)
        case .executor(let parallelExecutor):
            return ParallelMonad<A, B, E> { completion in
                parallelExecutor {
                    let newParallelResultType = transform($0, $1)
                    completion(newParallelResultType.0, newParallelResultType.1)
                }
            }
        }
    }
    
    internal func combine<S>(transform: @escaping ParallelCombine<T, U, E, S>) -> SideEffect<S, E> {
        switch parallelState {
        case .result(let parallelResult):
            let finalResult = transform(parallelResult.0, parallelResult.1)
            switch (finalResult) {
            case .success(let success):
                return SideEffect(success: success)
            case .failure(let failure):
                return SideEffect(failure: failure)
            }
        case .executor(let executor):
            return SideEffect { resolution, rejection in
                executor {
                    let finalResult = transform($0, $1)
                    switch (finalResult) {
                    case .success(let success):
                        return resolution(success)
                    case .failure(let failure):
                        return rejection(failure)
                    }
                }
            }
        }
    }
}
