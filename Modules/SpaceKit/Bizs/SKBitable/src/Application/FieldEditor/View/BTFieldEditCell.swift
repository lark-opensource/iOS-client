//
//  BTOptionTableCell.swift
//  SKBitable
//
//  Created by zoujie on 2021/12/1.
//  


import Foundation
import UIKit
import SKResource
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignIcon
import UniverseDesignToast
import SKUIKit

public protocol BTFieldEditCellDelegate: AnyObject {
    func longPress(_ sender: UILongPressGestureRecognizer, cell: BTFieldEditCell)
    func didChangeValue(id: String, cell: BTFieldEditCell) //处理编辑过程中产生的错误提示的显示并刷新当前cell的高度
}

public class BTFieldEditCell: SKSlideableTableViewCell {

    var editable: Bool = true

    var inpuTextView: BTConditionalTextField?

    var hasError: Bool = false //是否显示错误提示

    var textViewIsEditing: Bool = false //是否正在编辑

    var descriptionStr: String = ""

    var startLocation = CGPoint() //侧滑手势的开始位置，用来计算侧滑距离

    var shouldShowDeleteButton = false //是否需要显示删除按钮，配合滑动手势使用

    var currentDeletedButtonOffset: CGFloat = 0

    var deleteable: Bool = true

    var isNewItem: Bool = false //用来新增item直接进入编辑态

    lazy var container = UIView().construct { it in
        it.backgroundColor = .clear
    }

    lazy var dragWarpperView = UIView().construct { it in
        it.backgroundColor = .clear
    }

    lazy var dragView = UIImageView().construct { it in
        it.isUserInteractionEnabled = true
        it.image = UDIcon.getIconByKey(.menuOutlined, iconColor: UDColor.iconN3, size: CGSize(width: 20, height: 20))
    }

    lazy var leftView = UIView().construct { it in
        it.setContentHuggingPriority(.required, for: .horizontal)
    }

    lazy var textInputWarpperView = UIView().construct { it in
        it.layer.cornerRadius = 6
        it.backgroundColor = .clear
        it.clipsToBounds = false
    }

    lazy var errorLabel = UILabel().construct { it in
        it.textColor = UDColor.functionDangerContentDefault
        it.font = UIFont.systemFont(ofSize: 14)
    }

    lazy var separator = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear

        selectionStyle = .none
        Layout.cornerRadius = 10

        containerView.addSubview(container)
        containerView.backgroundColor = UDColor.bgFloat

        container.snp.makeConstraints { make in
            make.top.bottom.left.right.equalToSuperview()
        }

        container.addSubview(dragWarpperView)
        container.addSubview(leftView)
        container.addSubview(textInputWarpperView)
        container.addSubview(errorLabel)
        container.addSubview(separator)

        dragWarpperView.addSubview(dragView)

        dragView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(textInputWarpperView)
            make.width.height.equalTo(20)
        }

        dragWarpperView.snp.makeConstraints { make in
            make.width.equalTo(48)
            make.right.height.equalToSuperview()
        }

        leftView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(textInputWarpperView.snp.left).offset(-12)
        }

        textInputWarpperView.snp.makeConstraints { make in
            make.left.equalTo(leftView.snp.right).offset(12)
            make.right.equalTo(dragWarpperView.snp.left).offset(-4)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(40)
        }

        errorLabel.snp.makeConstraints { make in
            make.height.equalTo(0)
            make.left.equalTo(textInputWarpperView.snp.left)
            make.bottom.equalToSuperview().offset(-8)
            make.top.equalTo(textInputWarpperView.snp.bottom).offset(2)
        }

        separator.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(0.5)
        }

        let recognizer = UILongPressGestureRecognizer()
        recognizer.addTarget(self, action: #selector(longPress(_:)))
        dragWarpperView.addGestureRecognizer(recognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setUIConfig(deleteable: Bool, editable: Bool) {
        self.editable = editable
        self.deleteable = deleteable
    }

    func showErrorLabel(show: Bool, text: String) {
        errorLabel.text = text
        errorLabel.snp.updateConstraints { make in
            make.height.equalTo(show ? 20 : 0)
        }
    }

    @objc
    func longPress(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            dragView.image = UDIcon.menuOutlined.ud.withTintColor(UDColor.primaryContentDefault)
        case .failed, .cancelled, .ended:
            dragView.image = UDIcon.menuOutlined.ud.withTintColor(UDColor.iconN3)
        default:
            break
        }
    }
}
