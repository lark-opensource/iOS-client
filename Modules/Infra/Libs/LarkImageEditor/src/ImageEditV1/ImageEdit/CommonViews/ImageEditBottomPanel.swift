//
//  ImageEditBottomPanel.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/7/30.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkUIKit

protocol ImageEditBottomPanelDelegate: AnyObject {
    func bottomPanel(_ bottomPanel: ImageEditBottomPanel, didSelect function: BottomPanelFunction)
    func bottomPanelDidClickRevert(_ bottomPanel: ImageEditBottomPanel)
    func bottomPanelDidClickFinish(_ bottomPanel: ImageEditBottomPanel)
}

enum BottomPanelFunction {
    case line // 线
    case text // 文本
    case mosaic // 马赛克
    case trim // 裁剪

    var image: (normal: UIImage, highlight: UIImage) {
        switch self {
        case .line:
            return (Resources.edit_line, Resources.edit_line_highlight)
        case .text:
            return (Resources.edit_text, Resources.edit_text_highlight)
        case .mosaic:
            return (Resources.edit_mosaic, Resources.edit_mosaic_highlight)
        case .trim:
            return (Resources.edit_trim, Resources.edit_trim_highlight)
        }
    }

    static var `default`: BottomPanelFunction {
        return .line
    }
}

final class ImageEditBottomPanel: UIView {
    weak var delegate: ImageEditBottomPanelDelegate?

    private let revertButton = UIButton()
    private let stackView = UIStackView()
    private var finishButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.ud.colorfulBlue
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.setTitle(BundleI18n.LarkImageEditor.Lark_Legacy_Finish, for: .normal)
        button.setTitle(BundleI18n.LarkImageEditor.Lark_Legacy_Finish, for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.white, for: .selected)
        return button
    }()
    private let disposeBag = DisposeBag()
    var currentWidth: CGFloat = UIApplication.shared.keyWindow?.bounds.width ?? UIScreen.main.bounds.width

    var isRevertButtonEnable: Bool = true {
        didSet {
            revertButton.isEnabled = isRevertButtonEnable
        }
    }

    init() {
        super.init(frame: CGRect.zero)

        revertButton.setImage(Resources.edit_revert, for: .normal)
        revertButton.setImage(Resources.edit_revert_highlight, for: .highlighted)
        revertButton.addTarget(self, action: #selector(revertButtonDidClick), for: .touchUpInside)
        addSubview(revertButton)
        revertButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(26)
            make.centerX.equalTo(28)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }

        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = currentWidth < 375 ? 18 : 26
        addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.centerY.equalTo(26)
            make.centerX.equalToSuperview()
        }

        let functions: [BottomPanelFunction] = [.line, .mosaic, .trim, .text]
        functions.forEach { (function) in
            let button = ImageEditBottomPanelButton(function: function)
            button.rx.tap.subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                if !button.isSelected {
                    self.delegate?.bottomPanel(self, didSelect: function)
                }
            })
            .disposed(by: disposeBag)

            stackView.addArrangedSubview(button)
        }

        finishButton.addTarget(self, action: #selector(finishButtonDidClick), for: .touchUpInside)
        addSubview(finishButton)
        finishButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(26)
            make.right.equalTo(-16)
            make.size.equalTo(CGSize(width: 60, height: 28))
        }

        backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.9)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var currentFunction: BottomPanelFunction = BottomPanelFunction.default {
        didSet {
            stackView.arrangedSubviews.forEach { (view) in
                guard let functionButton = view as? ImageEditBottomPanelButton else { return }
                functionButton.isSelected = (functionButton.function == currentFunction)
            }
        }
    }

    @objc
    private func revertButtonDidClick() {
        delegate?.bottomPanelDidClickRevert(self)
    }

    @objc
    private func finishButtonDidClick() {
        delegate?.bottomPanelDidClickFinish(self)
    }

    override func layoutSubviews() {
        if currentWidth != self.bounds.width {
            currentWidth = self.bounds.width
            stackView.spacing = currentWidth < 375 ? 18 : 26
        }
        super.layoutSubviews()
    }
}

private final class ImageEditBottomPanelButton: UIButton {
    let function: BottomPanelFunction
    init(function: BottomPanelFunction) {
        self.function = function
        super.init(frame: CGRect.zero)
        setImage(function.image.normal, for: .normal)
        setImage(function.image.highlight, for: .highlighted)
        imageView?.contentMode = .scaleAspectFit
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                setImage(function.image.highlight, for: .normal)
            } else {
                setImage(function.image.normal, for: .normal)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
