//
//  DemoVC.swift
//  LarkFontAssemblyDev
//
//  Created by 白镜吾 on 2023/4/19.
//

import UIKit

class DemoVC: UIViewController {

    lazy var fontLabel = UILabel()

    lazy var boldButton = UIButton()
    lazy var SButton = UIButton()
    lazy var ItalicButton = UIButton()
    lazy var UButton = UIButton()

    lazy var isBold = false
    lazy var isItalic = false
    lazy var selectS = false
    lazy var selectU = false

    lazy var stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase
        self.view.addSubview(fontLabel)
        fontLabel.snp.makeConstraints { make in
            make.width.equalTo(300)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-50)
        }
        fontLabel.font = UIFont.ud.systemFont(ofSize: 36).regular
        fontLabel.text = "123 hhh"

        self.view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaInsets).offset(-50)
        }

        boldButton.setTitle("B", for: .normal)
        SButton.setTitle("S", for: .normal)
        ItalicButton.setTitle("I", for: .normal)
        UButton.setTitle("U", for: .normal)

        boldButton.setTitleColor(.black, for: .normal)
        SButton.setTitleColor(.black, for: .normal)
        ItalicButton.setTitleColor(.black, for: .normal)
        UButton.setTitleColor(.black, for: .normal)

        stackView.addArrangedSubview(boldButton)
        stackView.addArrangedSubview(SButton)
        stackView.addArrangedSubview(ItalicButton)
//        stackView.addArrangedSubview(UButton)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually

        boldButton.addTarget(self, action: #selector(clickB), for: .touchUpInside)
        SButton.addTarget(self, action: #selector(clickS), for: .touchUpInside)
        ItalicButton.addTarget(self, action: #selector(clickI), for: .touchUpInside)
//        UButton.addTarget(self, action: #selector(clickU), for: .touchUpInside)

        let b = UIFont.systemFont(ofSize: 36).medium
        b.isItalic = true
        let c = b

        print("")
    }

    @objc
    func clickB() {
        guard let font = fontLabel.font else { return }
        let baseFont = font.withoutTraits(.traitBold, .traitItalic)
        if isBold {
            // remove
            if font.isBold {
                // 这里使用baseFont处理 而不是使用 font，因为汉字的font的英文的font的不一样，加粗之后会出现字体变小的情况
                if font.isItalic {
                    fontLabel.font = baseFont.italic
                } else {
                    fontLabel.font = baseFont
                }
            }
        } else {
            // add
            if !font.isBold {
                // 这里使用baseFont处理 而不是使用 font，因为汉字的font的英文的font的不一样，加粗之后会出现字体变小的情况
                if font.isItalic {
                    fontLabel.font = baseFont.boldItalic
                } else {
                    fontLabel.font = baseFont.medium
                }
            }
        }

        isBold = !isBold
        if isBold {
            boldButton.setTitleColor(.green, for: .normal)
        } else {
            boldButton.setTitleColor(.black, for: .normal)
        }
    }

    @objc
    func clickI() {
        guard let font = fontLabel.font else { return }
        let baseFont = font.withoutTraits([.traitBold, .traitItalic])
        if isItalic {
            // remove
            if font.isItalic {
                // 这里使用baseFont处理 而不是使用 font，因为汉字的font的英文的font的不一样，加粗之后会出现字体变小的情况
                if font.isBold {
                    fontLabel.font = baseFont.medium
                } else {
                    fontLabel.font = baseFont.removeItalic()
                }
            } else {

            }
        } else {
            // add
            if !font.isItalic {
                // 这里使用baseFont处理 而不是使用 font，因为汉字的font的英文的font的不一样，加粗之后会出现字体变小的情况
                if font.isBold {
                    fontLabel.font = baseFont.boldItalic
                } else {
                    fontLabel.font = baseFont.italic
                }
            }
        }
        isItalic = !isItalic

        if isItalic {
            ItalicButton.setTitleColor(.green, for: .normal)
        } else {
            ItalicButton.setTitleColor(.black, for: .normal)
        }
    }

    @objc
    func clickS() {
        guard let font = fontLabel.font else { return }
        fontLabel.font = font.withoutTraits(.traitBold, .traitItalic)
    }

}
