//
//  DemoHeaderViewController.swift
//  TangramUIComponentDev
//
//  Created by 袁平 on 2021/6/16.
//

import Foundation
import UIKit
import TangramComponent
import TangramUIComponent
import UniverseDesignMenu
import LarkTag

class DemoHeaderViewController: UIViewController {
    let wrapper = UIView()
    let container = UIView(frame: .zero)
    var render: ComponentRenderer!
    var root: UIViewComponent<EmptyProps, EmptyContext>!
    var tagType: TagType?
    var headerProps = TangramHeaderComponentProps()
    var header: TangramHeaderComponent<EmptyContext>!

    lazy var headerTitle: UITextField = {
        let headerTitle = UITextField()
        headerTitle.layer.borderWidth = 1
        headerTitle.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        return headerTitle
    }()

    lazy var showIcon: SwitchView = {
        let showIcon = SwitchView(title: "Icon")
        return showIcon
    }()

    lazy var showClose: SwitchView = {
        let showClose = SwitchView(title: "Close Icon")
        return showClose
    }()

    lazy var showCopy: SwitchView = {
        let showCopy = SwitchView(title: "Copy Icon")
        return showCopy
    }()

    lazy var width: UITextField = {
        let width = UITextField()
        width.layer.borderWidth = 1
        width.text = "\(view.bounds.width - 20)"
        width.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        return width
    }()

    lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle("Update", for: .normal)
        button.setTitleColor(UIColor.ud.N900, for: .normal)
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        button.layer.borderWidth = 1
        button.addTarget(self, action: #selector(updateHeader), for: .touchUpInside)
        return button
    }()

