import Foundation
import UIKit
import RxSwift
import LarkDebugExtensionPoint


// swiftlint:disable identifier_name

var PassportDebugCellItemRegistries: [SectionType: [PassportDebugItemProvider]] = [:]

typealias PassportDebugItemProvider = () -> DebugCellItem

enum PassportDebugRegistry {
    /// Register a debug cell item. DebugViewController will create a cell with the item and shows on its tableview.
    ///  - NOTE: Items will be created each time a DebugViewController is showed, and will be dealloced when DebugViewController is dismissed.
    /// - Parameters:
    ///   - item: Debug cell item, which defines one debug function.
    ///   - section: The debug section where the debug item will be showed.
    static func registerDebugItem(_ item: @escaping @autoclosure PassportDebugItemProvider, to section: SectionType) {
        DispatchQueue.main.async {
            var cellItems = PassportDebugCellItemRegistries[section] ?? []
            cellItems.append(item)
            PassportDebugCellItemRegistries[section] = cellItems
        }
    }
}

