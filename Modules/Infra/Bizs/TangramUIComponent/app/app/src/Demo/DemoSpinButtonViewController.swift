//
//  DemoSpinButtonViewController.swift
//  TangramUIComponentDev
//
//  Created by 袁平 on 2021/7/15.
//

import Foundation
import UIKit
import TangramUIComponent
import TangramComponent

class DemoSpinButtonViewController: BaseDemoViewController {
    lazy var spinButtonProps: SpinButtonComponentProps = {
        let props = SpinButtonComponentProps()
        props.title = "Spin Button"
        props.setImage.update { view in
            view.image = Resources.arrow
        }
        props.onTap.update { _ in }
        return props
    }()

    lazy var spinButton: SpinButtonComponent<EmptyContext> = {
        let spinButton = SpinButtonComponent<EmptyContext>(props: spinButtonProps)
        return spinButton
    }()

    lazy var buttonTitle: UITextField = {
        let buttonTitle = UITextField()
        buttonTitle.layer.borderWidth = 1
        buttonTitle.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        buttonTitle.placeholder = "Button Title"
        return buttonTitle
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTool()
    }

    override func setupView() {
        super.setupView()
        rootLayout.setChildren([spinButton])
        render.update(rootComponent: root)
        render.render()
    }

    func setupTool() {
        view.addSubview(buttonTitle)
        buttonTitle.snp.makeConstraints { make in
            make.top.equalTo(wrapper.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(44)
        }

        let updateButton = UIButton()
        updateButton.setTitle("Update", for: .normal)
        updateButton.setTitleColor(UIColor.ud.N900, for: .normal)
        updateButton.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        updateButton.layer.borderWidth = 1
        updateButton.addTarget(self, action: #selector(update), for: .touchUpInside)
        view.addSubview(updateButton)
        updateButton.snp.makeConstraints { make in
            make.top.equalTo(buttonTitle.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(44)
        }
    }

    @objc
    func update() {
        if let title = buttonTitle.text, !title.isEmpty {
            spinButtonProps.title = title
        }
        spinButton.props = spinButtonProps
        render.update(component: spinButton) {
            self.render.render()
        }
    }
}
