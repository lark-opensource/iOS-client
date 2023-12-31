//
//  RichTextDialog.swift
//  UGDialog
//
//  Created by ByteDance on 2022/9/16.
//

import UIKit
import Foundation
import LKRichView
import EENavigator
import UniverseDesignDialog
import SwiftUI
import LarkUIKit
import ByteWebImage
import LarkContainer
import LarkDialogManager
import LarkNavigator

public enum DialogButtonDirection {
    case horizontal
    case vertical
}

public final class RichTextDialogLayout {
    public static let horizontalPadding = Display.pad ? 24.0 : 20.0
    public static let verticalPadding = 24.0
    public static let buttonHeight = 48

    public static let dialogEdges = 36.0
    static let baseWidths: (screenWidth: CGFloat, dialogWidth: CGFloat) = (414.0, 303.0)

    public static var dialogWidth: CGFloat {
        if Display.pad {
            return 712.0
        }
        var currentBounds: CGRect
        if let window = UIApplication.shared.delegate?.window {
            currentBounds = window?.bounds ?? UIScreen.main.bounds
        } else {
            currentBounds = UIScreen.main.bounds
        }
        if currentBounds.width >= baseWidths.screenWidth {
            return baseWidths.dialogWidth
        } else {
            // app宽度不足414，弹窗左右边距固定为36
            return currentBounds.width - 2.0 * dialogEdges
        }

    }

    public static var dialogHeight: CGFloat {
        if Display.pad {
            return 680.0
        }
        var currentBounds: CGRect
        if let window = UIApplication.shared.delegate?.window {
            currentBounds = window?.bounds ?? UIScreen.main.bounds
        } else {
            currentBounds = UIScreen.main.bounds
        }
        return currentBounds.height - 2.0 * dialogEdges
    }
}

public final class RichTextDialog: UIViewController, UserResolverWrapper {

