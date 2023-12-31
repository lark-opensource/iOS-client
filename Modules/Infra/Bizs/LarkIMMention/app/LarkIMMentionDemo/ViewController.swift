//
//  ViewController.swift
//  LarkIMMentionDemo
//
//  Created by Yuri on 2022/12/6.
//

import Foundation
import UIKit
import UniverseDesignLoading
@testable import LarkIMMention

class ViewController: UIViewController {
    
    let textField = UITextField(frame: CGRect(x: 100, y: 100, width: 300, height: 60))

    override func viewDidLoad() {
        super.viewDidLoad()
        textField.borderStyle = .roundedRect
        textField.keyboardType = .webSearch
        view.addSubview(textField)
//        textField.isSkeletonable = true
//        textField.showUDSkeleton()
//        textField.hideUDSkeleton()
        
        let cell = IMMentionItemCell(frame: CGRect(x: 0, y: 0, width: 320, height: 60))
        var item = IMPickerOption(id: UUID().uuidString)
        item.name = NSAttributedString(string: "name")
        view.addSubview(cell)
        cell.frame = CGRect(x: 20, y: 200, width: 300, height: 66)
        cell.node = MentionItemNode(item: item, isSkeleton: true)
//        cell.node = MentionItemNode(item: item, isSkeleton: false)
//        cell.setDeleteBtn()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let endDoc = textField.endOfDocument
        let text = textField.text ?? ""
        let start = textField.position(from: endDoc, offset: -text.count)!
        let end = textField.position(from: endDoc, offset: 0)!
        textField.selectedTextRange = nil// textField.textRange(from: start, to: end)
    }

}

