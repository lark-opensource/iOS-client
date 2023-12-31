//
//  FlodChatterView.swift
//  LarkMessageCore
//
//  Created by Bytedance on 2022/9/23.
//

import Foundation
import UIKit
import LarkBizAvatar

/// 头像、名字、数量标识，方便渲染时查找，做复用逻辑
let FlodChatterAvatarTag: Int = 100_001
let FlodChatterNameTag: Int = 100_002
let FlodChatterNumberTag: Int = 100_003
let FlodChatterTag: Int = 100_004

/// 回调给业务方点击事件
public protocol FlodChatterViewDelegate: AnyObject {
    /// 点击了某个chatter的头像/名字/数量
    func didTapChatter(_ flodChatterView: FlodChatterView, chatter: FlodChatter)
    /// 点击了flodChatterView除chatter外的其他区域
    func didTapFlodChatterView(_ flodChatterView: FlodChatterView)
}

/// 展示所有聚合的人的列表
public final class FlodChatterView: UIView {
    /// 绘制出头像、名称、数字的边框
    var debugModel: Bool = false
    /// 所有渲染的的Chatter、ChatterFrame
    private var chatters: [FlodChatter] = []
    private var chatterFrames: [FlodChatterFrame] = []

    /// 回调给业务方点击事件
    weak var delegate: FlodChatterViewDelegate?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        // 添加点击事件，回调给业务方
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapFlodChatterView(tapGestureRecognizer:)))
        self.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc
    private func tapFlodChatterView(tapGestureRecognizer: UITapGestureRecognizer) {
        guard self.chatters.count == self.chatterFrames.count else {
            assertionFailure("chatters.count != chatterFrames.count")
            return
        }

        let tapPoint = tapGestureRecognizer.location(in: self)
        // 判断是否点击了某个chatterFrame
        if let index = self.chatterFrames.firstIndex { $0.contentFrame.contains(tapPoint) } {
            // 回调didTapChatter
            self.delegate?.didTapChatter(self, chatter: self.chatters[index])
            return
        }

        // 回调didTapFlodChatterView
        self.delegate?.didTapFlodChatterView(self)
    }

    private func createChatterView() -> UIView {
        let chatterView = UIView()
        chatterView.isUserInteractionEnabled = false
        chatterView.tag = FlodChatterTag
        chatterView.isHidden = false
        chatterView.layer.borderWidth = 1
        chatterView.layer.borderColor = UIColor.ud.red.cgColor
        return chatterView
    }

    private func createAvatarView() -> BizAvatar {
        let imageView = BizAvatar()
        imageView.isUserInteractionEnabled = false
        imageView.tag = FlodChatterAvatarTag
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 10
        if self.debugModel {
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = UIColor.ud.red.cgColor
        }
        return imageView
    }

    private func createNameView() -> UILabel {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.tag = FlodChatterNameTag
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textCaption
        if self.debugModel {
            label.layer.borderWidth = 1
            label.layer.borderColor = UIColor.ud.red.cgColor
        }
        return label
    }

    private func createNumberView() -> UILabel {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.tag = FlodChatterNumberTag
        label.font = FlodChatterFrame.numberLabelFont
        label.textColor = UIColor.ud.colorfulOrange
        if self.debugModel {
            label.layer.borderWidth = 1
            label.layer.borderColor = UIColor.ud.red.cgColor
        }
        return label
    }

    /// 根据给定的chatters信息渲染界面
    func setup(chatters: [FlodChatter], chatterFrames: [FlodChatterFrame]) {
        guard chatters.count == chatterFrames.count else {
            return
        }

        // 为了减少subView创建销毁的次数，把已存在的subView做复用处理
        var avatarCacheViews: [BizAvatar] = []; var nameCacheViews: [UILabel] = []; var numberCacheViews: [UILabel] = []
        // debug模式下，绘制chatter占用的size
        var chatterCacheViews: [UIView] = []
        self.subviews.forEach { subView in
            if subView.tag == FlodChatterAvatarTag, let avatarView = subView as? BizAvatar {
                avatarCacheViews.append(avatarView)
                return
            }
            if subView.tag == FlodChatterNameTag, let nameView = subView as? UILabel {
                nameCacheViews.append(nameView)
                return
            }
            if subView.tag == FlodChatterNumberTag, let numberView = subView as? UILabel {
                numberCacheViews.append(numberView)
                return
            }
            // debug模式下，绘制chatter占用的size
            if subView.tag == FlodChatterTag {
                chatterCacheViews.append(subView)
                return
            }
            // 出现了无法识别的subView
            assertionFailure("subView tag unrecognized")
        }

        // 重置，先让subView处于隐藏状态
        self.subviews.forEach { $0.isHidden = true }

        // 渲染，根据最新的chatters添加subView
        for index in 0..<chatters.count {
            // 得到当前需要渲染的chatter
            let chatter = chatters[index]; let chatterFrame = chatterFrames[index]
            // debug模式下，绘制chatter占用的size
            if self.debugModel {
                let chatterView = chatterCacheViews.isEmpty ? self.createChatterView() : chatterCacheViews.remove(at: 0)
                chatterView.isHidden = false
                chatterView.frame = chatterFrame.contentFrame
                self.addSubview(chatterView)
            }
            // 添加头像
            let imageView = avatarCacheViews.isEmpty ? self.createAvatarView() : avatarCacheViews.remove(at: 0)
            imageView.isHidden = false
            imageView.setAvatarByIdentifier(chatter.identifier, avatarKey: chatter.avatarKey, avatarViewParams: .init(sizeType: .size(20)))
            imageView.frame = chatterFrame.avatarFrame
            self.addSubview(imageView)
            // 添加名字
            let nameView = nameCacheViews.isEmpty ? self.createNameView() : nameCacheViews.remove(at: 0)
            nameView.isHidden = false
            nameView.frame = chatterFrame.nameFrame
            nameView.text = chatter.name
            self.addSubview(nameView)
            // 如果数字 > 1，才添加数字
            if chatter.number > 1 {
                let numberView = numberCacheViews.isEmpty ? self.createNumberView() : numberCacheViews.remove(at: 0)
                numberView.isHidden = false
                numberView.frame = chatterFrame.numberFrame
                numberView.text = "×\(chatter.number)"
                self.addSubview(numberView)
            }
        }

        // 删除所有未使用的cacheView
        avatarCacheViews.forEach { $0.removeFromSuperview() }
        nameCacheViews.forEach { $0.removeFromSuperview() }
        numberCacheViews.forEach { $0.removeFromSuperview() }
        chatterCacheViews.forEach { $0.removeFromSuperview() }

        // 存储本次渲染的chatter信息
        self.chatters = chatters
        self.chatterFrames = chatterFrames
    }
}
