//
//  GuideLineLayerDemo.swift
//  Action
//
//  Created by sniperj on 2018/12/13.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor

public final class GuideAtUserView: UIView {
    public struct Animation {
        var enabled: Bool = true
        var duration: (CFTimeInterval, CFTimeInterval, CFTimeInterval) = (0.25, 0.25, 0.25)
    }

    public var animation = Animation()
    public var startPoint: CGPoint = CGPoint.zero

    public var clickBlock: ((GuideAtUserView) -> Void)?

    internal var contentText: String

    internal var buttonText: String

    fileprivate lazy var textSize: CGSize = {
        var attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]

        var textSize = self.contentText.boundingRect(with: CGSize(width: self.maxWitdh,
                                                                  height: CGFloat.greatestFiniteMagnitude),
                                                     options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                                     attributes: attributes, context: nil).size

        textSize.width = ceil(textSize.width)
        textSize.height = ceil(textSize.height)

        if textSize.width < self.confirmButton.frame.size.width {
            textSize.width = self.confirmButton.frame.size.width
        }

        return textSize
    }()

    fileprivate lazy var contentSize: CGSize = {
        var contentSize = CGSize(width: 240, height: self.textSize.height + 72)

        return contentSize
    }()

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.color(177, 177, 177)
        label.numberOfLines = 0
        return label
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.bounds = CGRect(x: 0, y: 0, width: 80, height: 28)
        button.setTitle(self.buttonText, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.titleLabel?.textAlignment = .center
        button.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        button.layer.masksToBounds = true
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UIColor.ud.color(54, 134, 255))
        button.layer.cornerRadius = 4
        button.addTarget(self, action: #selector(clickConfirm), for: .touchUpInside)
        return button
    }()

    fileprivate lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        view.layer.cornerRadius = 6
        return view
    }()

    public var contentLabelText: String?

    public var lineColor = UIColor.ud.primaryOnPrimaryFill
    public var pointColor = UIColor.ud.primaryOnPrimaryFill
    public var pointWidth: CGFloat = 4
    public var lineWidth: CGFloat = 1
    public var lineLength: CGFloat = 23
    public var startPointOffset: CGFloat = 0

    public var maxWitdh: CGFloat = 215

    fileprivate var pointView: UIView = UIView()
    fileprivate var lineLayer: UIView = UIView()

    fileprivate var offset: CGFloat = 6

    private var canvasSize: CGSize

    public init(contentText: String = "",
                buttonText: String = "",
                canvasSize: CGSize = UIScreen.main.bounds.size) {
        self.canvasSize = canvasSize
        self.contentText = contentText
        self.buttonText = buttonText
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.clear
        self.initSubViews()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initSubViews() {
        self.addSubview(self.lineLayer)
        self.addSubview(self.pointView)
        self.addSubview(self.contentView)
    }

    public func show(text: String, startPoint: CGPoint, superView: UIView?) {
        clearSubviews()

        self.contentText = text
        self.contentLabel.text = self.contentText
        self.startPoint = startPoint

        updateSubviews()
        updatePointAndLine()

        superView?.addSubview(self)

        self.showAnimationIfNeed()
    }

    private func clearSubviews() {
        self.removeFromSuperview()
    }

    public func show(text: String, superView: UIView?) {
        self.contentText = text
        self.contentLabel.text = self.contentText

        updateSubviews()
        updatePointAndLine()
        superView?.addSubview(self)
        self.showAnimationIfNeed()
    }

    private func updateSubviews() {
        updatePointAndLine()
        updateContenView()
        self.frame = CGRect(x: 0,
                            y: 0,
                            width: canvasSize.width,
                            height: canvasSize.height)
    }

    private func updatePointAndLine() {
        self.pointView.layer.cornerRadius = self.pointWidth / 2
        self.pointView.layer.masksToBounds = true
        self.pointView.backgroundColor = self.pointColor
        self.pointView.bounds = CGRect(x: 0,
                                       y: 0,
                                       width: self.pointWidth,
                                       height: self.pointWidth)
        self.pointView.center = self.startPoint

        self.lineLayer.backgroundColor = self.lineColor
        self.lineLayer.frame = CGRect(x: self.pointView.frame.minX - self.lineLength,
                                      y: self.pointView.frame.minY + (self.pointView.frame.height - self.lineWidth) / 2,
                                      width: self.lineLength,
                                      height: self.lineWidth)
    }

    private func updateContenView() {
        self.contentView.addSubview(self.confirmButton)
        self.contentView.addSubview(self.contentLabel)

        if self.startPoint.y - 30 <= 0 {
            self.contentView.frame = CGRect(x: self.lineLayer.frame.minX - contentSize.width,
                                            y: 0,
                                            width: contentSize.width,
                                            height: contentSize.height)
        } else if self.startPoint.y + contentSize.height - 30 >= canvasSize.height {
            self.contentView.frame = CGRect(x: self.lineLayer.frame.minX - contentSize.width,
                                            y: canvasSize.height - contentSize.height,
                                            width: contentSize.width,
                                            height: contentSize.height)
        } else {
            self.contentView.frame = CGRect(x: self.lineLayer.frame.minX - contentSize.width,
                                            y: self.lineLayer.frame.minY - 30,
                                            width: contentSize.width,
                                            height: contentSize.height)
        }
        self.contentLabel.snp.makeConstraints { [weak self] (make) in
            make.width.equalTo(self!.textSize.width)
            make.height.equalTo(self!.textSize.height)
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
        }

        self.confirmButton.snp.makeConstraints { [weak self] (make) in
            make.width.equalTo(self!.confirmButton.frame.width)
            make.height.equalTo(self!.confirmButton.frame.height)
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(self!.contentLabel.snp.bottom).offset(16)
        }
    }

    private func showAnimationIfNeed() {
        if !self.animation.enabled {
            return
        }

        setupLineLayer()

        let animationDurations = self.animation.duration

        let animation1 = BaseAnimationItem { [weak self] cb in
            guard let `self` = self else { return }
            UIView.animate(withDuration: animationDurations.0, animations: {
                self.pointView.alpha = 1
            }) { (_) in
                cb()
            }
        }

        let animation2 = BaseAnimationItem { [weak self] cb in
            guard let `self` = self else { return }

            UIView.animate(withDuration: animationDurations.1, animations: {
                self.lineLayer.frame = CGRect(x: self.pointView.frame.minX - self.lineLength,
                                              y: self.lineLayer.frame.minY,
                                              width: self.lineLength,
                                              height: self.lineLayer.frame.height)
            }) { (_) in
                cb()
            }
        }

        let animation3 = BaseAnimationItem { [weak self] cb in
            guard let `self` = self else { return }
            UIView.animate(withDuration: animationDurations.2, animations: {
                self.contentView.alpha = 1
            }) { (_) in
                cb()
            }
        }

        AnimationQueue().add(animation1).add(animation2).add(animation3).start()
    }

    private func setupLineLayer() {
        self.pointView.alpha = 0
        self.contentView.alpha = 0
        self.lineLayer.frame = CGRect(x: self.lineLayer.frame.minX + self.lineLength,
                                      y: self.lineLayer.frame.minY,
                                      width: 0,
                                      height: self.lineLayer.frame.height)
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)

        if hitView == self {
            return nil
        }

        return hitView
    }

    @objc
    private func clickConfirm() {
        self.clickBlock?(self)
        self.removeFromSuperview()
    }
}
