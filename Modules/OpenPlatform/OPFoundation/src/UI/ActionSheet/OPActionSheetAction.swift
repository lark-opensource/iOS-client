//
//  EMAActionSheetAction.swift
//  OPFoundation
//
//  Created by baojianjun on 2023/4/23.
//

import Foundation

@objc
public final class EMAActionSheetAction: NSObject {
    public typealias ActionSheetHandler = os_block_t
    
    public let title: String
    
    public let handler: ActionSheetHandler?
    
    public let style: UIAlertAction.Style
    
    public init(title: String, style: UIAlertAction.Style, handler: ActionSheetHandler?) {
        self.title = title
        self.style = style
        self.handler = handler
        super.init()
    }
    
    @objc public class func action(title: String, style: UIAlertAction.Style, handler: ActionSheetHandler?) -> EMAActionSheetAction {
        return EMAActionSheetAction(title: title, style: style, handler: handler)
    }
    
    private override init() {
        self.title = ""
        self.style = .default
        self.handler = nil
        super.init()
    }
}
