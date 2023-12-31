//
//  ImageEditColorStack.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/7/1.
//

import Foundation
import UIKit

protocol ImageEditColorStackDelegate: AnyObject {
    func didSelectColor(_ color: ColorPanelType)
}

final class ImageEditColorStack: UIView {
    var currentColor: ColorPanelType {
        didSet {
            colorButtons.forEach { (colorButton) in
                if colorButton.panelColor == currentColor {
                    colorButton.isSelected = true
                } else {
                    colorButton.isSelected = false
                }
            }
        }
    }

    private let colors: [ColorPanelType] = [.red, .white, .black, .green, .orange, .blue, .pink]
    private let colorButtons: [ImageEditColorStackButton]
    private let stackView = UIStackView()

    var minimumWidth: CGFloat {
        return 30 * CGFloat(colors.count)
    }

    weak var delegate: ImageEditColorStackDelegate?

    init(originColor: ColorPanelType? = nil) {
        currentColor = originColor ?? ColorPanelType.default

        colorButtons = colors.map { ImageEditColorStackButton(color: $0) }

        super.init(frame: CGRect.zero)

        addSubview(stackView)
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        colorButtons.forEach { (button) in
            stackView.addArrangedSubview(button)
            button.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
            if button.panelColor == currentColor {
                button.isSelected = true
            }
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func refreshSettings() {
        delegate?.didSelectColor(currentColor)
    }

    @objc
    private func buttonClicked(button: ImageEditColorStackButton) {
        currentColor = button.panelColor
        self.delegate?.didSelectColor(button.panelColor)
    }
}

fileprivate extension ImageEditColorStack {
    final class ImageEditColorStackButton: UIButton {
        let panelColor: ColorPanelType
        private let borderView = UIView()
        private let colorView = UIView()

        init(color: ColorPanelType) {
            self.panelColor = color
            super.init(frame: CGRect.zero)

            addSubview(borderView)
            borderView.layer.masksToBounds = true
            borderView.layer.cornerRadius = 4
            borderView.backgroundColor = .clear
            borderView.isUserInteractionEnabled = false
            borderView.layer.ud.setBorderColor(.ud.colorfulBlue)
            borderView.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.size.equalTo(26)
            }

            addSubview(colorView)
            colorView.layer.masksToBounds = true
            colorView.layer.cornerRadius = 2
            colorView.backgroundColor = panelColor.color()
            colorView.isUserInteractionEnabled = false
            colorView.snp.makeConstraints { (make) in
                make.edges.equalTo(borderView).inset(3)
            }

            switch color {
            case .white, .black:
                colorView.layer.borderWidth = 0.5
                colorView.layer.ud.setBorderColor(.ud.lineBorderComponent)
            default:
                break
            }
        }

        required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override var isSelected: Bool {
            didSet {
                if isSelected {
                    borderView.layer.borderWidth = 2
                } else {
                    borderView.layer.borderWidth = 0
                }
            }
        }
    }
}
