//
//  ImageEditColorPanel.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/7/30.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol ImageEditColorPanelDelegate: AnyObject {
    func colorPanel(_ colorPanel: ImageEditColorPanel, didSelect color: ColorPanelType)
}

final class ImageEditColorPanel: UIView {
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
    private let colorButtons: [ImageEditColorPanelButton]
    private let stackView = UIStackView()
    private let disposeBag = DisposeBag()

    weak var delegate: ImageEditColorPanelDelegate?

    init(originColor: ColorPanelType? = nil) {
        currentColor = originColor ?? ColorPanelType.default

        colorButtons = colors.map { ImageEditColorPanelButton(color: $0) }

        super.init(frame: CGRect.zero)

        addSubview(stackView)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.bottom.equalToSuperview()
        }

        colorButtons.forEach { (button) in
            stackView.addArrangedSubview(button)
            button.rx.tap.subscribe(onNext: { [unowned self, unowned button] (_) in
                self.buttonClicked(button: button)
            })
            .disposed(by: disposeBag)
            if button.panelColor == currentColor {
                button.isSelected = true
            }
        }

        snp.makeConstraints { (make) in
            make.height.equalTo(40)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshSettings() {
        delegate?.colorPanel(self, didSelect: currentColor)
    }

    private func buttonClicked(button: ImageEditColorPanelButton) {
        currentColor = button.panelColor
        self.delegate?.colorPanel(self, didSelect: button.panelColor)
    }
}

final class ImageEditColorPanelButton: UIButton {
    let panelColor: ColorPanelType
    private let backgroundView = UIView()
    private let borderView = UIView()
    private let colorView = UIView()

    init(color: ColorPanelType) {
        self.panelColor = color
        super.init(frame: CGRect.zero)
        addSubview(backgroundView)
        backgroundView.isHidden = true
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = 4
        backgroundView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        backgroundView.isUserInteractionEnabled = false
        backgroundView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 19, height: 19))
        }

        addSubview(borderView)
        borderView.layer.masksToBounds = true
        borderView.layer.cornerRadius = 2
        borderView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        borderView.isUserInteractionEnabled = false
        borderView.snp.makeConstraints { (make) in
            make.edges.equalTo(backgroundView).inset(3)
        }

        addSubview(colorView)
        colorView.layer.masksToBounds = true
        colorView.layer.cornerRadius = 1
        colorView.backgroundColor = panelColor.color()
        colorView.isUserInteractionEnabled = false
        colorView.snp.makeConstraints { (make) in
            make.edges.equalTo(borderView).inset(1)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            backgroundView.isHidden = !isSelected
        }
    }
}
