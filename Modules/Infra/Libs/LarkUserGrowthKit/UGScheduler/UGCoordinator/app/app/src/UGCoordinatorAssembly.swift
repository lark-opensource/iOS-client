//
//  UGCoordinatorAssembly.swift
//  UGCoodinator
//
//  Created by zhenning on 2021/1/21.
//
import Foundation
import Swinject
import UGCoordinator

public class UGCoordinatorAssembly: Assembly {
    public init() { }

    private lazy var subAssemlies: [Assembly] = {
        []
    }()

    public func assemble(container: Container) {
        subAssemlies.forEach({
            $0.assemble(container: container)
        })
        assembleService(container: container)
    }

    private func assembleService(container: Container) {
        container.register(UGCoordinatorDependency.self) { _ -> UGCoordinatorDependency in
            return UGCoordinatorMockDependency()
        }
    }
}
