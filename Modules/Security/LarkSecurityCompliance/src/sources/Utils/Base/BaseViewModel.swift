//
//  BaseViewModel.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/21.
//

import Foundation
import RxSwift
import RxCocoa

public protocol ViewModel {
    var coordinator: ViewModelCoordinator? { get }

    var viewDidLoad: PublishSubject<Void> { get }
    var viewWillAppear: PublishSubject<Void> { get }
    var viewDidAppear: PublishSubject<Void> { get }
    var viewWillDisappear: PublishSubject<Void> { get }
    var viewDidDisappear: PublishSubject<Void> { get }

    func setupCoordinator(_ coordinator: ViewModelCoordinator)
}

open class BaseViewModel: ViewModel {

    open var coordinator: ViewModelCoordinator? { _coordinator }

    public let viewDidLoad = PublishSubject<Void>()
    public let viewWillAppear = PublishSubject<Void>()
    public let viewDidAppear = PublishSubject<Void>()
    public let viewWillDisappear = PublishSubject<Void>()
    public let viewDidDisappear = PublishSubject<Void>()

    private var _coordinator: ViewModelCoordinator?

    public func setupCoordinator(_ coordinator: ViewModelCoordinator) {
        _coordinator = coordinator
    }

    public init() {

    }
}
