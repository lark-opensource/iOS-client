//
//  GenericSelectAvatarEntryBar.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/9/20.
//

import Foundation
import UniverseDesignColor
import UIKit

struct AvatarEntryBarLayout {
    /// 功能按钮大小 - 宽度
    static let selectBtnWidth = 64.0
    /// 功能按钮大小 - 高度
    static let selectBtnHeight = 64.0
    /// 功能按钮左右间距
    static let horizontalSpacing = 32.0
    /// 按钮与文本之间的上下间距
    static let verticalSpacing = 4.0
    /// 功能按钮中图标大小 - 宽度
    static let imageIconWidth = 26.0
    /// 功能按钮中图标大小 - 高度
    static let iamgeIconHeight = 26.0
}

final class CircularView: UIView {

    private let imageView: UIImageView = UIImageView()
    // 点击view事件
    public var tapAction: (() -> Void)?

    init() {
        super.init(frame: .zero)
        setupView()
        setupGestureRecognizer()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setupView() {
        self.backgroundColor = UIColor.ud.B100
        /// 设置整个view宽高
        self.snp.makeConstraints { (make) in
            make.width.equalTo(AvatarEntryBarLayout.selectBtnWidth)
            make.height.equalTo(AvatarEntryBarLayout.selectBtnWidth)
        }

        // 设置圆形视图
        layer.cornerRadius = AvatarEntryBarLayout.selectBtnWidth / 2
        layer.masksToBounds = true
        // 设置图片视图
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.equalTo(AvatarEntryBarLayout.imageIconWidth)
            make.height.equalTo(AvatarEntryBarLayout.iamgeIconHeight)
            make.center.equalToSuperview()
        }
    }

    private func setupGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }

    @objc
    private func handleTap(_ gesture: UITapGestureRecognizer) {
        tapAction?()
    }

    // 设置添加的图片样式
    public func setImage(_ image: UIImage?) {
        imageView.image = image
    }
}
/// 头像选择功能条-图片、文字、拼接
final class GenericSelectAvatarEntryBar: UIView {

    public var tapImageHandler: (() -> Void)?
    public var tapTextHandler: (() -> Void)?
    public var tapJointHandler: (() -> Void)?

    /// 图片
    lazy var imageCircularView: UIView = {
        var view = CircularView()
        view.setImage(Resources.uploadImageSetting)
        view.tapAction = { [weak self] in
            self?.tapImageHandler?()
        }
        return view
    }()
    /// 文字
    private lazy var textCircularView: UIView = {
        var view = CircularView()
        view.setImage(Resources.textSetting)
        view.tapAction = { [weak self] in
            self?.tapTextHandler?()
        }
        return view
    }()
    /// 拼接
    private lazy var jointImageCircularView: UIView = {
        var view = CircularView()
        view.setImage(Resources.jointSetting)
        view.tapAction = { [weak self] in
            self?.tapJointHandler?()
        }
        return view
    }()

    private lazy var imageTipView: UILabel = {
        let tipView = UILabel()
        tipView.text = BundleI18n.LarkChatSetting.Lark_GroupPhoto_Type_Image_Mobile_Option
        tipView.textColor = UIColor.ud.textPlaceholder
        tipView.font = .systemFont(ofSize: 14, weight: .medium)
        tipView.numberOfLines = 0
        tipView.textAlignment = .center
        return tipView
    }()

    private lazy var textTipView: UILabel = {
        let tipView = UILabel()
        tipView.text = BundleI18n.LarkChatSetting.Lark_GroupPhoto_Type_Text_Mobile_Option
        tipView.textColor = UIColor.ud.textPlaceholder
        tipView.font = .systemFont(ofSize: 14, weight: .medium)
        tipView.numberOfLines = 0
        tipView.textAlignment = .center
        return tipView
    }()

    private lazy var jointTipView: UILabel = {
        let tipView = UILabel()
        tipView.text = BundleI18n.LarkChatSetting.Lark_GroupPhoto_Type_AvatarStack_Mobile_Option
        tipView.textColor = UIColor.ud.textPlaceholder
        tipView.font = .systemFont(ofSize: 14, weight: .medium)
        tipView.numberOfLines = 0
        tipView.textAlignment = .center
        return tipView
    }()

    let jointAvatarEnable: Bool
    init(jointAvatarEnable: Bool) {
        self.jointAvatarEnable = jointAvatarEnable
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        addSubview(imageCircularView)
        addSubview(imageTipView)
        addSubview(textCircularView)
        addSubview(textTipView)

        imageCircularView.snp.makeConstraints {
            $0.left.top.equalToSuperview()
        }

        imageTipView.snp.makeConstraints {
            $0.centerX.equalTo(imageCircularView.snp.centerX)
            $0.left.greaterThanOrEqualTo(imageCircularView.snp.left)
            $0.right.lessThanOrEqualTo(imageCircularView.snp.right)
            $0.top.equalTo(imageCircularView.snp.bottom).offset(AvatarEntryBarLayout.verticalSpacing)
            $0.bottom.lessThanOrEqualToSuperview()
        }

        if self.jointAvatarEnable {
            addSubview(jointImageCircularView)
            addSubview(jointTipView)
            textCircularView.snp.makeConstraints {
                $0.left.equalTo(imageCircularView.snp.right).offset(AvatarEntryBarLayout.horizontalSpacing)
                $0.top.equalToSuperview()
            }

            textTipView.snp.makeConstraints {
                $0.centerX.equalTo(textCircularView.snp.centerX)
                $0.left.greaterThanOrEqualTo(textCircularView.snp.left)
                $0.right.lessThanOrEqualTo(textCircularView.snp.right)
                $0.top.equalTo(textCircularView.snp.bottom).offset(AvatarEntryBarLayout.verticalSpacing)
                $0.bottom.lessThanOrEqualToSuperview()
            }
            jointImageCircularView.snp.makeConstraints {
                $0.left.equalTo(textCircularView.snp.right).offset(AvatarEntryBarLayout.horizontalSpacing)
                $0.top.right.equalToSuperview()
            }

            jointTipView.snp.makeConstraints {
                $0.centerX.equalTo(jointImageCircularView.snp.centerX)
                $0.left.greaterThanOrEqualTo(jointImageCircularView.snp.left)
                $0.right.lessThanOrEqualTo(jointImageCircularView.snp.right)
                $0.top.equalTo(jointImageCircularView.snp.bottom).offset(AvatarEntryBarLayout.verticalSpacing)
                $0.bottom.lessThanOrEqualToSuperview()
            }

        } else {
            textCircularView.snp.makeConstraints {
                $0.left.equalTo(imageCircularView.snp.right).offset(AvatarEntryBarLayout.horizontalSpacing)
                $0.top.right.equalToSuperview()
            }

            textTipView.snp.makeConstraints {
                $0.centerX.equalTo(textCircularView.snp.centerX)
                $0.left.greaterThanOrEqualTo(textCircularView.snp.left)
                $0.right.lessThanOrEqualTo(textCircularView.snp.right)
                $0.top.equalTo(textCircularView.snp.bottom).offset(AvatarEntryBarLayout.verticalSpacing)
                $0.bottom.lessThanOrEqualToSuperview()
            }
        }
    }

}
