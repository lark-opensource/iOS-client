//
//  LKCheckbox.swift
//  LarkUIKit
//
//  Created by zhenning on 2019/11/18.
//

import Foundation
import UIKit
import SnapKit

public enum LKCheckboxType {
    case list
    case single
    case multiple
    case square
}

public protocol LKCheckboxDelegate: AnyObject {
    func didTapLKCheckbox(_ checkbox: LKCheckbox)
}

extension LKCheckbox {
    public enum Layout {
        public static let iconLargeSize = CGSize(width: 22.0, height: 22.0)
        public static let iconMidSize = CGSize(width: 18.0, height: 18.0)
        public static let iconSmallSize = CGSize(width: 16.0, height: 16.0)
    }
}

/// default is multiple style
open class LKCheckbox: UIControl {
    public private(set) var on: Bool = false
    var iconView: UIImageView = UIImageView()
    private var touchSize: CGSize = Layout.iconMidSize
    private var iconSize: CGSize?
    public weak var delegate: LKCheckboxDelegate?

    public var boxType: LKCheckboxType = .multiple {
        didSet {
            self.refreshIcon()
        }
    }

    public override var isSelected: Bool {
        didSet {
            self.refreshIcon()
        }
    }

    public override var isEnabled: Bool {
        didSet {
            self.refreshIcon()
        }
    }

    public init(boxType: LKCheckboxType, isEnabled: Bool = true, iconSize: CGSize? = nil) {
        super.init(frame: .zero)
        self.iconSize = iconSize
        self.commonInit(boxType: boxType, isEnabled: isEnabled)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    func commonInit(boxType: LKCheckboxType? = nil, isEnabled: Bool = true) {
        self.backgroundColor = UIColor.clear
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapCheckBox)))
        addSubview(iconView)
        iconView.snp.makeConstraints({ make in
            if let iconSize = iconSize {
                make.size.equalTo(iconSize)
                make.centerX.centerY.equalToSuperview()
            } else {
                make.edges.equalToSuperview()
            }
        })
        if let boxType = boxType {
            self.boxType = boxType
        } else {
            refreshIcon()
        }
    }

    @objc
    func handleTapCheckBox(recognizer: UITapGestureRecognizer) {
        self.delegate?.didTapLKCheckbox(self)
        self.sendActions(for: .valueChanged)
    }

    func refreshIcon() {
        var image: UIImage?
        switch self.boxType {
        case .single:
            if self.isEnabled {
                image = self.isSelected ? Resources.checkBox_single_checked : Resources.checkBox_unchecked
            } else {
                image = self.isSelected ? Resources.checkBox_single_disabled_checked : Resources.checkBox_disabled_unchecked
            }
        case .multiple:
            if self.isEnabled {
                image = self.isSelected ? Resources.checkBox_multi_checked : Resources.checkBox_unchecked
            } else {
                image = self.isSelected ? Resources.checkBox_multi_disabled_checked : Resources.checkBox_disabled_unchecked
            }
        case .list:
            if self.isEnabled {
                image = self.isSelected ? Resources.checkBox_list_selected : nil
            } else {
                image = self.isSelected ? Resources.checkBox_list_disabled_unselected : Resources.checkBox_list_disabled_unselected
            }
        case .square:
            if self.isEnabled {
                image = self.isSelected ? Resources.checkBox_square_enable_checked : Resources.checkBox_square_enable_unchecked
            } else {
                image = self.isSelected ? Resources.checkBox_square_enable_checked : Resources.checkBox_square_enable_unchecked
            }
        }
        iconView.image = image
    }

    public static func calculateSize() -> CGSize {
        return Layout.iconMidSize
    }
}
