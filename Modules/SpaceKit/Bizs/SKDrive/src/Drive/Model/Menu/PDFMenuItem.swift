//
//  PDFMenuItem.swift
//  SKDrive
//
//  Created by huayufan on 2023/10/11.
//  


import UIKit
import SKUIKit

class PDFMenuItem: PDFMenuType {
    
    let title: String
    let callback: ((String, String?) -> Void)
    let identifier: String
    
    init(title: String, identifier: String, callback: @escaping ((String, String?) -> Void)) {
        self.title = title
        self.identifier = identifier
        self.callback = callback
    }
}
