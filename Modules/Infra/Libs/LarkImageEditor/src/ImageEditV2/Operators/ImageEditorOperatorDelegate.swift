//
//  ImageEditorOperatorDelegate.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/10/9.
//

import UIKit
import Foundation

protocol ImageEditorOperatorDelegate: AnyObject {
    var currentImageScale: CGFloat { get }
    var currentImageInitialScale: CGFloat { get }

    func setRenderFlag()
}
