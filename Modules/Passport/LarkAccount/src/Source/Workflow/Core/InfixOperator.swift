precedencegroup MonadRightArrowPrecedence {
    associativity: left
    higherThan: AssignmentPrecedence
}

precedencegroup MonadTransformPrecedence {
    associativity: left
    higherThan: MonadRightArrowPrecedence
}

precedencegroup MonadParallelPrecedence {
    higherThan: MonadTransformPrecedence
}

infix operator -->: MonadRightArrowPrecedence

infix operator ====: MonadParallelPrecedence

infix operator -<: MonadTransformPrecedence

infix operator >-: MonadTransformPrecedence

// (A, B) -> ParallelMonad<T, U, E>
public typealias ParallelTask<A, B, T, U, E> = (A, B) -> ParallelMonad<T, U, E> where E : Error

// MARK: - -->
func --><T, U, E, S>(taskA: Task<T, U ,E>, taskB: Task<U, S, E>) -> Task<T, S, E> {
    return Task{
        let input: T = $0
        return taskA.runnable($0).then {
            taskA.state = (input, $0)
            return SideEffect(success: $0)
        }.then(transform: { a_value in
            return taskB.runnable(a_value).then{
                taskB.state = (a_value, $0)
                return SideEffect(success: $0)
            }.catch { error in
                if let state = taskA.state {
                    return SideEffect { _, failCallback in
                        taskA.rollback(state).execute { _ in
                            failCallback(error)
                        } failureCallback: { rollbackError in
                            failCallback(rollbackError)
                        }
                    }
                } else {
                    return SideEffect(failure: error)
                }
            }
        })
    } rollback: { _ in
        return SideEffect { succCallback, failCallback in
            if let b_state = taskB.state, let a_state = taskA.state {
                taskB.rollback(b_state).execute { _ in
                    taskA.rollback(a_state).execute(successCallback: succCallback, failureCallback: failCallback)
                } failureCallback: { rollbackError in
                    failCallback(rollbackError)
                }
            } else {
                assert(false)
            }
        }
    }
}

//// MARK: - ====
//
//func ====<A, B, T, U, E>(taskA: (Monad<A, T, E>, Monad<T, A, E>), taskB: (Monad<B, U, E>, Monad<U, B, E>)) -> (ParallelTask<A, B, T, U, E>, ParallelTask<T, U, A, B, E>) {
//    return ({
//        taskA.0($0).zip(sideEffect: taskB.0($1)).map {
//            switch ($0, $1) {
//            case (.success(let success), .failure(_)):
//                taskA.1(success).execute(successCallback:nil) {_ in
//                    // TODO: Rollback Failure Monitor
//                }
//            case (.failure(_), .success(let success)):
//                taskB.1(success).execute(successCallback:nil) {_ in
//                    // TODO: Rollback Failure Monitor
//                }
//            default:
//                break
//            }
//            
//            return ($0, $1)
//        }
//    }, {
//        taskA.1($0).zip(sideEffect: taskB.1($1))
//    })
//}
//
//// MARK: - -<
//func -<<T, A, B, U, E, S>(map: (InputTransform<T, A, B>, ZipTransform<A, B, E, T>), task: (ParallelTask<A, B, U, S, E>, ParallelTask<U, S, A, B, E>)) -> ((T) -> ParallelMonad<U, S, E>, (U, S) -> SideEffect<T, E>) {
//    return ({
//        let mapResult = map.0($0)
//        
//        return task.0(mapResult.0, mapResult.1)
//    }, {
//        task.1($0, $1).combine(transform: map.1)
//    })
//}
//
//// MARK: - >-
//func >-<T, U, E, S, C>(task: ((T) -> ParallelMonad<U, S, E>, (U, S) -> SideEffect<T, E>), map: (ParallelCombine<U, S, E, C>, InputTransform<C, U, S>)) -> (Monad<T, C, E>, Monad<C, T, E>) {
//    return ({
//        var result: (U, S)? = nil
//        
//        return task.0($0).map(transform: {
//            if case .success(let successA) = $0, case .success(let successB) = $1 {
//                result = (successA, successB)
//            }
//            
//            return ($0, $1)
//        }).combine(transform: map.0).catch {
//            if let result = result {
//                task.1(result.0, result.1).execute(successCallback: nil) { _ in
//                    // TODO: Map Failure Monitor
//                }
//            }
//            
//            return SideEffect(failure: $0)
//        }
//    }, {
//        let mapResult = map.1($0)
//        
//        return task.1(mapResult.0, mapResult.1)
//    })
//}
