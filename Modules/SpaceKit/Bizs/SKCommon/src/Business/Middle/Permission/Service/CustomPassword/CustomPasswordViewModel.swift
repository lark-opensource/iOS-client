//
//  CustomPasswordViewModel.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/11/29.
//

import Foundation
import SKFoundation
import RxSwift
import RxCocoa
import RxRelay
import SpaceInterface
import SKInfra
import SwiftyJSON

protocol PasswordRequirementViewModel: AnyObject {
    var visableDriver: Driver<Bool> { get }
    var stateDriver: Driver<CustomPasswordViewModel.State> { get }
    var message: String { get }
}

extension CustomPasswordViewModel {

    enum ValidationError: Error {
        case invalidPassword
    }

    enum State: Equatable {
        case notify     // 灰色提示
        case pass       // 绿色提示
        case warning    // 橙色提示
    }

    enum Input {
        case reset
        case edit(password: String)
        case commit(password: String)

        var password: String {
            switch self {
            case let .edit(password),
                let .commit(password):
                return password
            case .reset:
                return ""
            }
        }
    }

    class RequirementModel: PasswordRequirementViewModel {

        let requirement: PasswordRequirement
        let stateRelay = BehaviorRelay<State>(value: .notify)

        var state: State { stateRelay.value }
        var visableDriver: Driver<Bool> { .just(true) }
        var stateDriver: Driver<State> { stateRelay.asDriver() }
        var message: String { requirement.message }

        init(requirement: PasswordRequirement) {
            self.requirement = requirement
        }

        func receive(input: Input) {
            stateRelay.accept(process(input: input))
        }

        private func process(input: Input) -> State {
            let pass = requirement.validate(password: input.password)
            switch (state, input) {
            case (.notify, .edit):
                return pass ? .pass : .notify
            case (.pass, .edit):
                return pass ? .pass : .notify
            case (.warning, .edit):
                return pass ? .pass : .warning
            case (_, .commit):
                return pass ? .pass : .warning
            case (_, .reset):
                return .notify
            }
        }
    }

    class ForbiddenModel: PasswordRequirementViewModel {
        let requirement: PasswordRequirement
        let stateRelay = BehaviorRelay<State>(value: .pass)

        var state: State { stateRelay.value }
        var visableDriver: Driver<Bool> { stateRelay.asDriver().map { $0 == .warning } }
        var stateDriver: Driver<State> { stateRelay.asDriver() }
        var message: String { requirement.message }

        init(requirement: PasswordRequirement) {
            self.requirement = requirement
        }

        func receive(input: Input) {
            stateRelay.accept(process(input: input))
        }

        private func process(input: Input) -> State {
            if input.password.isEmpty { return .pass }
            let pass = !requirement.validate(password: input.password)
            return pass ? .pass : .warning
        }
    }

    class LevelModel {
        private let levelRule: PasswordLevelRule
        private let levelRelay = BehaviorRelay<PasswordLevelRule.Level>(value: .unknown)
        var visableDriver: Driver<Bool> { levelRelay.asDriver().map { $0 != .unknown } }
        var levelDriver: Driver<PasswordLevelRule.Level> { levelRelay.asDriver() }

        init(levelRule: PasswordLevelRule) {
            self.levelRule = levelRule
        }

        func receive(input: Input) {
            levelRelay.accept(levelRule.validate(password: input.password))
        }
    }
}

class CustomPasswordViewModel {

    let objToken: String
    let objType: DocsType

    private let requirementModels: [RequirementModel]
    private let forbiddenModels: [ForbiddenModel]
    let levelModel: LevelModel
    private let passRelay = BehaviorRelay<Bool>(value: false)
    private let disposeBag = DisposeBag()

    var passDriver: Driver<Bool> { passRelay.asDriver() }
    var pass: Bool { passRelay.value }
    var showingWarning: Bool {
        requirementModels.contains(where: { $0.state == .warning })
        || forbiddenModels.contains(where: { $0.state == .warning })
    }

    init(objToken: String, objType: DocsType, ruleSet: PasswordRuleSet) {
        self.objToken = objToken
        self.objType = objType
        requirementModels = ruleSet.matchRequirements.map(RequirementModel.init(requirement:))
        forbiddenModels = ruleSet.notMatchRequirements.map(ForbiddenModel.init(requirement:))
        levelModel = LevelModel(levelRule: ruleSet.passwordLevelRule)

        setup()
    }

    func getSubModels() -> [PasswordRequirementViewModel] {
        var subModels = requirementModels as [PasswordRequirementViewModel]
        subModels.append(contentsOf: forbiddenModels as [PasswordRequirementViewModel])
        return subModels
    }

    private func setup() {
        var passObservables: [Observable<Bool>] = []
        passObservables.append(contentsOf: requirementModels.map { model in
            model.stateRelay.map { $0 == .pass }
        })
        passObservables.append(contentsOf: forbiddenModels.map { model in
            model.stateRelay.map { $0 == .pass }
        })
        // 这里用 zip 可以节省一些调用的次数，但是要假设每个 model 在收到 input 一定会发一个事件，否则要用 combineLatest
        Observable.zip(passObservables) { passStates in
            passStates.allSatisfy { $0 }
        }.subscribe { [weak self] allPass in
            self?.passRelay.accept(allPass)
        }
        .disposed(by: disposeBag)
    }

    func edit(password: String) {
        receive(input: .edit(password: password))
    }

    func commit(password: String) {
        receive(input: .commit(password: password))
    }

    func reset() {
        receive(input: .reset)
    }

    func save(password: String) -> Completable {
        guard pass else {
            return .error(ValidationError.invalidPassword)
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionPasswordCommit,
                                        params: [
                                            "token": objToken,
                                            "type": objType.rawValue,
                                            "password": password
                                        ])
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
        return request.rxStart().asCompletable()
    }

    private func receive(input: Input) {
        requirementModels.forEach { $0.receive(input: input) }
        forbiddenModels.forEach { $0.receive(input: input) }
        levelModel.receive(input: input)
    }

    func getRandomPassword() -> Single<String> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionPasswordRandom,
                                        params: nil)
        request.set(method: .GET)
        return request.rxStart().map { json in
            guard let json else {
                DocsLogger.error("json not found when request random password")
                throw DocsNetworkError.invalidData
            }
            guard let password = json["data"]["password"].string,
                  !password.isEmpty else {
                DocsLogger.error("password not found when request random password")
                throw DocsNetworkError.invalidData
            }
            return password
        }
    }
}



