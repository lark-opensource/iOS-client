//
//  Tools.swift
//  LarkInteractionDev
//
//  Created by Saafo on 2021/10/13.
//

import Foundation
import UIKit

@dynamicMemberLookup
struct Chainable<Subject> {
    private let subject: Subject

    func unwrap() -> Subject {
        return subject
    }

    init(_ subject: Subject) {
        self.subject = subject
    }

    subscript<Value>(dynamicMember keyPath: WritableKeyPath<Subject, Value>) -> ((Value) -> Chainable<Subject>) {

        var subject = self.subject

        return { value in
            subject[keyPath: keyPath] = value
            return Chainable(subject)
        }
    }
}
