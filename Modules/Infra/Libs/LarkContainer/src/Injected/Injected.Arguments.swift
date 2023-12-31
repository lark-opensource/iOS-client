//
//  Injected.swift
//  LarkContainer
//
//  Created by SuPeng on 8/24/19.
//

//
// NOTICE:
//
// Injected.Arguments.swift is generated from Container.Arguments.erb by ERB.
// Do NOT modify Injected.Arguments.swift directly.
// Instead, modify Injected.Arguments.erb and run `script/gencode` at the project root directory to generate the code.
//

import Swinject
import Foundation

// MARK: - Injected constructor with keyPath
public extension Injected {

  /// Retrieves the instance of type Value, 1 argument to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - argument:   1 argument to pass to the factory closure.
  ///
  init<Arg1>(
     name: String? = nil,
     argument: Arg1)
  {
     wrappedValue = Container.shared.resolve(Value.self, name: name, argument: argument)!
  }

  /// Retrieves the instance of type Value, 1 argument to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - keyPath:     The keyPath value of the instance of Root
  ///   - argument:   1 argument to pass to the factory closure.
  ///
  init<Root, Arg1>(
     name: String? = nil,
     keyPath: Swift.KeyPath<Root, Value>,
     argument: Arg1)
  {
     wrappedValue = Container.shared.resolve(Root.self, name: name, argument: argument)![keyPath: keyPath]
  }

  /// Retrieves the instance of type Value, list of 2 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - arguments:   List of 2 arguments to pass to the factory closure.
  ///
  init<Arg1, Arg2>(
     name: String? = nil,
     arguments arg1: Arg1, _ arg2: Arg2)
  {
     wrappedValue = Container.shared.resolve(Value.self, name: name, arguments: arg1, arg2)!
  }

  /// Retrieves the instance of type Value, list of 2 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - keyPath:     The keyPath value of the instance of Root
  ///   - arguments:   List of 2 arguments to pass to the factory closure.
  ///
  init<Root, Arg1, Arg2>(
     name: String? = nil,
     keyPath: Swift.KeyPath<Root, Value>,
     arguments arg1: Arg1, _ arg2: Arg2)
  {
     wrappedValue = Container.shared.resolve(Root.self, name: name, arguments: arg1, arg2)![keyPath: keyPath]
  }

  /// Retrieves the instance of type Value, list of 3 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - arguments:   List of 3 arguments to pass to the factory closure.
  ///
  init<Arg1, Arg2, Arg3>(
     name: String? = nil,
     arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3)
  {
     wrappedValue = Container.shared.resolve(Value.self, name: name, arguments: arg1, arg2, arg3)!
  }

  /// Retrieves the instance of type Value, list of 3 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - keyPath:     The keyPath value of the instance of Root
  ///   - arguments:   List of 3 arguments to pass to the factory closure.
  ///
  init<Root, Arg1, Arg2, Arg3>(
     name: String? = nil,
     keyPath: Swift.KeyPath<Root, Value>,
     arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3)
  {
     wrappedValue = Container.shared.resolve(Root.self, name: name, arguments: arg1, arg2, arg3)![keyPath: keyPath]
  }

  /// Retrieves the instance of type Value, list of 4 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - arguments:   List of 4 arguments to pass to the factory closure.
  ///
  init<Arg1, Arg2, Arg3, Arg4>(
     name: String? = nil,
     arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4)
  {
     wrappedValue = Container.shared.resolve(Value.self, name: name, arguments: arg1, arg2, arg3, arg4)!
  }

  /// Retrieves the instance of type Value, list of 4 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - keyPath:     The keyPath value of the instance of Root
  ///   - arguments:   List of 4 arguments to pass to the factory closure.
  ///
  init<Root, Arg1, Arg2, Arg3, Arg4>(
     name: String? = nil,
     keyPath: Swift.KeyPath<Root, Value>,
     arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4)
  {
     wrappedValue = Container.shared.resolve(Root.self, name: name, arguments: arg1, arg2, arg3, arg4)![keyPath: keyPath]
  }

  /// Retrieves the instance of type Value, list of 5 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - arguments:   List of 5 arguments to pass to the factory closure.
  ///
  init<Arg1, Arg2, Arg3, Arg4, Arg5>(
     name: String? = nil,
     arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5)
  {
     wrappedValue = Container.shared.resolve(Value.self, name: name, arguments: arg1, arg2, arg3, arg4, arg5)!
  }

