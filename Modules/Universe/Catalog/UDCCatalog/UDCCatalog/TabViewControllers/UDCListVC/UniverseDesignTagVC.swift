//
//  UniverseDesignTagVC.swift
//  UDCCatalog
//
//  Created by 王元洵 on 2020/9/18.
//  Copyright © 2020 王元洵. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignTag
import UniverseDesignIcon
import SnapKit
import UniverseDesignFont
import UniverseDesignColor

class UniverseDesignTagVC: UIViewController {
    private var colorScheme: UDTag.Configuration.ColorScheme = .blue {
        didSet {
            tagExample.colorScheme = colorScheme
        }
    }
    private var sizeClass: UDTag.Configuration.Size = .medium {
        didSet {
            tagExample.sizeClass = sizeClass
        }
    }
    private var isBgOpaque: Bool = true {
        didSet {
            tagExample.isBgOpaque = isBgOpaque
        }
    }
    private var icon: UIImage? = UDIcon.emojiFilled {
        didSet {
            tagExample.icon = icon
        }
    }
    private var text: String? = "请输入文本内容" {
        didSet {
            tagExample.text = text
        }
    }
    private enum TagStyle {
        case icon
        case text
        case iconText
    }
    private var tagStyle: TagStyle = .text
    {
        didSet {
            var config: UDTag.Configuration
            switch tagStyle {
            case .icon:
                config = .icon(icon ?? UDIcon.emojiFilled)
            case .text:
                config = .text(text ?? "请输入文本内容")
            case .iconText:
                config = .iconText(icon ?? UDIcon.emojiFilled, text: text ?? "请输入文本内容")
            }
            tagExample.updateConfiguration(config)
        }
    }

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

    private lazy var tagExample: UDTag = {
        var tag: UDTag
        if tagStyle == .icon{
            tag = UDTag(withIcon: icon ?? UDIcon.emojiFilled)
        } else if tagStyle == .text {
            tag = UDTag(withText: text ?? "请输入文本内容")
        } else {
            tag = UDTag(withIcon: icon ?? UDIcon.emojiFilled, text: text ?? "请输入文本内容")
        }
        tag.colorScheme = colorScheme
        tag.sizeClass = sizeClass
        return tag
    }()

    private lazy var styleBtn: UISegmentedControl = {
        let segmentedCtl = UISegmentedControl(items: ["icon","text","icon+text"])
        segmentedCtl.selectedSegmentIndex = 2
        // 設置切換選項時執行的動作
        segmentedCtl.addTarget(self, action: #selector(changeTagStyle), for: .valueChanged)
        return segmentedCtl
    }()

    private lazy var sizeBtn: UISegmentedControl = {
        let segmentedCtl = UISegmentedControl(items: ["mini","small","middle", "large"])
        segmentedCtl.selectedSegmentIndex = 2
        // 設置切換選項時執行的動作
        segmentedCtl.addTarget(self, action: #selector(changeTagSize), for: .valueChanged)
        return segmentedCtl
    }()

    private lazy var opacityBtn: UISegmentedControl = {
        let segmentedCtl = UISegmentedControl(items: ["opaque","transparent"])
        segmentedCtl.selectedSegmentIndex = 0
        // 設置切換選項時執行的動作
        segmentedCtl.addTarget(self, action: #selector(changeTagOpacity), for: .valueChanged)
        return segmentedCtl
    }()

    @objc private func changeTagStyle(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.tagStyle = .icon
        }
        if sender.selectedSegmentIndex == 1 {
            self.tagStyle = .text
        }
        if sender.selectedSegmentIndex == 2 {
            self.tagStyle = .iconText
        }
    }

    @objc private func changeTagSize(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.sizeClass = .mini
        } else if sender.selectedSegmentIndex == 1 {
            self.sizeClass = .small
        } else if sender.selectedSegmentIndex == 2 {
            self.sizeClass = .medium
        } else if sender.selectedSegmentIndex == 3 {
            self.sizeClass = .large
        }
    }

    @objc private func changeTagOpacity(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0{
            self.isBgOpaque = true
        }
        else if sender.selectedSegmentIndex == 1{
            self.isBgOpaque = false
        }
    }
    private var collectionView: UICollectionView?

    //icon选择框
    private lazy var iconView: UIStackView = {
        let iconView = UIStackView()
        iconView.axis = .horizontal
        iconView.alignment = .center
        iconView.distribution = .fill
        iconView.spacing = 10
        return iconView
    }()

    private lazy var textStackView: UIStackView = {
        let textView = UIStackView()
        textView.axis = .horizontal
        textView.alignment = .center
        textView.distribution = .fill
        textView.spacing = 40
        textView.addArrangedSubview(labelTextField)
        textView.addArrangedSubview(confirmBtn)
        return textView
    }()

    /// 文本输入框
    private lazy var labelTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "文本内容"
        textField.borderStyle = .line
        textField.textAlignment = .center
//        textField.resignFirstResponder()
        textField.delegate = self
        textField.returnKeyType = UIReturnKeyType.done
        return textField
    }()

