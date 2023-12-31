//
//  CheckBox.swift
//  ByteView
//
//  Created by fakegourmet on 2020/8/17.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit

protocol CheckboxDelegate: AnyObject {
    func didTapCheckbox(_ checkbox: Checkbox)
}

final class Checkbox: UIControl {
    private(set) var on: Bool = false
    var iconView: UIImageView = UIImageView()
    private var iconSize: CGSize?
    weak var delegate: CheckboxDelegate?

    override var isSelected: Bool {
        didSet {
            self.refreshIcon()
        }
    }

    init(iconSize: CGSize? = nil) {
        super.init(frame: .zero)
        self.iconSize = iconSize
        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    func commonInit() {
        self.backgroundColor = UIColor.clear
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapCheckBox)))
        addSubview(iconView)
        iconView.snp.makeConstraints({ make in
            if let iconSize = iconSize {
                make.size.equalTo(iconSize)
            }
            make.edges.equalToSuperview()
        })
        refreshIcon()
    }

    @objc
    func handleTapCheckBox(recognizer: UITapGestureRecognizer) {
        self.isSelected = !self.isSelected
        self.delegate?.didTapCheckbox(self)
        self.sendActions(for: .valueChanged)
    }

    func refreshIcon() {
        let image = self.isSelected ? BundleResources.Cert.CheckBoxSelected : BundleResources.Cert.CheckBoxUnselected
        iconView.image = image
    }

    var hitTestEdgeInsets: UIEdgeInsets = .zero

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if self.hitTestEdgeInsets == .zero || !self.isEnabled || self.isHidden {
            return super.point(inside: point, with: event)
        }

        let relativeFrame = self.bounds
        let hitFrame = relativeFrame.inset(by: self.hitTestEdgeInsets)
        return hitFrame.contains(point)
    }
}