    lazy var tag1: UILabel = {
        let tag = UILabel()
        tag.text = "none"
        tag.textColor = UIColor.ud.N900
        tag.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        tag.layer.borderWidth = 1
        tag.isUserInteractionEnabled = true
        tag.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showTagList)))
        return tag
    }()

    lazy var tag2: UITextField = {
        let tag2 = UITextField()
        tag2.layer.borderWidth = 1
        tag2.placeholder = "自定义Tag文字"
        tag2.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        return tag2
    }()

    lazy var titleType: UILabel = {
        let titleType = UILabel()
        titleType.text = "title"
        titleType.textColor = UIColor.ud.N900
        titleType.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        titleType.layer.borderWidth = 1
        titleType.isUserInteractionEnabled = true
        titleType.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showTitleType)))
        return titleType
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        setupHeader()
        setupTool()
    }

    func setupHeader() {
        view.addSubview(wrapper)
        wrapper.layer.borderColor = UIColor.red.cgColor
        wrapper.layer.borderWidth = 1
        let margin: CGFloat = 10
        let width = view.bounds.width - margin * 2
        wrapper.frame = CGRect(x: margin, y: 100, width: width, height: 100)

        wrapper.addSubview(container)

        headerProps.title = "初始化Header Title"
        headerProps.showCloseButton = true
        headerProps.showCopyLinkButton = true
        headerProps.iconProvider.update { view in
            view.image = .random()
        }
        headerProps.titleType = .title
        header = TangramHeaderComponent<EmptyContext>(props: headerProps)

        var layoutProps = LinearLayoutComponentProps()
        layoutProps.orientation = .row
        let layout = LinearLayoutComponent(children: [header], props: layoutProps)

        root = UIViewComponent<EmptyProps, EmptyContext>(props: .empty)
        root.style.borderWidth = 1
        root.style.borderColor = UIColor.ud.lineBorderComponent
        root.style.maxWidth = TCValue(cgfloat: width)
        root.setLayout(layout)

        render = ComponentRenderer(rootComponent: root, preferMaxLayoutWidth: width, preferMaxLayoutHeight: 100)
        render.bind(to: container)
        render.render()
    }

    func setupTool() {
        headerTitle.placeholder = "Header Title"
        view.addSubview(headerTitle)
        headerTitle.snp.makeConstraints { make in
            make.top.equalTo(wrapper.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(44)
        }

        view.addSubview(showIcon)
        showIcon.snp.makeConstraints { make in
            make.top.equalTo(headerTitle.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
        }
        view.addSubview(showClose)
        showClose.snp.makeConstraints { make in
            make.centerY.equalTo(showIcon)
            make.leading.equalTo(showIcon.snp.trailing).offset(12)
        }
        view.addSubview(showCopy)
        showCopy.snp.makeConstraints { make in
            make.centerY.equalTo(showIcon)
            make.leading.equalTo(showClose.snp.trailing).offset(12)
        }

        let tagTitle1 = UILabel()
        tagTitle1.text = "Header Tag:"
        tagTitle1.textColor = UIColor.ud.textCaption
        view.addSubview(tagTitle1)
        tagTitle1.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalTo(showIcon.snp.bottom).offset(12)
        }
        view.addSubview(tag1)
        tag1.snp.makeConstraints { make in
            make.top.equalTo(showIcon.snp.bottom).offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.leading.equalTo(tagTitle1.snp.trailing).offset(12)
        }

        let tagTitle2 = UILabel()
        tagTitle2.text = "Header Tag:"
        tagTitle2.textColor = UIColor.ud.textCaption
        view.addSubview(tagTitle2)
        tagTitle2.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalTo(tagTitle1.snp.bottom).offset(12)
        }
        view.addSubview(tag2)
        tag2.snp.makeConstraints { make in
            make.leading.equalTo(tagTitle2.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalTo(tagTitle2)
            make.height.equalTo(24)
        }

        let titleTypeLabel = UILabel()
        titleTypeLabel.text = "Title Type:"
        titleTypeLabel.textColor = UIColor.ud.textCaption
        view.addSubview(titleTypeLabel)
        titleTypeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalTo(tagTitle2.snp.bottom).offset(12)
        }
        view.addSubview(titleType)
        titleType.snp.makeConstraints { make in
            make.top.equalTo(tagTitle2.snp.bottom).offset(12)
            make.leading.equalTo(titleTypeLabel.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }

        let widthLabel = UILabel()
        widthLabel.text = "Container Width:"
        widthLabel.textColor = UIColor.ud.textCaption
        view.addSubview(widthLabel)
        widthLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalTo(titleTypeLabel.snp.bottom).offset(24)
        }
        view.addSubview(width)
        width.snp.makeConstraints { make in
            make.leading.equalTo(widthLabel.snp.trailing).offset(12)
            make.centerY.equalTo(widthLabel)
            make.height.equalTo(36)
            make.width.equalTo(100)
        }

        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalTo(widthLabel.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(44)
        }
    }

    @objc
    func showTagList(_ recognizer: UITapGestureRecognizer) {
        var actions: [UDMenuAction] = []
        let none = UDMenuAction(title: "none", icon: UIImage.random()) { [weak self] in
            self?.tagType = nil
            self?.tag1.text = "none"
        }
        actions.append(none)
        TagType.allCases.forEach { tagType in
            if tagType == .customIconTag || tagType == .customTitleTag { return }
            let title = tagType.tag.title ?? "\(tagType.rawValue)"
            let action = UDMenuAction(title: title, icon: tagType.tag.image ?? UIImage.random()) { [weak self] in
                self?.tagType = tagType
                self?.tag1.text = title
            }
            actions.append(action)
        }
        var style = UDMenuStyleConfig.defaultConfig()
        style.menuMaxWidth = view.bounds.width
        style.menuWidth = view.bounds.width - 24
        style.menuItemTitleFont = UIFont.ud.caption0
        let menu = UDMenu(actions: actions, style: style)
        menu.showMenu(sourceView: recognizer.view!, sourceVC: self)
    }

    @objc
    func showTitleType(_ recognizer: UITapGestureRecognizer) {
        var actions: [UDMenuAction] = []
        let titleTheme = UDMenuAction(title: "title", icon: UIImage.random()) { [weak self] in
            self?.titleType.text = "title"
        }
        actions.append(titleTheme)

        let domainTheme = UDMenuAction(title: "domain", icon: UIImage.random()) { [weak self] in
            self?.titleType.text = "domain"
        }
        actions.append(domainTheme)

        var style = UDMenuStyleConfig.defaultConfig()
        style.menuMaxWidth = view.bounds.width
        style.menuWidth = view.bounds.width - 24
        style.menuItemTitleFont = UIFont.ud.caption0
        let menu = UDMenu(actions: actions, style: style)
        menu.showMenu(sourceView: recognizer.view!, sourceVC: self)
    }

    @objc
    func updateHeader() {
        if let text = headerTitle.text, !text.isEmpty {
            headerProps.title = text
        }
        headerProps.showCloseButton = showClose.isOn
        headerProps.showCopyLinkButton = showCopy.isOn
        if showIcon.isOn {
            headerProps.iconProvider.update { view in
                view.image = UIImage.random()
            }
        } else {
            headerProps.iconProvider.update(new: nil)
        }
        if titleType.text == "title" {
            headerProps.titleType = .title
        } else {
            headerProps.titleType = .domain
        }
        let tagText = tag2.text ?? ""
        if tagText.isEmpty, tagType == nil {
            headerProps.headerTag = nil
        } else {
            headerProps.headerTag = TangramHeaderConfig.HeaderTag(tagType: tagType,
                                                                  tag: tagText.isEmpty ? nil : tagText,
                                                                  textColor: UIColor.ud.udtokenTagTextSRed,
                                                                  backgroundColor: UIColor.ud.udtokenTagBgRed)
        }

        header.props = headerProps
        if let text = width.text, !text.isEmpty, let width = Double(text) {
            render.update(preferMaxLayoutWidth: CGFloat(width), preferMaxLayoutHeight: nil)
            render.render()
        } else {
            render.update(component: header) {
                self.render.render()
            }
        }
    }
}

class SwitchView: UIView {
    lazy var switchView: UISwitch = {
        let switchView = UISwitch()
        return switchView
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.N900
        return titleLabel
    }()

    var isOn: Bool {
        get {
            return switchView.isOn
        }
        set {
            switchView.isOn = newValue
        }
    }

    init(isOn: Bool = true, title: String) {
        super.init(frame: .zero)
        addSubview(switchView)
        addSubview(titleLabel)
        switchView.isOn = isOn
        switchView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.top.equalToSuperview()
        }
        titleLabel.text = title
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.top.equalTo(switchView.snp.bottom).offset(6)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
