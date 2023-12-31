//
//  MailThreadListMultiSelectView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2022/6/20.
//

import Foundation
import UIKit

class MailThreadListMultiSelectView: UIView {

    var isSelected: Bool = false {
        didSet {
            updateIcon()
        }
    }
    
    var isAttachmentSelectIcon: Bool = false {
        didSet {
            updateIconFrame()
        }
    }
    
    private var iconView = UIImageView()

    init() {
        super.init(frame: .zero)
        addSubview(iconView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateIconFrame()
        updateIcon()
    }

    func updateIcon() {
        iconView.image = isSelected ? Resources.mail_cell_option_selected : Resources.mail_cell_option
        if isSelected {
            iconView.backgroundColor = UIColor.ud.primaryContentDefault
            iconView.layer.cornerRadius = 10
            iconView.clipsToBounds = true
        } else {
            iconView.backgroundColor = UIColor.clear
            iconView.layer.cornerRadius = 0
            iconView.clipsToBounds = false
        }
    }
    func updateIconFrame() {
        if isAttachmentSelectIcon {
            iconView.frame = CGRect(x: 18, y: 24, width: 20, height: 20)
        } else {
            iconView.frame = CGRect(x: 18, y: 14, width: 20, height: 20)
        }
    }
}