    lazy var dialogContainer: UIView = UIView()
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        return label
    }()
    lazy var contentView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    lazy var contentContainer: UIView = UIView()
    lazy var topImageView:ByteImageView = ByteImageView()
    lazy var buttonContainer: UIStackView = UIStackView()
    var richTextView: LKRichView?

    var buttonInfoDict: [UIButton: UGDialogButton] = [:]
    var buttonDirection: DialogButtonDirection

    @ScopedInjectedLazy private var dialogManagerService: DialogManagerService?

    public let userResolver: UserResolver
    public init(userResolver: UserResolver, buttonDirection: DialogButtonDirection = .horizontal) {
        self.userResolver = userResolver
        self.buttonDirection = buttonDirection
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setButtons(buttons: [UGDialogButton]) {
        var datas = buttons
        if buttonDirection == .horizontal {
            datas = datas.reversed()
        }
        for data in datas {
            let button = UIButton(type: .custom)
            button.setTitle(data.buttonTitle, for: .normal)
            let titleColor = data.isMainButton ? (Display.pad ? UIColor.ud.primaryOnPrimaryFill : UIColor.ud.primaryContentDefault) : UIColor.ud.textTitle
            button.setTitleColor(titleColor, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            let image = UIImage.ud.fromPureColor(data.isMainButton && Display.pad ? UIColor.ud.primaryContentDefault : UIColor.ud.bgFloat)
            button.setBackgroundImage(image, for: .normal)
            if Display.pad {
                button.layer.cornerRadius = 4
                button.clipsToBounds = true
                button.layer.borderWidth = 1
                button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
            }
            button.snp.makeConstraints { make in
                make.height.equalTo(RichTextDialogLayout.buttonHeight)
            }
            button.addTarget(self, action: #selector(didTapButton(btn:)), for: .touchUpInside)
            self.buttonInfoDict[button] = data
            buttonContainer.addArrangedSubview(button)
        }
        buttonContainer.spacing = Display.pad ? 16 : 1
        buttonContainer.axis = buttonDirection == .horizontal ? .horizontal : .vertical
        buttonContainer.distribution = .fillEqually
        buttonContainer.backgroundColor = Display.pad ? UIColor.ud.bgFloat : UIColor.ud.lineDividerDefault
        let buttonCount = buttons.count
        let totalHeight = buttonDirection == .horizontal ? RichTextDialogLayout.buttonHeight : buttonCount * RichTextDialogLayout.buttonHeight + buttonCount
        buttonContainer.snp.makeConstraints { make in
            make.height.equalTo(totalHeight)
        }
    }

    @objc
    func didTapButton(btn: UIButton) {
        self.view.backgroundColor = .clear
        let navigator = self.userResolver.navigator
        self.dismiss(animated: true, completion: { [weak self] in
            guard let self = self,
                  let data = self.buttonInfoDict[btn] else { return }
            self.dialogManagerService?.onDismiss()
            if data.needManualCustom,
               let reachPoint = data.reachPoint {
                reachPoint.reportClosed()
            }
            switch data.buttonType {
            case .applink, .url:
                guard let link = data.link,
                      !link.isEmpty,
                      let url = URL(string: link),
                      let window = navigator.mainSceneWindow else {
                    return
                }
                navigator.open(url, from: window)
            case .exitAPP:
                exit(0)
            }
        })
    }

    public func setTitle(title: String) {
        self.titleLabel.text = title
        let width = titleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
        titleLabel.textAlignment = width > RichTextDialogLayout.dialogWidth - 2 * RichTextDialogLayout.horizontalPadding ? .left : .center
    }

    public func setRichTextContent(topImageUrl: String? = nil, richTextView: LKRichView) {
        self.richTextView = richTextView
        let contentWidth = RichTextDialogLayout.dialogWidth - 2 * RichTextDialogLayout.horizontalPadding
        richTextView.preferredMaxLayoutWidth = contentWidth
        let richTextsize = richTextView.intrinsicContentSize
        contentContainer.backgroundColor = UIColor.clear
        let padding = 16.0
        var maxContentHeight = 0.0
        let aspectRatio = 16.0 / 9.0
        if let url = topImageUrl, !url.isEmpty {
            let imageHeight = contentWidth / aspectRatio
            topImageView.clipsToBounds = true
            topImageView.contentMode = .scaleAspectFill
            topImageView.bt.setLarkImage(with: .default(key: url), completion: { [weak self] result in
                switch result {
                case .success(let data):
                    guard let self = self,
                          let image = data.image,
                          image.size.height != 0.0,
                          image.size.width != 0.0 else {
                        return
                    }
                    // 根据图片宽高比计算高度
                    let newImageHeight = contentWidth / (image.size.width / image.size.height)
                    DispatchQueue.main.async {
                        // 更新图片高度
                        self.topImageView.snp.updateConstraints { make in
                            make.height.equalTo(newImageHeight)
                        }
                        maxContentHeight = newImageHeight + padding + richTextsize.height
                        self.contentView.snp.updateConstraints { make in
                            make.height.lessThanOrEqualTo(maxContentHeight).priority(.low)
                        }
                        self.contentView.layoutIfNeeded()
                        self.contentView.isScrollEnabled = self.contentView.frame.height < maxContentHeight
                        self.contentView.contentSize = CGSize(width: richTextsize.width, height: maxContentHeight)
                    }
                case .failure(let error):
                    break
                }
            })
            contentContainer.addSubview(topImageView)
            contentContainer.addSubview(richTextView)
            topImageView.snp.makeConstraints { make in
                make.top.centerX.equalToSuperview()
                make.width.equalTo(contentWidth)
                make.height.equalTo(imageHeight)
            }
            richTextView.snp.makeConstraints { make in
                make.top.equalTo(topImageView.snp.bottom).offset(padding)
                make.centerX.equalToSuperview()
                make.width.equalTo(richTextsize.width)
                make.height.equalTo(richTextsize.height)
            }
            maxContentHeight = imageHeight + padding + richTextsize.height
        } else {
            contentContainer.addSubview(richTextView)
            richTextView.snp.makeConstraints { make in
                make.top.centerX.equalToSuperview()
                make.width.equalTo(richTextsize.width)
                make.height.equalTo(richTextsize.height)
            }
            maxContentHeight = richTextsize.height
        }
        contentView.addSubview(contentContainer)
        contentContainer.snp.makeConstraints { make in
            make.top.width.centerX.equalToSuperview()
            make.bottom.equalTo(richTextView.snp.bottom)
        }
        contentView.snp.makeConstraints { make in
            make.height.lessThanOrEqualTo(maxContentHeight).priority(.low)
        }
        contentView.layoutIfNeeded()
        contentView.isScrollEnabled = contentView.frame.height < maxContentHeight
        contentView.contentSize = CGSize(width: richTextsize.width, height: maxContentHeight)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.4)
        dialogContainer.layer.cornerRadius = 8
        dialogContainer.clipsToBounds = true
        dialogContainer.backgroundColor = UIColor.ud.bgFloat
        view.addSubview(dialogContainer)
        let splitLine = UIView()
        splitLine.backgroundColor = UIColor.ud.lineDividerDefault
        dialogContainer.addSubview(titleLabel)
        dialogContainer.addSubview(contentView)
        dialogContainer.addSubview(splitLine)
        dialogContainer.addSubview(buttonContainer)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(RichTextDialogLayout.verticalPadding)
            make.left.equalTo(RichTextDialogLayout.horizontalPadding)
            make.right.equalTo(-RichTextDialogLayout.horizontalPadding)
        }
        contentView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(RichTextDialogLayout.verticalPadding)
            make.left.right.equalToSuperview()
        }
        let buttonPadding = Display.pad ? 24 : 0
        if !Display.pad {
            splitLine.snp.makeConstraints { make in
                make.top.equalTo(contentView.snp.bottom).offset(RichTextDialogLayout.verticalPadding)
                make.left.equalTo(buttonPadding)
                make.right.equalTo(-buttonPadding)
                make.height.equalTo(1)
            }
            buttonContainer.snp.makeConstraints { make in
                make.top.equalTo(splitLine.snp.bottom)
                make.left.equalTo(buttonPadding)
                make.right.equalTo(-buttonPadding)
            }
            dialogContainer.snp.makeConstraints { make in
                make.bottom.equalTo(buttonContainer)
                make.height.lessThanOrEqualTo(RichTextDialogLayout.dialogHeight - 2 * RichTextDialogLayout.dialogEdges)
                make.width.equalTo(RichTextDialogLayout.dialogWidth)
                make.centerX.centerY.equalToSuperview()
            }
        } else {
            buttonContainer.snp.makeConstraints { make in
                make.top.equalTo(contentView.snp.bottom).offset(RichTextDialogLayout.verticalPadding)
                make.left.equalTo(buttonPadding)
                make.right.equalTo(-buttonPadding)
            }
            dialogContainer.snp.makeConstraints { make in
                make.bottom.equalTo(buttonContainer).offset(RichTextDialogLayout.verticalPadding)
                make.width.equalTo(RichTextDialogLayout.dialogWidth)
                make.centerX.centerY.equalToSuperview()
                make.height.lessThanOrEqualTo(RichTextDialogLayout.dialogHeight)
            }
        }
    }
}
