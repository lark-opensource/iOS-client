//
//  MentionDebugItemCell.swift
//  LarkMention-Core-Debug-Model-Resources-Util-View
//
//  Created by Yuri on 2022/6/14.
//

import Foundation
#if !LARK_NO_DEBUG
import UIKit

final class MentionDebugItemCell: UITableViewCell, UITextFieldDelegate {
    
    final class Section: CustomStringConvertible {
        var title: String
        var items: [Item]
        
        init(title: String, items: [Item]) {
            self.title = title
            self.items = items
        }
        
        var description: String {
            return "\(title) - \n\(items)"
        }
        
    }
    
    final class Item: CustomStringConvertible {
        enum ItemType {
        case sw
            case textField
        }
        var title: String?
        var type: ItemType = .sw
        var isOpen: Bool = false
        var content: String?
        
        init(title: String, isOpen: Bool = false, type: ItemType = .sw) {
            self.title = title
            self.isOpen = isOpen
            self.type = type
        }
        
        var description: String {
            return "\(title) \(isOpen) \(content)\n"
        }
    }
    
    var item: Item? {
        didSet {
            setupUI()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupUI() {
        guard let item = item else { return }
        textLabel?.text = item.title
        switch item.type {
        case .sw:
            let sw = UISwitch()
            sw.addTarget(self, action: #selector(onSwitch(sw:)), for: .valueChanged)
            sw.isOn = item.isOpen
            self.accessoryView = sw
        case .textField:
            let textField = UITextField()
            textField.delegate = self
            textField.text = item.content
            textField.borderStyle = .roundedRect
            textField.bounds = CGRect(x: 0, y: 0, width: 180, height: 40)
            accessoryView = textField
        }
    }
    
    @objc private func onSwitch(sw: UISwitch) {
        item?.isOpen = sw.isOn
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var text = (textField.text ?? "") + string
        if range.length > 0 && string.utf16.isEmpty {
            text = String(text.dropLast())
        }
        item?.content = text
        return true
    }
    
    @objc func injected() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        setupUI()
        let i = self.item
        self.item = i
    }
}
#endif
