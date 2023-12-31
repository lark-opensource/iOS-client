//
//  NativeRenderInterface.swift
//  LarkWebViewContainer
//
//  Created by tefeng liu on 2020/9/15.
//

import Foundation
import UIKit

/// WebView Service of insert native view for Webview
@objc public protocol LarkWebNativeRenderInterface {
    /// insert native view
    func insertComponent(view: UIView, atIndex index: String, completion: ((Bool) -> Void)? )

    /// remove native view for index
    func removeComponent(index: String) -> Bool

    /// get native view of index
    func component(fromIndex index: String) -> UIView?
}
