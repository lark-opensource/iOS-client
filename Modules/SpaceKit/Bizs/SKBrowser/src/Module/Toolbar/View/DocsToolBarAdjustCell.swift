//
//  DocsToolBarAdjustCell.swift
//  DocsSDK
//
//  Created by Gill on 2020/6/8.
//

import UIKit
import SKCommon
import SKResource
import UniverseDesignColor
import UniverseDesignFont

public protocol FontSizeAdjustViewDelegate: AnyObject {
    func hasUpdateValue(cell: UICollectionViewCell, value: String)
}

public protocol AdjustViewDelegate: AnyObject {
    func updateValue(value: String)
}

class DocsToolBarAdjustCell: UICollectionViewCell, AdjustViewDelegate {
    public weak var adjustViewDelegate: FontSizeAdjustViewDelegate?
    static var suggestedWidth: CGFloat {
        return FontSizeAdjustView.suggestedWidth
    }
    private var adjustView: FontSizeAdjustView = FontSizeAdjustView([])

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(adjustView)
        adjustView.delegate = self
        adjustView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func updateData(_ list: [String], index: Int) {
        adjustView.updateData(list, index: index)
    }

    func updateValue(value: String) {
        adjustViewDelegate?.hasUpdateValue(cell: self, value: value)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
// - 10 +
// 👆 样式如上
class FontSizeAdjustView: UIView {
    public weak var delegate: AdjustViewDelegate?
    static let suggestedWidth: CGFloat = 139
    private(set) var list: [String]
    private(set) var curIndex: Int
    private(set) lazy var subtractButton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.backgroundColor = .clear
        btn.setImage(BundleResources.SKResource.Common.Tool.icon_tool_minus_nor.ud.withTintColor(UDColor.textTitle), for: .normal)
        btn.setImage(BundleResources.SKResource.Common.Tool.icon_tool_minus_nor.ud.withTintColor(UDColor.textDisabled), for: .disabled)
        btn.imageEdgeInsets = UIEdgeInsets(edges: 8)
        btn.layer.cornerRadius = 6
        btn.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        btn.layer.borderWidth = 1
        btn.layer.masksToBounds = true
        btn.addTarget(self, action: #selector(_touchDown(_:)), for: .touchDown)
        btn.addTarget(self, action: #selector(_touchUpInside(_:)), for: .touchUpInside)
        btn.addTarget(self, action: #selector(_touchCancelled(_:)), for: .touchUpOutside)
        btn.addTarget(self, action: #selector(_touchCancelled(_:)), for: .touchCancel)
        return btn
    }()

    private(set) lazy var addButton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.backgroundColor = .clear
        btn.setImage(BundleResources.SKResource.Common.Tool.icon_tool_plus_nor.ud.withTintColor(UDColor.textTitle), for: .normal)
        btn.setImage(BundleResources.SKResource.Common.Tool.icon_tool_plus_nor.ud.withTintColor(UDColor.textDisabled), for: .disabled)
        btn.imageEdgeInsets = UIEdgeInsets(edges: 8)
        btn.layer.cornerRadius = 6
        btn.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        btn.layer.borderWidth = 1
        btn.layer.masksToBounds = true
        btn.addTarget(self, action: #selector(_touchDown(_:)), for: .touchDown)
        btn.addTarget(self, action: #selector(_touchUpInside(_:)), for: .touchUpInside)
        btn.addTarget(self, action: #selector(_touchCancelled(_:)), for: .touchUpOutside)
        btn.addTarget(self, action: #selector(_touchCancelled(_:)), for: .touchCancel)
        return btn
    }()

    private(set) lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    init(_ list: [String], curIndex: Int = 0) {
        self.list = list
        self.curIndex = curIndex
        super.init(frame: .zero)
        _setupView()
        _updateValueLabel()
        subtractButton.docs.addStandardLift()
        addButton.docs.addStandardLift()
    }

    func updateData(_ list: [String], index: Int) {
        self.list = list
        self.curIndex = index
        _updateValueLabel()
        if index == 0 {
            subtractButton.isEnabled = false
            addButton.isEnabled = true

        } else if index == (list.count - 1) {
            subtractButton.isEnabled = true
            addButton.isEnabled = false
        } else {
            subtractButton.isEnabled = true
            addButton.isEnabled = true
        }
    }

    private func _setupView() {
        addSubview(subtractButton)
        addSubview(addButton)
        addSubview(valueLabel)
        let buttonSize: CGFloat = 36
        subtractButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(buttonSize)
            make.left.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
        }
        addButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(buttonSize)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-8)
        }
        valueLabel.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
        }
    }

    private func _updateValueLabel(_ index: Int? = nil) {
        if let idx = index {
            self.curIndex = idx
        }
        if list.count == 0 { return }
        guard list.count > curIndex else {
            assertionFailure("数组越界")
            return
        }
        valueLabel.text = "\(list[curIndex])"
        guard let fontValue = valueLabel.text else { return }
        delegate?.updateValue(value: fontValue)
    }
    
    @objc
    private func _touchDown(_ sender: UIButton) {
        sender.backgroundColor = UDColor.fillPressed
    }
    
    @objc
    private func _touchCancelled(_ sender: UIButton) {
        sender.backgroundColor = .clear
    }

    @objc
    private func _touchUpInside(_ sender: UIButton) {
        sender.backgroundColor = .clear
        if sender === subtractButton {
            _updateIndexIfCan(-1)
        } else if sender === addButton {
            _updateIndexIfCan(1)
        }
        _updateValueLabel()
    }

    private func _updateIndexIfCan(_ update: Int) {
        let willIndex = self.curIndex + update
        if willIndex < 0 {
            self.curIndex = 0
        } else if willIndex >= list.count {
            self.curIndex = list.count - 1
        } else {
            self.curIndex = willIndex
        }
        if willIndex == 0 {
            subtractButton.isEnabled = false
            addButton.isEnabled = true
        } else if willIndex == (list.count - 1) {
            subtractButton.isEnabled = true
            addButton.isEnabled = false
        } else {
            subtractButton.isEnabled = true
            addButton.isEnabled = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
