//
//  SnsContentPasteController.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/3/12.
//

import UIKit
import Foundation
import UniverseDesignColor
import RxSwift
import RxCocoa
import SnapKit
import LarkExtensions
import AsyncComponent

// ignore magic number checking for UI
// disable-lint: magic number

public struct PanelConfig {
    /// 实际拷贝的内容
    let copyContent: String
    let title: String
    /// 粘贴面板展示的内容
    let displayContent: String
    let ctaButtonIcon: UIImage
    let ctaButtonTitle: String
    let ctaButtonTitleColor: UIColor
    let ctaButtonBackgroundColor: UIColor
    let ctaButtonHightlightColor: UIColor
    let skipButtonTitle: String
    let contentAlignment: NSTextAlignment
    var autoOperationHandler: ((SnsOperationTipPanel) -> Void)?
    var ctaButtonDidClick: ((SnsOperationTipPanel) -> Void)?
    var skipButtonDidClick: ((SnsOperationTipPanel) -> Void)?

    public init(copyContent: String,
                title: String,
                displayContent: String,
                ctaButtonIcon: UIImage,
                ctaButtonTitle: String,
                ctaButtonTitleColor: UIColor,
                ctaButtonBackgroundColor: UIColor,
                ctaButtonHightlightColor: UIColor,
                skipButtonTitle: String,
                contentAlignment: NSTextAlignment = .left,
                autoOperationHandler: ((SnsOperationTipPanel) -> Void)? = nil,
                ctaButtonDidClick: ((SnsOperationTipPanel) -> Void)? = nil,
                skipButtonDidClick: ((SnsOperationTipPanel) -> Void)? = nil) {
        self.copyContent = copyContent
        self.title = title
        self.displayContent = displayContent
        self.ctaButtonIcon = ctaButtonIcon
        self.ctaButtonTitle = ctaButtonTitle
        self.ctaButtonTitleColor = ctaButtonTitleColor
        self.ctaButtonBackgroundColor = ctaButtonBackgroundColor
        self.ctaButtonHightlightColor = ctaButtonHightlightColor
        self.skipButtonTitle = skipButtonTitle
        self.contentAlignment = contentAlignment
        self.autoOperationHandler = autoOperationHandler
        self.ctaButtonDidClick = ctaButtonDidClick
        self.skipButtonDidClick = skipButtonDidClick
    }
}

public class SnsOperationTipPanel: UIViewController {
    private let panelConfig: PanelConfig
    private let transition = LarkShareActionSheetTransition()
    private var cancelEnable: Bool = true
    private let disposeBag = DisposeBag()

    public init(panelConfig: PanelConfig) {
        self.panelConfig = panelConfig
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = transition
        self.modalPresentationStyle = .custom
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        layoutPageSubviews()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startShowAnimation()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        panelConfig.autoOperationHandler?(self)
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let handler = panelConfig.skipButtonDidClick {
            handler(self)
        } else {
            dismiss()
        }
    }

    public func dismiss() {
        startDismissAnimation {
            self.dismiss(animated: false, completion: nil)
        }
    }

    private lazy var container: UIControl = {
        let view = UIControl()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = 8.0
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var pasteTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.numberOfLines = 1
        label.text = self.panelConfig.title
        return label
    }()

    private lazy var pasteContentView: UITextView = {
        let view = UITextView(frame: .zero)
        view.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        view.backgroundColor = UIColor.ud.bgFloatOverlay
        view.textColor = UIColor.ud.textCaption
        view.textAlignment = panelConfig.contentAlignment
        view.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        view.isScrollEnabled = false
        view.isEditable = false
        let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
                paragraphStyle.lineBreakMode = .byWordWrapping
        view.attributedText =
            NSAttributedString(
                string: self.panelConfig.displayContent,
                attributes: [
                    .paragraphStyle: paragraphStyle,
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.ud.textCaption
                ]
            )
        return view
    }()

    private lazy var ctaIconView: UIImageView = {
        let view = UIImageView()
        view.image = self.panelConfig.ctaButtonIcon
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var ctaTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = self.panelConfig.ctaButtonTitleColor
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 1
        label.text = self.panelConfig.ctaButtonTitle
        return label
    }()

