//
//  PrecheckBuilder.swift
//  ByteView
//
//  Created by lutingting on 2023/9/4.
//

import Foundation

final class PrecheckBuilder {
    private var checkList: CheckList = CheckList()

    @discardableResult
    func checker(_ checker: MeetingPrecheckable) -> Self {
        checkList.append(checker)
        return self
    }

    func execute(_ context: MeetingPrecheckContext, completion: @escaping (Result<Void, Error>) -> Void) {
        checkList.run(context, completion: completion)
    }
}

private final class CheckList {
    private var header: MeetingPrecheckable?
    private var tailer: MeetingPrecheckable?

    func append(_ checker: MeetingPrecheckable) {
        if header != nil {
            tailer?.nextChecker = checker
            tailer = checker
        } else {
            header = checker
            tailer = checker
        }
    }

    func run(_ context: MeetingPrecheckContext, completion: @escaping PrecheckHandler) {
        if let checker = header {
            checker.check(context, completion: completion)
        } else {
            completion(.success(()))
        }
    }
}