    private lazy var confirmBtn: UIButton = {
        let button = UIButton()
        button.setTitle("确认", for: .normal)
        button.titleLabel?.font = UDFont.body2
        button.setTitleColor(UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = UIColor.ud.primaryContentLoading
        button.addTarget(self, action: #selector(onBtnClicked), for: .touchUpInside)
        return button
    }()
    
    /// icon选择区域数据源
    private lazy var iconSelections: [UIButton] = []

    // 颜色列表
    private lazy var colorHueList: [UDTag.Configuration.ColorScheme] = [
        .blue, .wathet, .turquoise, .green, .lime,
        .yellow, .orange, .red, .carmine, .purple,
        .indigo, .normal
    ]

    //icon列表
    private lazy var iconList: [UIImage] = [UDIcon.emojiFilled, UDIcon.activityFilled, UDIcon.appFilled, UDIcon.addFilled, UDIcon.adminOutlined, UDIcon.alarmOutlined]
    private func addIcon() {
        for i in 0..<iconList.count {
            iconSelections.append(createIconButton(backgroundImage: iconList[i], index: i))
            iconView.addArrangedSubview(iconSelections[i])
        }
    }

    /// 颜色按钮创建
    private func createIconButton(backgroundImage: UIImage, index: Int) -> UIButton {
        let btn = UIButton()
        btn.tag = index
        btn.setBackgroundImage(backgroundImage, for: .normal)
        btn.addTarget(self, action: #selector(onIconClicked(sender:)), for: .touchUpInside)
        return btn
    }

    /// 确认按钮点击事件
    @objc private func onBtnClicked() {
        if labelTextField.text != "" {
            text = labelTextField.text
        }
    }

    /// Icon按钮点击事件
    @objc private func onIconClicked(sender: UIButton) {
        icon = iconList[sender.tag]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            wrapperStack.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor),
            wrapperStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wrapperStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        if let collectionView = collectionView {
            //MARK: 如果不设autolayout的话UICollectionView的width就是0，frame没有起作用，存疑
            //解答：因为在UIStackView里面CollectionView的frame失效了
            NSLayoutConstraint.activate([
                collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                collectionView.heightAnchor.constraint(equalToConstant: Cons.collectionViewHeight),
                collectionView.widthAnchor.constraint(equalToConstant: 273)
            ])
        }
        NSLayoutConstraint.activate([
            labelTextField.widthAnchor.constraint(equalToConstant: Cons.textFieldWidth),
            labelTextField.heightAnchor.constraint(equalToConstant: Cons.textFieldHeight)
        ])
        NSLayoutConstraint.activate([
            confirmBtn.widthAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupSubviews() {
        self.view.addSubview(wrapperStack)
        wrapperStack.addArrangedSubview(tagExample)
        wrapperStack.addArrangedSubview(styleBtn)
        wrapperStack.addArrangedSubview(sizeBtn)
        wrapperStack.addArrangedSubview(opacityBtn)
        initColorView()
        addIcon()
        wrapperStack.addArrangedSubview(iconView)
        wrapperStack.addArrangedSubview(textStackView)
    }

    private func setupAppearance() {
        self.view.backgroundColor = UIColor.ud.bgBase
    }
}

extension UniverseDesignTagVC {

    enum Cons {
        static var collectionViewHeight: CGFloat { 85 }
        static var textFieldWidth: CGFloat { 180 }
        static var textFieldHeight: CGFloat { 32 }
    }
}

extension UniverseDesignTagVC: UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    func initColorView() {
        let layout = UICollectionViewFlowLayout()
        //MARK: 这里虽然设置了frame，但是没有起作用，存疑
        //是因为collectionView放在了UIStackView里，UIStackView是使用autoLayout写的，所以frame不起作用，所以要单独设置左右和heightAnchor
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        //注册cell
        collectionView?.register(CollectionCell.self, forCellWithReuseIdentifier:"cell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = .clear
        collectionView?.translatesAutoresizingMaskIntoConstraints = false
        //MARK: 设置每一个cell的宽高/间距
        layout.itemSize = CGSize(width: 38, height: 38)
        layout.minimumLineSpacing = 9
        layout.minimumInteritemSpacing = 9
        if let collectionView = collectionView {
            wrapperStack.addArrangedSubview(collectionView)
        }
    }

    //返回多少个组
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    //返回多少个cell
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }

    //返回自定义的cell
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? CollectionCell else {
            return UICollectionViewCell()
        }
        let color = colorHueList[indexPath.row]
        cell.cellColorScheme = color
        cell.backgroundColor = color.opaqueBgColor
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? CollectionCell
        colorScheme = cell?.cellColorScheme ?? .blue
    }
}

extension UniverseDesignTagVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(false)
        return true
    }
}

class CollectionCell: UICollectionViewCell {
    var cellColorScheme: UDTag.Configuration.ColorScheme?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