    private lazy var ctaContainer: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var ctaButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage.lu.fromColor(self.panelConfig.ctaButtonBackgroundColor), for: .normal)
        button.setBackgroundImage(UIImage.lu.fromColor(self.panelConfig.ctaButtonHightlightColor), for: .highlighted)
        button.layer.cornerRadius = 6.0
        button.layer.masksToBounds = true
        button.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            if let handler = self.panelConfig.ctaButtonDidClick {
                handler(self)
            } else {
                self.dismiss()
            }
        }).disposed(by: self.disposeBag)
        return button
    }()

    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.setTitleColor(UIColor.ud.textCaption, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        button.setTitle(self.panelConfig.skipButtonTitle, for: .normal)
        button.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            if let handler = self.panelConfig.skipButtonDidClick {
                handler(self)
            } else {
                self.dismiss()
            }
        }).disposed(by: self.disposeBag)
        return button
    }()
}

private extension SnsOperationTipPanel {
    func layoutPageSubviews() {
        view.addSubview(container)
        container.addSubview(pasteTitleLabel)
        container.addSubview(pasteContentView)
        container.addSubview(ctaButton)
        ctaButton.addSubview(ctaContainer)
        ctaContainer.addSubview(ctaIconView)
        ctaContainer.addSubview(ctaTitleLabel)
        container.addSubview(skipButton)

        container.snp.makeConstraints { (make) in
            make.width.equalTo(300).priority(.high)
            make.leading.greaterThanOrEqualToSuperview().offset(32).priority(.required)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        view.layoutIfNeeded()
        pasteTitleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(24)
        }
        let unlimitSize = CGSize(width: container.frame.width - 60, height: CGFloat.greatestFiniteMagnitude)
        let limitSize = CGSize(width: container.frame.width - 60, height: 0.6 * view.frame.width)
        let unlimitContentSize = pasteContentView.attributedText.componentTextSize(for: unlimitSize, limitedToNumberOfLines: Int.max)
        let limitContentSize = pasteContentView.attributedText.componentTextSize(for: limitSize, limitedToNumberOfLines: Int.max)
        // 如果未限制的高度仍然大于限制后的计算高度，此时允许文本框进行滑动翻阅
        if unlimitContentSize.height > limitContentSize.height + 20 {
            pasteContentView.isScrollEnabled = true
        }
        pasteContentView.snp.makeConstraints { (make) in
            let topMargin = self.panelConfig.displayContent.isEmpty ? 0 : 12
            make.top.equalTo(pasteTitleLabel.snp.bottom).offset(topMargin)
            make.leading.trailing.equalToSuperview().inset(20)
            let minHeightLimit = self.panelConfig.displayContent.isEmpty ? 0 : max(CGFloat(110), limitContentSize.height + 20)
            make.height.equalTo(minHeightLimit)
        }
        ctaButton.snp.makeConstraints { (make) in
            make.top.equalTo(pasteContentView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }
        ctaContainer.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        ctaIconView.snp.makeConstraints { (make) in
            make.leading.top.bottom.equalToSuperview()
            make.width.height.equalTo(20)
        }
        ctaTitleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(ctaIconView.snp.trailing).offset(4)
            make.trailing.centerY.equalToSuperview()
        }
        skipButton.snp.makeConstraints { (make) in
            make.top.equalTo(ctaButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(32)
            make.bottom.equalToSuperview().inset(12)
        }
    }

    func startShowAnimation() {
        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.duration = 0.35
        animation.values = [NSValue(caTransform3D: CATransform3DMakeScale(0.0001, 0.0001, 1.0)),
                            NSValue(caTransform3D: CATransform3DMakeScale(1.05, 1.05, 1.0)),
                            NSValue(caTransform3D: CATransform3DMakeScale(0.95, 0.95, 1.0)),
                            NSValue(caTransform3D: CATransform3DIdentity)]
        animation.keyTimes = [0, 0.6, 0.8, 1.0]
        animation.timingFunctions = [CAMediaTimingFunction(name: .easeInEaseOut),
                                     CAMediaTimingFunction(name: .easeInEaseOut),
                                     CAMediaTimingFunction(name: .easeInEaseOut)]
        container.layer.add(animation, forKey: "showAnimation")
    }

    func startDismissAnimation(_ completion: @escaping () -> Void) {
        guard cancelEnable else { return }
        cancelEnable = false
        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.duration = 0.35
        animation.values = [NSValue(caTransform3D: CATransform3DIdentity),
                            NSValue(caTransform3D: CATransform3DMakeScale(1.05, 1.05, 1.0)),
                            NSValue(caTransform3D: CATransform3DMakeScale(0.0001, 0.0001, 1.0))]
        animation.keyTimes = [0, 0.3, 1.0]
        animation.timingFunctions = [CAMediaTimingFunction(name: .easeInEaseOut),
                                     CAMediaTimingFunction(name: .easeInEaseOut)]
        container.layer.add(animation, forKey: "dismissAnimation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.cancelEnable = true
            completion()
        }
    }
}
