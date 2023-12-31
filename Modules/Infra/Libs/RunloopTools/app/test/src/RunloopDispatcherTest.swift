//
//  RunloopDispatcherTest.swift
//  RunloopToolsDevEEUnitTest
//
//  Created by CharlieSu on 3/19/20.
//

import Foundation
import XCTest
@testable import RunloopTools

class RunloopDispatcherTest: XCTestCase {

    var runloopDispatcher: RunloopDispatcher!

    override func setUp() {
        RunloopDispatcher.enable = true
        runloopDispatcher = RunloopDispatcher(trigger: MockTrigger())
    }

    override func tearDown() {
        runloopDispatcher = nil
    }

    func test_add_task() {
        let expect = expectation(description: "add task")
        runloopDispatcher.addTask {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 0.5)
    }

    func test_can_not_trigger_when_enable_equals_false() {
        RunloopDispatcher.enable = false
        let expect = expectation(description: "add task")
        expect.isInverted = true
        runloopDispatcher.addTask {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 0.5)
    }

    func test_clear_user_scope() {
        let expect = expectation(description: "add task with user scope")
        expect.isInverted = true
        runloopDispatcher.addTask(scope: .user) {
            expect.fulfill()
        }

        let containerExpect = expectation(description: "add task with continer scope")
        runloopDispatcher.addTask(scope: .container) {
            containerExpect.fulfill()
        }
        runloopDispatcher.clearUserScopeTask()
        wait(for: [expect, containerExpect], timeout: 0.5)
    }

    func test_task_priority() {
        let expect = expectation(description: "add task with low priority")
        runloopDispatcher.addTask(priority: .low) {
            expect.fulfill()
        }

        let mediumExpect = expectation(description: "add task with medium priority")
        runloopDispatcher.addTask(priority: .medium) {
            mediumExpect.fulfill()
        }

        let highExpect = expectation(description: "add task with high priority")
        runloopDispatcher.addTask(priority: .high) {
            highExpect.fulfill()
        }

        wait(for: [highExpect, mediumExpect, expect], timeout: 100.0, enforceOrder: true)
    }

    func test_dispatcher_observer() {
        let observer = DispacherResponseable()

        let addTriggerExpect = expectation(description: "add observer")
        let execTaskExpect = expectation(description: "exec task")
        let removeTriggerExpect = expectation(description: "remove observer")

        observer.addTriggerObserver = {
            addTriggerExpect.fulfill()
        }
        observer.removeTriggerObserver = {
            removeTriggerExpect.fulfill()
        }
        runloopDispatcher.addObserver(observer)

        runloopDispatcher.addTask {
            execTaskExpect.fulfill()
        }
        wait(for: [addTriggerExpect, execTaskExpect, removeTriggerExpect],
             timeout: 0.5,
             enforceOrder: true)
    }
}

class MockTrigger: RunloopTrigger {
    var hasSetUp: Bool = false

    override func setup() {
        guard !hasSetUp else { return }
        hasSetUp = true

        perodicFunc()
        self.reciver?.didAddObserver()
    }

    private func perodicFunc() {
        guard self.hasSetUp else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self, self.hasSetUp else { return }
            _ = self.reciver?.willTrigger()
            self.perodicFunc()
        }
    }

    override func clean() {
        guard hasSetUp else { return }
        hasSetUp = false

        self.reciver?.didRemoveObserver()
    }
}

class DispacherResponseable: RunloopDispatcherResponseable {
    var addTriggerObserver: (() -> Void)?
    var removeTriggerObserver: (() -> Void)?

    func didAddTriggerObserver() {
        addTriggerObserver?()
    }

    func didRemoveTriggerObserver() {
        removeTriggerObserver?()
    }
}
