//
//  UniverseDesignMenu.swift
//  UDCCatalog
//
//  Created by qsc on 2020/10/26.
//  Copyright © 2020 ByteDance. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignMenu
import UniverseDesignToast

class UniverseDesignMenuVC: UIViewController {
    private lazy var menu: UDMenu = UDMenu(actions: actions1)
    private lazy var style = UDMenuStyleConfig.defaultConfig()

    private lazy var button1: UIButton = createBtn(bgColor: UIColor.ud.B200, title: "菜单1", panSelector: #selector(pan1))
    private lazy var button2: UIButton = createBtn(bgColor: UIColor.ud.B300, title: "菜单2", panSelector: #selector(pan2))
    private lazy var button3: UIButton = createBtn(bgColor: UIColor.ud.B400, title: "菜单3", panSelector: #selector(pan3))
    private lazy var button4: UIButton = createBtn(bgColor: UIColor.ud.colorfulBlue, title: "菜单4", panSelector: #selector(pan4))
    private lazy var button5: UIButton = createBtn(bgColor: UIColor.ud.B600, title: "菜单5", panSelector: #selector(pan5))
    private lazy var button6: UIButton = createBtn(bgColor: UIColor.ud.B600, title: "更改badge显示", panSelector: #selector(pan6))
    private lazy var label: UILabel = UILabel()
    private lazy var slider: UISlider = {
        let slider = UISlider()
        slider.maximumValue = 390
        slider.minimumValue = 30
        slider.setValue(390, animated: false)
        return slider
    }()

    private lazy var actions1:[UDMenuAction] = []
    private lazy var actions2:[UDMenuAction] = []
    private lazy var actions3:[UDMenuAction] = []
    private lazy var actions4:[UDMenuAction] = []
    private lazy var actions5:[UDMenuAction] = []
    // 最小尺寸 正常
    private lazy var action11 = UDMenuAction(title: "最小", icon: UDIcon.scanOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 富文本", on: self.view, delay: 3)
    })
    // 最小尺寸 禁用
    private lazy var action12 = UDMenuAction(title: "禁用", icon: UDIcon.groupOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 禁用", on: self.view, delay: 3)
    })
    // 最小尺寸 副标题 一行
    private lazy var action13 = UDMenuAction(title: "标题", icon: UDIcon.teamAddOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 一行副标题", on: self.view, delay: 3)
    })
    // 最小尺寸 副标题 禁用
    private lazy var action14 = UDMenuAction(title: "标题", icon: UDIcon.addChatOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 禁用副标题", on: self.view, delay: 3)
    })
    // 最小尺寸 副标题 截断
    private lazy var action15 = UDMenuAction(title: "标题", icon: UDIcon.calloutOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 有截断的副标题", on: self.view, delay: 3)
    })

    // 最大尺寸 正常
    private lazy var action21 = UDMenuAction(title: "至高至强至宽至大至任至善的选项", icon: UDIcon.scanOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 至高至强至宽至大至任至善的选项", on: self.view, delay: 3)
    })
    // 最大尺寸 禁用
    private lazy var action22 = UDMenuAction(title: "至高至强至宽至大至任至善的选项被禁用", icon: UDIcon.groupOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 至高至强至宽至大至任至善的选项禁用", on: self.view, delay: 3)
    })
    // 最大尺寸 副标题 一行
    private lazy var action23 = UDMenuAction(title: "一行副标题", icon: UDIcon.teamAddOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 一行副标题", on: self.view, delay: 3)
    })

    private lazy var action24 = UDMenuAction(title: "副标题被禁用", icon: UDIcon.addChatOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 副标题被禁用", on: self.view, delay: 3)
    })

    private lazy var action25 = UDMenuAction(title: "副标题被截断", icon: UDIcon.calloutOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 有截断的副标题", on: self.view, delay: 3)
    })
    private lazy var action31 = UDMenuAction(title: "扫一扫", icon: UDIcon.scanOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 扫一扫", on: self.view, delay: 3)
    })

    private lazy var action32 = UDMenuAction(title: "创建群组", icon: UDIcon.groupOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 创建群组", on: self.view, delay: 3)
    })
    private lazy var action33 = UDMenuAction(title: "创建团队", icon: UDIcon.teamAddOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 创建团队", on: self.view, delay: 3)
    })
    private lazy var action34 = UDMenuAction(title: "添加外部联系人", icon: UDIcon.addChatOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 添加外部联系人", on: self.view, delay: 3)
    })
    private lazy var action35 = UDMenuAction(title: "加入会议", icon: UDIcon.joinMeetingOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 加入会议", on: self.view, delay: 3)
    })
    private lazy var action36 = UDMenuAction(title: "创建文件夹", icon: UDIcon.creatFolderOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 创建文件夹", on: self.view, delay: 3)
    })

    private lazy var action41 = UDMenuAction(title: "邀请加入", icon: UDIcon.shareOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 邀请加入", on: self.view, delay: 3)
    })

    private lazy var action42 = UDMenuAction(title: "电话邀请", icon: UDIcon.phoneOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 电话邀请", on: self.view, delay: 3)
    })

    private lazy var action51 = UDMenuAction(title: "pin", icon: UDIcon.pinOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 pin", on: self.view, delay: 3)
    })

    private lazy var action52 = UDMenuAction(title: "不知道什么功能", icon: UDIcon.spaceOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 未知功能", on: self.view, delay: 3)
    })

    private lazy var action53 = UDMenuAction(title: "Doc 文档", icon: UDIcon.docOutlined, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 Doc 文档", on: self.view, delay: 3)
    })

    private lazy var action54 = UDMenuAction(title: "Doc is title", icon: UDIcon.languageFilled, tapHandler: { [weak self] in
        guard let self = self else { return }
        UDToast().showTips(with: "点击了 Doc is title", on: self.view, delay: 3)
    })

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "UniverseDesignMenu"
        self.view.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(button1)
        self.view.addSubview(button2)
        self.view.addSubview(button3)
        self.view.addSubview(button4)
        self.view.addSubview(button5)
        self.view.addSubview(button6)
        self.view.addSubview(label)
        self.view.addSubview(slider)
        button1.addTarget(self, action: #selector(click1), for: .touchUpInside)
        button2.addTarget(self, action: #selector(click2), for: .touchUpInside)
        button3.addTarget(self, action: #selector(click3), for: .touchUpInside)
        button4.addTarget(self, action: #selector(click4), for: .touchUpInside)
        button5.addTarget(self, action: #selector(click5), for: .touchUpInside)
        button6.addTarget(self, action: #selector(click6), for: .touchUpInside)
        label.text = "max length"
        button1.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(40)
            make.top.equalToSuperview().offset(100)
            make.left.equalToSuperview().offset(20)
        }
        button2.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(40)
            make.top.equalToSuperview().offset(150)
            make.left.equalToSuperview().offset(20)
        }
        button3.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(40)
            make.top.equalToSuperview().offset(200)
            make.left.equalToSuperview().offset(20)
        }
        button4.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(40)
            make.top.equalToSuperview().offset(250)
            make.left.equalToSuperview().offset(20)
        }
        button5.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(44)
            make.top.equalToSuperview().offset(300)
            make.left.equalToSuperview().offset(20)
        }
        button6.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(44)
            make.top.equalToSuperview().offset(350)
            make.left.equalToSuperview().offset(20)
        }
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(400)
            make.left.equalToSuperview().offset(20)
        }
        slider.snp.makeConstraints { make in
            make.width.equalTo(200)
            make.top.equalToSuperview().offset(430)
            make.left.equalToSuperview().offset(20)
        }

        action11.hasBadge = true
        action12.isDisabled = true
        action12.tapDisableHandler = { [weak self] in
            guard let self = self else { return }
            UDToast().showTips(with: "点击了 禁用", on: self.view, delay: 3)
        }
        action13.subTitle = "副标题"
        action14.isDisabled = true
        action14.titleTextColor = .green
        action14.subTitle = "禁用副标题"
        action15.subTitle = "a very long subtitle"
        actions1.append(action11)
        actions1.append(action12)
        actions1.append(action13)
        actions1.append(action14)
        actions1.append(action15)

        action22.isDisabled = true
        action23.subTitle = "一行副标题"
        action24.isDisabled = true
        action24.subTitle = "努力达到一行半的副标题被禁用"
        action24.showBottomBorder = true
        action25.subTitle = "a very very very very very very very very very long subtitle"
        actions2.append(action21)
        actions2.append(action22)
        actions2.append(action23)
        actions2.append(action24)
        actions2.append(action25)

        actions3.append(action31)
        actions3.append(action32)
        actions3.append(action33)
        actions3.append(action34)
        actions3.append(action35)

        action42.subTitle = "+86 188 8888 8888"
        actions4.append(action41)
        actions4.append(action42)

        action52.subTitle = "未知功能"
        action53.subTitle = "很长很长的说明，预期它应该是要出现点点点了"
        action54.subTitle = "The time thats my journey takes is long and the way of it long"
        actions5.append(action51)
        actions5.append(action52)
        actions5.append(action53)
        actions5.append(action54)
    }
}

