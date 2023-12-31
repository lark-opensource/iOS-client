//
//  GroupColorView.swift
//  LarkChatSetting
//
//  Created by kangsiwan on 2020/4/17.
//

import Foundation
import UIKit
import LarkTag
import LarkExtensions
import UniverseDesignColor
/// 展示可选中的颜色
final class GroupColorView: UIView {
    private static let buttonBeginTag: Int = 500
    /// 所有颜色对应的按钮
    private var colorsButtonArray = [UIButton]()
    /// 用户可以选中的颜色，固定为8个
    private let colorArray = [UDColor.rgb(0x3370FF), UDColor.rgb(0x7F3BF5),
                              UDColor.rgb(0x04B49C), UDColor.rgb(0x2EA121),
                              UDColor.rgb(0x8FAC02), UDColor.rgb(0xDC9B04),
                              UDColor.rgb(0xDE7802), UDColor.rgb(0xF01D94)]
    /// 各颜色对应的默认图片，缓存起来，防止重复创建
    private var colorImageMap: [UIColor: UIImage] = [:]
    /// 用户当前选中颜色按钮的tag，值为-1表示未选中任何项
    private var selectButtonTag = -1
    /// 用户选择了一种新的颜色
    var selectColorChangeHandler: ((UIColor) -> Void)?

    /// 用于判断是否需要重新计算按钮间距
    private var previousBoundsWidth: CGFloat = 0
    /**埋点使用Chat参数*/
    var extraInfo: [String: Any] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
        // 选择颜色标签
        let changeColorLabel = UILabel()
        self.addSubview(changeColorLabel)
        changeColorLabel.text = BundleI18n.LarkChatSetting.Lark_Core_custmoized_groupavatar_color
        changeColorLabel.textColor = UIColor.ud.N800
        changeColorLabel.font = UIFont.systemFont(ofSize: 14)
        changeColorLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(20)
            maker.left.equalTo(16)
        }

        for (index, item) in colorArray.enumerated() {
            let button = createColorButton()
            button.backgroundColor = item
            self.addSubview(button)
            colorsButtonArray.append(button)
            button.tag = GroupColorView.buttonBeginTag + index
        }

        // 提示区域
        let tipsLabel = PaddingUILabel()
        tipsLabel.font = UIFont.systemFont(ofSize: 14)
        tipsLabel.text = BundleI18n.LarkChatSetting.Lark_Core_customized_question
        tipsLabel.numberOfLines = 0
        tipsLabel.textColor = UIColor.ud.N500
        tipsLabel.color = UIColor.ud.bgBase
        tipsLabel.paddingLeft = 16
        tipsLabel.paddingTop = 8
        tipsLabel.paddingRight = 16
        self.addSubview(tipsLabel)
        tipsLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            let lastContrlBottom = colorsButtonArray.last?.snp.bottom ?? changeColorLabel.snp.bottom
            make.top.equalTo(lastContrlBottom).offset(24)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width != previousBoundsWidth {
            previousBoundsWidth = bounds.width
            // button距离self.top为56，button宽高为28
            let buttonOffsetForTop: CGFloat = 56; let buttonSize: CGFloat = 28
            // 如果一行中绘制所有button，每个button间距为多少，button距离self.left&self.right为固定值16
            let offset = (self.bounds.size.width - 2 * 16 - buttonSize * CGFloat(colorArray.count)) / CGFloat(colorArray.count - 1)
            // 是否需要换行显示，如果大于UX要求的最小值16，说明一行就可以绘制完成，否则需要换行
            let needNextLine = offset < 16
            // 当前button应该绘制到哪一行，应该在那个x绘制当前button
            var row: CGFloat = 0; var currButtonXOffset: CGFloat = 16

            for (index, button) in colorsButtonArray.enumerated() {
                if needNextLine {
                    // 需要换行则保持button间距为16
                    if currButtonXOffset + buttonSize > self.bounds.size.width - 16 {
                        row += 1
                        currButtonXOffset = 16
                    }
                    button.frame = CGRect(x: currButtonXOffset, y: buttonOffsetForTop + row * (buttonSize + 16), width: buttonSize, height: buttonSize)
                    currButtonXOffset = button.frame.maxX + 16
                } else {
                    // 不需要换行则间距保持为计算出来的offset
                    button.frame = CGRect(x: 16 + (buttonSize + offset) * CGFloat(index), y: buttonOffsetForTop, width: buttonSize, height: buttonSize)
                }
            }
        }
    }

    /// 构造button
    private func createColorButton() -> UIButton {
        let button = UIButton()
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 14
        button.setImage(nil, for: .normal)
        button.setImage(Resources.group_check_icon, for: .selected)
        button.addTarget(self, action: #selector(buttonClick(button:)), for: .touchUpInside)
        return button
    }

    @objc
    private func buttonClick(button: UIButton) {
        // 选中了已经选中的按钮，不进行任何操作
        guard button.tag != selectButtonTag else { return }

        // 重置上一个选中的按钮为未选中状态
        if selectButtonTag != -1 {
            colorsButtonArray[selectButtonTag - GroupColorView.buttonBeginTag].isSelected = false
        }
        // 设置当前按钮为选中状态
        selectButtonTag = button.tag
        button.isSelected = true
        // 通知调用方颜色变化
        self.selectColorChangeHandler?(colorArray[selectButtonTag - GroupColorView.buttonBeginTag])
        ChatSettingTracker.trackGroupProfileAvatarColorSelection(colorArray[selectButtonTag - GroupColorView.buttonBeginTag], chatInfo: self.extraInfo)
    }
}

/// 对外提供的接口
extension GroupColorView {
    /// 清空选中的颜色
    func clearSelectColor() {
        guard selectButtonTag != -1 else { return }

        // 重置上一个选中的按钮为未选中状态
        colorsButtonArray[selectButtonTag - GroupColorView.buttonBeginTag].isSelected = false
        selectButtonTag = -1
    }

    /// 默认随机选中一种颜色
    func selectRandomColor() {
        selectButtonTag = GroupColorView.buttonBeginTag + Int.random(in: 0..<colorsButtonArray.count)
        colorsButtonArray[selectButtonTag - GroupColorView.buttonBeginTag].isSelected = true
    }

    /// 获取当前用户选中的颜色，如果未选中，则随机选中一个颜色
    func currSelectColor() -> UIColor? {
        guard selectButtonTag != -1 else { return nil }

        return self.colorArray[selectButtonTag - GroupColorView.buttonBeginTag]
    }

    /// 获取某个颜色对应的默认群头像
    func getImageFor(originImage: UIImage, color: UIColor) -> UIImage {
        guard self.colorArray.firstIndex(where: { $0.cgColor == color.cgColor }) != nil else { return UIImage() }
        if let image = colorImageMap[color] { return image }
        // 通过颜色，生成对应的图片
        let resultImage = originImage.lu.colorize(color: color)
        colorImageMap[color] = resultImage
        return resultImage
    }

    /// 选中指定的颜色
    func setSelectColor(color: UIColor) {
        guard let index = self.colorArray.firstIndex(where: { $0.cgColor == color.cgColor }) else { return }

        selectButtonTag = GroupColorView.buttonBeginTag + index
        colorsButtonArray[index].isSelected = true
    }
}
