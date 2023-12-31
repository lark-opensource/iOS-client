//
//  ImageEditorOperator.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/10/11.
//

import Foundation
import TTVideoEditor

class ImageEditorOperator {
    let imageEditor: VEImage
    weak var delegate: ImageEditorOperatorDelegate?

    init(with imageEditor: VEImage) { self.imageEditor = imageEditor }
}