  /// Retrieves the instance of type Value, list of 5 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - keyPath:     The keyPath value of the instance of Root
  ///   - arguments:   List of 5 arguments to pass to the factory closure.
  ///
  init<Root, Arg1, Arg2, Arg3, Arg4, Arg5>(
     name: String? = nil,
     keyPath: Swift.KeyPath<Root, Value>,
     arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5)
  {
     wrappedValue = Container.shared.resolve(Root.self, name: name, arguments: arg1, arg2, arg3, arg4, arg5)![keyPath: keyPath]
  }

  /// Retrieves the instance of type Value, list of 6 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - arguments:   List of 6 arguments to pass to the factory closure.
  ///
  init<Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(
     name: String? = nil,
     arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6)
  {
     wrappedValue = Container.shared.resolve(Value.self, name: name, arguments: arg1, arg2, arg3, arg4, arg5, arg6)!
  }

  /// Retrieves the instance of type Value, list of 6 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - keyPath:     The keyPath value of the instance of Root
  ///   - arguments:   List of 6 arguments to pass to the factory closure.
  ///
  init<Root, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(
     name: String? = nil,
     keyPath: Swift.KeyPath<Root, Value>,
     arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6)
  {
     wrappedValue = Container.shared.resolve(Root.self, name: name, arguments: arg1, arg2, arg3, arg4, arg5, arg6)![keyPath: keyPath]
  }

  /// Retrieves the instance of type Value, list of 7 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - arguments:   List of 7 arguments to pass to the factory closure.
  ///
  init<Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7>(
     name: String? = nil,
     arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7)
  {
     wrappedValue = Container.shared.resolve(Value.self, name: name, arguments: arg1, arg2, arg3, arg4, arg5, arg6, arg7)!
  }

  /// Retrieves the instance of type Value, list of 7 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - keyPath:     The keyPath value of the instance of Root
  ///   - arguments:   List of 7 arguments to pass to the factory closure.
  ///
  init<Root, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7>(
     name: String? = nil,
     keyPath: Swift.KeyPath<Root, Value>,
     arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7)
  {
     wrappedValue = Container.shared.resolve(Root.self, name: name, arguments: arg1, arg2, arg3, arg4, arg5, arg6, arg7)![keyPath: keyPath]
  }

  /// Retrieves the instance of type Value, list of 8 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - arguments:   List of 8 arguments to pass to the factory closure.
  ///
  init<Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8>(
     name: String? = nil,
     arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7, _ arg8: Arg8)
  {
     wrappedValue = Container.shared.resolve(Value.self, name: name, arguments: arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)!
  }

  /// Retrieves the instance of type Value, list of 8 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - keyPath:     The keyPath value of the instance of Root
  ///   - arguments:   List of 8 arguments to pass to the factory closure.
  ///
  init<Root, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8>(
     name: String? = nil,
     keyPath: Swift.KeyPath<Root, Value>,
     arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7, _ arg8: Arg8)
  {
     wrappedValue = Container.shared.resolve(Root.self, name: name, arguments: arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)![keyPath: keyPath]
  }

  /// Retrieves the instance of type Value, list of 9 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - arguments:   List of 9 arguments to pass to the factory closure.
  ///
  init<Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9>(
     name: String? = nil,
     arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7, _ arg8: Arg8, _ arg9: Arg9)
  {
     wrappedValue = Container.shared.resolve(Value.self, name: name, arguments: arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)!
  }

  /// Retrieves the instance of type Value, list of 9 arguments to the factory closure and registration name.
  ///
  /// - Parameters:
  ///   - name:        The registration name.
  ///   - keyPath:     The keyPath value of the instance of Root
  ///   - arguments:   List of 9 arguments to pass to the factory closure.
  ///
  init<Root, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9>(
     name: String? = nil,
     keyPath: Swift.KeyPath<Root, Value>,
     arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7, _ arg8: Arg8, _ arg9: Arg9)
  {
     wrappedValue = Container.shared.resolve(Root.self, name: name, arguments: arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)![keyPath: keyPath]
  }

}
