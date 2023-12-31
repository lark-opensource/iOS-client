//
//  Models.swift
//  LarkContainerDemoTests
//
//  Created by SuPeng on 8/24/19.
//  Copyright © 2019 SuPeng. All rights reserved.
//

import Foundation
import LarkContainer

class Bar {
    static var allocNumber: Int = 0
    let name: String
    init(_ name: String = "") {
        Self.allocNumber += 1
        self.name = name
    }

    func doSomething(arg: Int) -> String {
        return self.name
    }
}

class Foo {
    @Injected var bar: Bar
    @Injected(\Bar.name) var name: String
    @Injected(Bar.doSomething) var doSomething: (Int) -> String
}

class NameFoo {
    @Injected("Name1") var bar1: Bar
    @Injected("Name2") var bar2: Bar
}

class ArgumentFoo {
    @Injected(argument: "arg1") var bar1: Bar
    @Injected(arguments: "arg1", "arg2") var bar2: Bar
}

class LazyFoo {
    @InjectedLazy var bar1: Bar
    @InjectedLazy(Injected(argument: "arg1")) var bar2: Bar
}
class SafeLazyFoo {
    @InjectedSafeLazy var bar1: Bar
    @InjectedSafeLazy(Injected(argument: "arg1")) var bar2: Bar
}

class ProviderFoo {
    @Provider var bar1: Bar
    @Provider(Injected(argument: "arg1")) var bar2: Bar
}

class FooOptional {
    @Injected var bar: Bar

    // 初始化的时候，直接从容器中取出一个可空的类型
    @InjectedOptional var bar1: Bar?
    @InjectedOptional var bar2: NonExistInContainerType?

    // 调用的时候，从容器中取出一个可空的类型
    @InjectedLazy(InjectedOptional()) var bar3: Bar?
    @InjectedLazy(InjectedOptional()) var bar4: NonExistInContainerType?

    @Provider(InjectedOptional()) var bar5: Bar?
    @Provider(InjectedOptional()) var bar6: NonExistInContainerType?
}

struct NonExistInContainerType {

}
