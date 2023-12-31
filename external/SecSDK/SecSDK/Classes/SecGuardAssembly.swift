//
//  SecGuardAssembly.swift
//  EETest
//
//  Created by moqianqian on 2020/1/13.
//

import Foundation
import LarkContainer
import Swinject
import AppContainer
import LarkAccountInterface
import LarkAssembler

public class SecGuardAssembly: LarkAssemblyInterface{
  public init () {}

  public func registBootLoader(container: Container) {
    (SecGuardDelegate.self, DelegateLevel.default)
  }
}
