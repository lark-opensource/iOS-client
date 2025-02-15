# Attributes

Attributes should be on their own lines in functions and types, but on the same line as variables and imports.

* **Identifier:** attributes
* **Enabled by default:** Disabled
* **Supports autocorrection:** No
* **Kind:** style
* **Analyzer rule:** No
* **Minimum Swift compiler version:** 3.0.0
* **Default configuration:** warning, always_on_same_line: ["@IBAction", "@NSManaged"], always_on_line_above: []

## Non Triggering Examples

```swift
@objc var x: String
```

```swift
@objc private var x: String
```

```swift
@nonobjc var x: String
```

```swift
@IBOutlet private var label: UILabel
```

```swift
@IBOutlet @objc private var label: UILabel
```

```swift
@NSCopying var name: NSString
```

```swift
@NSManaged var name: String?
```

```swift
@IBInspectable var cornerRadius: CGFloat
```

```swift
@available(iOS 9.0, *)
 let stackView: UIStackView
```

```swift
@NSManaged func addSomeObject(book: SomeObject)
```

```swift
@IBAction func buttonPressed(button: UIButton)
```

```swift
@objc
 @IBAction func buttonPressed(button: UIButton)
```

```swift
@available(iOS 9.0, *)
 func animate(view: UIStackView)
```

```swift
@available(iOS 9.0, *, message="A message")
 func animate(view: UIStackView)
```

```swift
@nonobjc
 final class X
```

```swift
@available(iOS 9.0, *)
 class UIStackView
```

```swift
@NSApplicationMain
 class AppDelegate: NSObject, NSApplicationDelegate
```

```swift
@UIApplicationMain
 class AppDelegate: NSObject, UIApplicationDelegate
```

```swift
@IBDesignable
 class MyCustomView: UIView
```

```swift
@testable import SourceKittenFramework
```

```swift
@objc(foo_x)
 var x: String
```

```swift
@available(iOS 9.0, *)
@objc(abc_stackView)
 let stackView: UIStackView
```

```swift
@objc(abc_addSomeObject:)
 @NSManaged func addSomeObject(book: SomeObject)
```

```swift
@objc(ABCThing)
 @available(iOS 9.0, *)
 class Thing
```

```swift
class Foo: NSObject {
 override var description: String { return "" }
}
```

```swift
class Foo: NSObject {

 override func setUp() {}
}
```

```swift
@objc
class ⽺ {}

```

```swift
extension Property {

 @available(*, unavailable, renamed: "isOptional")
public var optional: Bool { fatalError() }
}
```

```swift
@GKInspectable var maxSpeed: Float
```

```swift
@discardableResult
 func a() -> Int
```

```swift
@objc
 @discardableResult
 func a() -> Int
```

```swift
func increase(f: @autoclosure () -> Int) -> Int
```

```swift
func foo(completionHandler: @escaping () -> Void)
```

```swift
private struct DefaultError: Error {}
```

```swift
@testable import foo

private let bar = 1
```

```swift
import XCTest
@testable import DeleteMe

@available (iOS 11.0, *)
class DeleteMeTests: XCTestCase {
}
```

```swift
@objc
internal func foo(identifier: String, completion: @escaping (() -> Void)) {}
```

```swift
func printBoolOrTrue(_ expression: @autoclosure () throws -> Bool?) rethrows {
  try print(expression() ?? true)
}
```

## Triggering Examples

```swift
@objc
 ↓var x: String
```

```swift
@objc

 ↓var x: String
```

```swift
@objc
 private ↓var x: String
```

```swift
@nonobjc
 ↓var x: String
```

```swift
@IBOutlet
 private ↓var label: UILabel
```

```swift
@IBOutlet

 private ↓var label: UILabel
```

```swift
@NSCopying
 ↓var name: NSString
```

```swift
@NSManaged
 ↓var name: String?
```

```swift
@IBInspectable
 ↓var cornerRadius: CGFloat
```

```swift
@available(iOS 9.0, *) ↓let stackView: UIStackView
```

```swift
@NSManaged
 ↓func addSomeObject(book: SomeObject)
```

```swift
@IBAction
 ↓func buttonPressed(button: UIButton)
```

```swift
@IBAction
 @objc
 ↓func buttonPressed(button: UIButton)
```

```swift
@available(iOS 9.0, *) ↓func animate(view: UIStackView)
```

```swift
@nonobjc final ↓class X
```

```swift
@available(iOS 9.0, *) ↓class UIStackView
```

```swift
@available(iOS 9.0, *)
 @objc ↓class UIStackView
```

```swift
@available(iOS 9.0, *) @objc
 ↓class UIStackView
```

```swift
@available(iOS 9.0, *)

 ↓class UIStackView
```

```swift
@UIApplicationMain ↓class AppDelegate: NSObject, UIApplicationDelegate
```

```swift
@IBDesignable ↓class MyCustomView: UIView
```

```swift
@testable
↓import SourceKittenFramework
```

```swift
@testable


↓import SourceKittenFramework
```

```swift
@objc(foo_x) ↓var x: String
```

```swift
@available(iOS 9.0, *) @objc(abc_stackView)
 ↓let stackView: UIStackView
```

```swift
@objc(abc_addSomeObject:) @NSManaged
 ↓func addSomeObject(book: SomeObject)
```

```swift
@objc(abc_addSomeObject:)
 @NSManaged
 ↓func addSomeObject(book: SomeObject)
```

```swift
@available(iOS 9.0, *)
 @objc(ABCThing) ↓class Thing
```

```swift
@GKInspectable
 ↓var maxSpeed: Float
```

```swift
@discardableResult ↓func a() -> Int
```

```swift
@objc
 @discardableResult ↓func a() -> Int
```

```swift
@objc

 @discardableResult
 ↓func a() -> Int
```