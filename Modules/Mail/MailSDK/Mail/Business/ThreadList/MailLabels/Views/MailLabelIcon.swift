//
//  MailLabelIcon.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/12/14.
//

import Foundation
import SnapKit
import UniverseDesignIcon

class MailLabelIcon: UIView {
    enum State {
        case normal
        case selected
    }

    let fillImageView = UIImageView()
    let borderImageView = UIImageView()
    var state: State = .normal {
        didSet {
            refreshUI()
        }
    }

    var borderColor: UIColor = .blue {
        didSet {
            refreshUI()
        }
    }

    var fillColor: UIColor = .clear {
        didSet {
            refreshUI()
        }
    }

    init() {
        super.init(frame: CGRect.zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.addSubview(fillImageView)
        self.addSubview(borderImageView)

        refreshUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.fillImageView.frame = self.bounds
        self.borderImageView.frame = self.bounds
    }

    private func refreshUI() {
        if state == .selected {
            borderImageView.image = nil
            borderImageView.image = UDIcon.labelChangeOutlined.withRenderingMode(.alwaysTemplate)
        } else {
            borderImageView.image = nil
            borderImageView.image = UDIcon.labelChangeOutlined.withRenderingMode(.alwaysTemplate)
        }
        fillImageView.image = nil

        borderImageView.tintColor = borderColor
        fillImageView.tintColor = fillColor
        fillImageView.isHidden = fillColor == .clear
    }
}
