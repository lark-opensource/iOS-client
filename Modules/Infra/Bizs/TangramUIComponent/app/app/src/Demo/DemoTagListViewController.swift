//
//  DemoTagListViewController.swift
//  TangramUIComponentDev
//
//  Created by 袁平 on 2021/7/15.
//

import Foundation
import UIKit
import TangramUIComponent
import TangramComponent

class DemoTagListViewController: BaseDemoViewController {
    lazy var tagListProps: TagListComponentProps = {
        let props = TagListComponentProps()
        props.tagInfos = [TagInfo(text: "外部联系人", textColor: .black, backgroundColor: .red.withAlphaComponent(50))]
        props.font = UIFont.ud.body2
        props.tagTextColor = UIColor.ud.udtokenTagTextSRed
        props.tagBackgroundColor = UIColor.ud.udtokenTagBgRed
        props.numberOfLines = 1
        return props
    }()

    lazy var tagList: TagListComponent<EmptyContext> = {
        let tagList = TagListComponent<EmptyContext>(props: tagListProps)
        return tagList
    }()

    lazy var tagText: UITextField = {
        let tagText = UITextField()
        tagText.layer.borderWidth = 1
        tagText.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        tagText.placeholder = "Tag Text"
        return tagText
    }()

    lazy var tagWidth: UITextField = {
        let tagWidth = UITextField()
        tagWidth.layer.borderWidth = 1
        tagWidth.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        tagWidth.placeholder = "Tag Width"
        return tagWidth
    }()

    lazy var tagHeight: UITextField = {
        let tagHeight = UITextField()
        tagHeight.layer.borderWidth = 1
        tagHeight.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        tagHeight.placeholder = "Tag Height"
        return tagHeight
    }()

    lazy var maxLines: UITextField = {
        let maxLines = UITextField()
        maxLines.layer.borderWidth = 1
        maxLines.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        maxLines.placeholder = "Max Lines"
        return maxLines
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTool()
    }

    override func setupView() {
        super.setupView()
        rootLayout.setChildren([tagList])
        root.style.width = TCValue(cgfloat: view.bounds.width - 20)
        render.update(rootComponent: root)
        render.render()
    }

    func setupTool() {
        view.addSubview(tagText)
        tagText.snp.makeConstraints { make in
            make.top.equalTo(wrapper.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(44)
        }

        view.addSubview(tagWidth)
        tagWidth.snp.makeConstraints { make in
            make.top.equalTo(tagText.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(44)
        }

        view.addSubview(tagHeight)
        tagHeight.snp.makeConstraints { make in
            make.top.equalTo(tagWidth.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(44)
        }

        view.addSubview(maxLines)
        maxLines.snp.makeConstraints { make in
            make.top.equalTo(tagHeight.snp.bottom).offset(12)
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
            make.top.equalTo(maxLines.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(44)
        }
    }

    @objc
    func update() {
        if let title = tagText.text, !title.isEmpty {
            var tags = tagListProps.tagInfos
            tags.append(TagInfo(text: title, textColor: UIColor.random(), backgroundColor: UIColor.random()))
            tagListProps.tagInfos = tags
        }
        if let text = tagWidth.text, !text.isEmpty, let width = Double(text) {
            root.style.width = TCValue(cgfloat: CGFloat(width))
        }
        if let text = tagHeight.text, !text.isEmpty, let height = Double(text) {
            root.style.height = TCValue(cgfloat: CGFloat(height))
        }
        if let text = maxLines.text, !text.isEmpty, let maxLines = Int(text) {
            tagListProps.numberOfLines = maxLines
        }
        tagList.props = tagListProps
        render.update(rootComponent: root)
        render.render()
    }
}
