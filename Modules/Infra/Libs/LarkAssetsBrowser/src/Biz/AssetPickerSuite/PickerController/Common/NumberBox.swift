//
//  NumberBox.swift
//  LarkAssetsBrowser
//
//  Created by Supeng on 2021/7/2.
//

import UIKit
import Foundation

protocol NumberBoxDelegate: AnyObject {
    func didTapNumberbox(_ numberBox: NumberBox)
}

final class NumberBox: UIControl {
    /// 展示的数字
    var number: Int? {
        didSet {
            self.updateNumber()
        }
    }
    var autoTapBounceAnimation = true

    private let numberLabel = UILabel()
    private let bgImageView = UIImageView()
    weak var delegate: NumberBoxDelegate?
    private let labelFont = UIFont.systemFont(ofSize: 16)
    private let labelSize = CGSize(width: 24, height: 24)

    init(number: Int?) {
        self.number = number
        super.init(frame: CGRect.zero)
        self.setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {

        bgImageView.frame = self.bounds
        bgImageView.image = Resources.numberBox_unchecked
        addSubview(bgImageView)
        bgImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 30, height: 30))
            make.center.equalToSuperview()
        }

        // 添加计数label
        numberLabel.text = ""
        numberLabel.textAlignment = .center
        numberLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        numberLabel.font = labelFont
        numberLabel.layer.cornerRadius = labelSize.width / 2.0
        numberLabel.backgroundColor = UIColor.clear
        /**
          这里没有通过设置numberLabel的background的为UIColor.ud.colorfulBlue->
          因为label设置backgroundColor之后 再切圆角，需要numberLabel.layer.masksToBounds = true
          触发离屏渲染,直接设置layerColor
         */
        numberLabel.layer.backgroundColor = UIColor.ud.colorfulBlue.cgColor
        addSubview(numberLabel)
        numberLabel.snp.makeConstraints { (make) in
            make.height.equalTo(labelSize.height)
            make.width.equalTo(labelSize.width)
            make.center.equalToSuperview()
        }
        updateNumber()

        addTarget(self, action: #selector(numberBoxTap), for: .touchUpInside)
    }

    @objc
    func numberBoxTap() {
        delegate?.didTapNumberbox(self)
        if autoTapBounceAnimation == true {
            startTapBounceAnimation()
        }
    }

    func startTapBounceAnimation(onCompleted: (() -> Void)? = nil) {
        if self.number == nil {
            // number == nil 即不需要动画，直接调用onCompleted返回
            onCompleted?()
            return
        }
        self.layer.lu.bounceAnimation(frames: [1, 1.2, 1], duration: 0.25, key: nil) {
            onCompleted?()
        }

    }

    private func updateNumber() {
        if let number = number {
            // 展示Label
            numberLabel.text = String(number)
            numberLabel.isHidden = false

            // 隐藏背景
            bgImageView.isHidden = true
            // 计算高度后重新设置约束
            var width = (String(number) as NSString).boundingRect(
                with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30),
                options: .usesLineFragmentOrigin,
                attributes: [.font: labelFont],
                context: nil).width
            // UI规定, 满足文字左右各4间距显示圆形, 不满足则改变宽度满足间距
            width += 8
            width = width > labelSize.width ? width : labelSize.width
            numberLabel.snp.remakeConstraints { (make) in
                // 如果width需要扩展, 则撑开父view
                if width != labelSize.width {
                    make.left.right.equalToSuperview()
                }
                make.height.equalTo(labelSize.height)
                make.width.equalTo(width)
                make.center.equalToSuperview()
            }
        } else {
            // 隐藏label
            numberLabel.text = ""
            numberLabel.isHidden = true
            // 展示背景
            bgImageView.isHidden = false
        }
    }
}
