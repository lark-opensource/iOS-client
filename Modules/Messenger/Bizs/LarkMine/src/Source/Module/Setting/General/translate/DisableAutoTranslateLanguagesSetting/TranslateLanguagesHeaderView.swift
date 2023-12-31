//
//  TranslateLanguagesHeaderView.swift
//  LarkMine
//
//  Created by 李勇 on 2019/5/13.
//

import UIKit
import Foundation

/// 代理
protocol TranslateLanguagesHeaderViewDelegate: AnyObject {
    func languageKeyDidSelect(language: String)
}

/// 展示一些语言，提供删除操作
final class TranslateLanguagesHeaderView: UIView {
    /// button开始的tag
    private static let buttonBeginTag: Int = 1000
    /// 滚动内容视图，内部item使用frame计算位置
    private lazy var scrollView: UIScrollView = UIScrollView()
    /// 存一份，做点击事件处理
    private var languageKeys: [String] = []
    weak var delegate: TranslateLanguagesHeaderViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        /// 添加滚动视图
        self.scrollView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.bounces = false
        self.addSubview(self.scrollView)
        self.scrollView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 更新内容
    func updateTranslateLanguages(languageKeys: [String], languageValues: [String]) {
        self.languageKeys = languageKeys
        self.scrollView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        /// 滚动视图的高度
        let scrollViewHeight: CGFloat = 54
        /// 得到x图标的icon大小
        let deleteImage: UIImage = Resources.delete_language_icon
        let deleteImageSize: CGSize = deleteImage.size
        /// 按钮的高度
        let buttonHeight: CGFloat = 24
        /// 按钮距父视图顶的距离
        let buttonTopDistance: CGFloat = (scrollViewHeight - buttonHeight) / 2

        /// item之间的间距 item构成：|<-->label<-->icon<-->|
        let itemDistance: CGFloat = 4
        /// item内部label距父视图左的距离
        let labelLeftDistance: CGFloat = 6
        /// item内部x图标距父视图右的距离
        let deleteRightDistance: CGFloat = 6
        /// item内部x图标和label的间距
        let labelDeleteDistance: CGFloat = 4

        /// 记录当前item应该从哪个位置绘制
        var currLastX: CGFloat = 0
        languageValues.enumerated().forEach { (offset, languageValue) in
            let button: UIButton = UIButton(type: .custom)
            button.backgroundColor = UIColor.ud.N200
            button.layer.cornerRadius = 1.5
            button.clipsToBounds = true
            button.tag = TranslateLanguagesHeaderView.buttonBeginTag + offset
            button.addTarget(self, action: #selector(languageButtonClick), for: .touchUpInside)
            /// 创建label，得到字符串占用的size
            let label: UILabel = UILabel()
            label.text = languageValue
            label.font = UIFont.systemFont(ofSize: 15)
            label.textColor = UIColor.ud.N900
            let labelSize: CGSize = label.sizeThatFits(.zero)
            /// 创建imageView
            let imageView: UIImageView = UIImageView()
            imageView.image = deleteImage
            /// 得到按钮的总宽度
            let buttonWidth: CGFloat = labelLeftDistance + labelSize.width + labelDeleteDistance + deleteImageSize.width + deleteRightDistance

            /// 开始添加视图
            button.frame = CGRect(origin: CGPoint(x: currLastX, y: buttonTopDistance), size: CGSize(width: buttonWidth, height: buttonHeight))
            label.frame = CGRect(origin: CGPoint(x: labelLeftDistance, y: (buttonHeight - labelSize.height) / 2), size: labelSize)
            imageView.frame = CGRect(origin: CGPoint(x: buttonWidth - deleteRightDistance - deleteImageSize.width, y: (buttonHeight - deleteImageSize.height) / 2), size: deleteImageSize)
            button.addSubview(label)
            button.addSubview(imageView)
            self.scrollView.addSubview(button)

            /// 移动偏移
            currLastX += buttonWidth
            currLastX += itemDistance
        }
        /// 滚动视图内容宽度
        let scrollViewContentSizeWidth: CGFloat = currLastX != 0 ? currLastX - itemDistance : 0
        self.scrollView.contentSize = CGSize(width: scrollViewContentSizeWidth, height: scrollViewHeight)
    }

    @objc
    private func languageButtonClick(button: UIButton) {
        /// 得到选中的下标
        let selectIndex: Int = button.tag - TranslateLanguagesHeaderView.buttonBeginTag
        guard selectIndex >= 0, selectIndex < self.languageKeys.count else {
            return
        }
        self.delegate?.languageKeyDidSelect(language: self.languageKeys[selectIndex])
    }
}