extension UniverseDesignMenuVC {
    private func createBtn(bgColor: UIColor, title: String, panSelector: Selector) -> UIButton {
        let button: UIButton = {
            let button = UIButton(type: .custom)
            button.backgroundColor = bgColor
            button.setTitleColor(UIColor.ud.N00, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            button.layer.cornerRadius = 6.0
            button.layer.masksToBounds = true
            button.setTitle(title, for: .normal)
            let pan = UIPanGestureRecognizer(target: self, action: panSelector)
            pan.minimumNumberOfTouches = 1
            pan.maximumNumberOfTouches = 1
            button.addGestureRecognizer(pan)
            return button
        }()
        return button
    }

    @objc
    func pan1(recognizer:UIPanGestureRecognizer) {
        let point = recognizer.location(in: self.view)
        button1.snp.remakeConstraints { make in
            make.centerX.equalTo(point.x)
            make.centerY.equalTo(point.y)
            make.width.equalTo(100)
            make.height.equalTo(44)
        }
    }
    @objc
    func pan2(recognizer:UIPanGestureRecognizer) {
        let point = recognizer.location(in: self.view)
        button2.snp.remakeConstraints { make in
            make.centerX.equalTo(point.x)
            make.centerY.equalTo(point.y)
            make.width.equalTo(100)
            make.height.equalTo(44)
        }
    }

    @objc
    func pan3(recognizer:UIPanGestureRecognizer) {
        let point = recognizer.location(in: self.view)
        button3.snp.remakeConstraints { make in
            make.centerX.equalTo(point.x)
            make.centerY.equalTo(point.y)
            make.width.equalTo(100)
            make.height.equalTo(44)
        }
    }

    @objc
    func pan4(recognizer:UIPanGestureRecognizer) {
        let point = recognizer.location(in: self.view)
        button4.snp.remakeConstraints { make in
            make.centerX.equalTo(point.x)
            make.centerY.equalTo(point.y)
            make.width.equalTo(100)
            make.height.equalTo(44)
        }
    }

    @objc
    func pan5(recognizer:UIPanGestureRecognizer) {
        let point = recognizer.location(in: self.view)
        button5.snp.remakeConstraints { make in
            make.centerX.equalTo(point.x)
            make.centerY.equalTo(point.y)
            make.width.equalTo(100)
            make.height.equalTo(44)
        }
    }
    @objc
    func pan6(recognizer:UIPanGestureRecognizer) {
        let point = recognizer.location(in: self.view)
        button6.snp.remakeConstraints { make in
            make.centerX.equalTo(point.x)
            make.centerY.equalTo(point.y)
            make.width.equalTo(100)
            make.height.equalTo(44)
        }
    }

    @objc
    func click1() {
        style.menuMaxWidth = CGFloat(slider.value)
        style.showArrowInPopover = false
        print("click1,menuMaxWidth", style.menuMaxWidth)
        style.showSubTitleInOneLine = true
        menu = UDMenu(actions: actions1, style: style)
        menu.showMenu(sourceView: button1, sourceVC: self)
    }

    @objc
    func click2() {
        style.menuMaxWidth = CGFloat(slider.value)
        style.showArrowInPopover = true
        menu = UDMenu(actions: actions2, style: style)
        menu.showMenu(sourceView: button2, sourceVC: self)
    }

    @objc
    func click3() {
        style.menuMaxWidth = CGFloat(slider.value)
        menu = UDMenu(actions: actions3, style: style)
        menu.showMenu(sourceView: button3, sourceVC: self)
    }

    @objc
    func click4() {
        style.menuMaxWidth = CGFloat(slider.value)
        style.showSubTitleInOneLine = true
        menu = UDMenu(actions: actions4, style: style)
        menu.showMenu(sourceView: button4, sourceVC: self)
    }

    @objc
    func click5() {
        style.menuMaxWidth = CGFloat(slider.value)
        style.menuItemIconTintColor = .red
        style.menuMaxWidth = 210
        menu = UDMenu(actions: actions1 + actions5 + actions1, style: style)
        menu.showMenu(sourceView: button5, sourceVC: self)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            self.menu.closeMenu(animated: true)
        })
    }

    @objc
    func click6() {
        actions1[0].hasBadge = !actions1[0].hasBadge
    }
}
