//
//  ViewController.swift
//  LarkTagDev
//
//  Created by 郭怡然 on 2022/8/9.
//

import Foundation
import UIKit
import UniverseDesignAvatar
import UniverseDesignFont
import UniverseDesignIcon
import UniverseDesignTag
import LarkTag

class ViewController: UIViewController {
    
    private lazy var avatar: UDAvatar = {
        let avatar = UDAvatar()
        avatar.image = UDIcon.virtualAvatarOutlined
        avatar.config.style = .circle
        return avatar
    }()
    
    public lazy var userLabel: UILabel = {
        let label = UILabel()
        label.text = "用户名"
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.body2
        return label
    }()
    
    public var dialogLabel: UILabel = {
        let label = UILabel()
        label.text = "摘要信息"
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UDFont.body2
        return label
    }()
    
    ///使用UIStackView最为最外层
    private lazy var wrapperStack: UIStackView = {
        let wrapperStack = UIStackView()
        wrapperStack.axis = .vertical
        wrapperStack.alignment = .center
        wrapperStack.distribution = .fill
        wrapperStack.spacing = 40
        wrapperStack.isLayoutMarginsRelativeArrangement = true
        wrapperStack.translatesAutoresizingMaskIntoConstraints = false //会影响Auto Layout
        return wrapperStack
    }()
    
    private var feedView: UIView = UIView()
    
    private lazy var tag: Tag = {
        var tag = Tag(type: .organization, style: .blue, size: .mini)
        return tag
    }()

    
    public lazy var organizationTag: TagWrapperView = {
        var tagView = TagWrapperView()
        var tags: [Tag] = [tag]
        tagView.setElements(tags)
        return tagView
    }()
    
    /// 用户名文本输入框
    private lazy var userTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "输入用户名文本"
        textField.font = UDFont.body2
        textField.borderStyle = .line
        textField.textAlignment = .center
        textField.delegate = self
        textField.returnKeyType = UIReturnKeyType.done
        textField.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingChanged)
        return textField
    }()
    
    /// 标签文本输入框
    private lazy var tagTitleTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "输入标签文本"
        textField.font = UDFont.body2
        textField.borderStyle = .line
        textField.textAlignment = .center
        textField.delegate = self
        textField.returnKeyType = UIReturnKeyType.done
        textField.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingChanged)
        return textField
    }()
    
    /// 标签区域宽度滑动条
    private lazy var tagWidthSlider: UISlider = {
        let mySlider = UISlider()
        mySlider.minimumValue = 0
        mySlider.maximumValue = 300
        mySlider.setValue(50, animated: false)
        mySlider.isContinuous = true
        mySlider.tintColor = UIColor.green
        mySlider.addTarget(self, action: #selector(self.sliderValueDidChange(_:)), for: .valueChanged)
        return mySlider
    }()
    
    /// 标签大小选择
    private lazy var sizeBtn: UISegmentedControl = {
        let segmentedCtl = UISegmentedControl(items: ["mini","small","middle", "large"])
        segmentedCtl.selectedSegmentIndex = 0
        segmentedCtl.addTarget(self, action: #selector(changeTagSize), for: .valueChanged)
        return segmentedCtl
    }()
    
    ///是否有权限选择
    private lazy var permissionBtn: UISegmentedControl = {
        let segmentedCtl = UISegmentedControl(items: ["有权限","无权限"])
        segmentedCtl.selectedSegmentIndex = 0
        segmentedCtl.addTarget(self, action: #selector(changePermission), for: .valueChanged)
        return segmentedCtl
    }()
    
    @objc private func changePermission(sender: UISegmentedControl) {
        updateTag(tagTitle: tagTitle, isPermitted: isPermitted, tagSize: tagSize)
    }
    
    @objc private func changeTagSize(sender: UISegmentedControl) {
        updateTag(tagTitle: tagTitle, isPermitted: isPermitted, tagSize: tagSize)
    }
    
    @objc func sliderValueDidChange(_ sender:UISlider!)
    {
        organizationTag.snp.updateConstraints { make in
            make.width.lessThanOrEqualTo(tagWidthSlider.value)
        }
    }
    
    @objc func textFieldDidBeginEditing(_ textField:UITextField){
        if textField == tagTitleTextField {
            updateTag(tagTitle: tagTitle, isPermitted: isPermitted, tagSize: tagSize)
        } else if textField == userTextField {
            userLabel.text = textField.text
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        // Do any additional setup after loading the view.
    }
    
    private func setup() {
        addComponents()
        makeConstraints()
        setAppearance()
    }
    
    private func addComponents() {
        view.addSubview(wrapperStack)
        wrapperStack.addArrangedSubview(feedView)
        feedView.addSubview(avatar)
        feedView.addSubview(userLabel)
        feedView.addSubview(organizationTag)
        feedView.addSubview(dialogLabel)
        wrapperStack.addArrangedSubview(userTextField)
        wrapperStack.addArrangedSubview(tagTitleTextField)
        wrapperStack.addArrangedSubview(tagWidthSlider)
        wrapperStack.addArrangedSubview(permissionBtn)
        wrapperStack.addArrangedSubview(sizeBtn)
        
    }
    private func makeConstraints() {
        NSLayoutConstraint.activate([
            wrapperStack.widthAnchor.constraint(equalTo: view.widthAnchor),
            wrapperStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wrapperStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        feedView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        
        avatar.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.top.equalToSuperview().offset(24)
            make.left.equalToSuperview().offset(12)
        }
        
        userLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(12)
            make.top.equalTo(avatar.snp.top).offset(2)
        }
        
        dialogLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(12)
            make.top.equalTo(avatar.snp.centerY).offset(10)
            make.bottom.equalToSuperview().offset(-24)
        }
        
        organizationTag.snp.makeConstraints { make in
            make.left.equalTo(userLabel.snp.right).offset(12)
            make.right.lessThanOrEqualToSuperview().offset(-12)
            make.top.equalTo(userLabel.snp.top)
            make.width.lessThanOrEqualTo(tagWidthSlider.value)
        }
        
        tagWidthSlider.snp.makeConstraints { make in
            make.width.equalTo(300)
        }
    }
    private func setAppearance() {
        self.view.backgroundColor = UIColor.ud.bgBase
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(false)
        return true
    }
}

extension ViewController {
    private var tagTitle: String? { tagTitleTextField.text }
    
    private var tagWidth: Float {
        tagWidthSlider.value
    }
    
    private var isPermitted: Bool {
        if permissionBtn.selectedSegmentIndex == 0 {
            return true
        } else {
            return false
        }
    }
    
    private var tagSize: LarkTag.Size {
        switch sizeBtn.selectedSegmentIndex {
        case 0:
            return .mini
        case 1:
            return .small
        case 2:
            return .medium
        case 3:
            return .large
        default:
            return .mini
        }
    }
    
    private func updateTag(tagTitle: String?, isPermitted: Bool, tagSize: LarkTag.Size) {
        if !(tagTitle?.isEmpty ?? true) && isPermitted {
            tag = Tag(title: tagTitle, style: .blue, type: .organization, size: tagSize)
        } else {
            tag = Tag(type: .organization, style: .blue, size: tagSize)
        }
        organizationTag.setElements([tag])
    }
}
