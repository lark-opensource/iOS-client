//
//  DemoAvatarListViewController.swift
//  TangramUIComponentDev
//
//  Created by 袁平 on 2021/7/16.
//

import Foundation
import UIKit
import TangramUIComponent
import TangramComponent

class DemoAvatarListViewController: BaseDemoViewController {
    lazy var avatarListProps: AvatarListComponentProps = {
        let props = AvatarListComponentProps()
        props.restCount = 19999
        props.setAvatarTasks.setTask { completion in
            let task1: UserAvatarListView.SetAvatarTask = { view in
                view.image = .random()
            }
            let task2: UserAvatarListView.SetAvatarTask = { view in
                view.image = .random()
            }
            let task3: UserAvatarListView.SetAvatarTask = { view in
                view.image = .random()
            }
            completion([task1, task2, task3], nil)
        }
        return props
    }()

    lazy var avatarList: AvatarListComponent<EmptyContext> = {
        let avatarList = AvatarListComponent<EmptyContext>(props: avatarListProps)
        return avatarList
    }()

    lazy var restText: UITextField = {
        let tagText = UITextField()
        tagText.layer.borderWidth = 1
        tagText.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        tagText.placeholder = "Rest Count"
        return tagText
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTool()
    }

    override func setupView() {
        super.setupView()
        rootLayout.setChildren([avatarList])
        render.update(rootComponent: root)
        render.render()
    }

    func setupTool() {
        view.addSubview(restText)
        restText.snp.makeConstraints { make in
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
            make.top.equalTo(restText.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(44)
        }
    }

    @objc
    func update() {
        if let text = restText.text, !text.isEmpty, let restCount = Int(text) {
            avatarListProps.restCount = restCount
        }
        avatarList.props = avatarListProps
        render.update(rootComponent: root)
        render.render()
    }
}
