//
//  OPBlockTypeUsageStatusView.swift
//  OPBlock
//
//  Created by chenziyi on 2021/10/20.
//

import Foundation
import LarkUIKit
import UniverseDesignIcon
import EENavigator
import LarkContainer

class HighlightButton: UIButton {
    var highlightColor: UIColor?
    var normalBackgroundColor: UIColor? {
        didSet {
            backgroundColor = normalBackgroundColor
        }
    }
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? highlightColor : normalBackgroundColor
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        highlightColor = backgroundColor
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class OPBlockTypeUsageStatusView: UIView {

    lazy var titleView: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.baselineAdjustment = .alignCenters
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 2

        return label
    }()

    lazy var buttonView: HighlightButton = {
        let button = HighlightButton(type: .custom)
        button.layer.cornerRadius = 5

        button.highlightColor = UIColor.dynamic(light: UIColor.ud.primaryContentDefault, dark: UIColor.ud.udtokenBtnSeBgPriHover.withAlphaComponent(0.2))
        button.normalBackgroundColor = UIColor.dynamic(light: UIColor.ud.primaryContentDefault, dark: UIColor.ud.bgFloat)

        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor

        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgFloat
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class OPBlockImageStatusView: OPBlockTypeUsageStatusView {
    private var viewItem: GuideInfoStatusViewItem
    private var url: URL?

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = viewItem.imageType?.image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        return imageView
    }()

    private let userResolver: UserResolver

    /// 有图模式
    init(frame: CGRect, data: GuideInfoStatusViewItem, userResolver: UserResolver) {
        self.viewItem = data
        self.userResolver = userResolver
        super.init(frame: frame)

        guard let _ = data.imageType else {
            self.viewItem.imageType = .default_error
            return
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        guard let superview = newSuperview else {
            imageView.removeFromSuperview()
            titleView.removeFromSuperview()

            if let _ = viewItem.button {
                buttonView.removeFromSuperview()
            }
            return
        }
        addSubviews()
        setupSubviews(superView: superview)
    }

    private func addSubviews() {
        addSubview(imageView)
        addSubview(titleView)

        if let _ = viewItem.button {
            addSubview(buttonView)
        }
    }

    private func setupSubviews(superView: UIView) {
        let superViewHeight = superView.frame.height
        let imageHeight = (superViewHeight / 4) > 128 ? 128 : (superViewHeight / 4)

        imageView.snp.makeConstraints {(make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(superViewHeight / 2)
            make.width.height.equalTo(imageHeight)
        }

        titleView.text = viewItem.displayMsg
        titleView.textColor = UIColor.ud.textCaption
        titleView.textAlignment = .center

        titleView.snp.makeConstraints {(make) in
            make.top.equalTo(imageView.snp.bottom).inset(-10)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().dividedBy(1.5)
            make.height.equalTo(40)
        }

        if let button = viewItem.button {
            buttonView.setTitle(button.title, for: .normal)
            buttonView.setTitleColor(UIColor.dynamic(light: UIColor.ud.primaryOnPrimaryFill, dark: UIColor.ud.primaryContentDefault), for: .normal)
            buttonView.titleLabel?.font = UIFont.systemFont(ofSize: 12)

            buttonView.snp.makeConstraints {(make) in
                make.top.equalTo(titleView.snp.bottom).inset(-10)
                make.centerX.equalToSuperview()
                make.width.equalTo(70)
                make.height.equalTo(30)
            }
            self.url = URL(string: button.schema)
            buttonView.addTarget(self, action: #selector(onClickToApply), for: .touchUpInside)
        }
    }
    @objc func onClickToApply() {
        guard let url = self.url else {
            return
        }
        let navigator = userResolver.navigator
        if let fromVC = navigator.mainSceneWindow?.fromViewController {
            navigator.push(url, from: fromVC)
        }
    }
}

class OPBlockTextStatusView: OPBlockTypeUsageStatusView {
    private var viewItem: GuideInfoStatusViewItem
    private var url: URL?
    private let userResolver: UserResolver

    init(frame: CGRect, data: GuideInfoStatusViewItem, userResolver: UserResolver) {
        self.viewItem = data
        self.userResolver = userResolver
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviews() {
        addSubview(titleView)
        if viewItem.button != nil && !viewItem.isSimple {
            addSubview(buttonView)
        }
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        guard let superview = newSuperview else {
            titleView.removeFromSuperview()
            if viewItem.button != nil && !viewItem.isSimple {
                buttonView.removeFromSuperview()
            }
            return
        }
        addSubviews()
        setupSubviews(superView: superview)
    }

    private func setupSubviews(superView: UIView) {
        titleView.text = viewItem.displayMsg
        titleView.textColor = UIColor.ud.textCaption
        titleView.textAlignment = .center

        titleView.snp.makeConstraints {(make) in
            make.centerX.centerY.equalToSuperview()
            make.width.equalToSuperview().dividedBy(1.5)
            make.height.equalTo(40)
        }

        if !viewItem.isSimple {
            if let button = viewItem.button {
                buttonView.setTitle(button.title, for: .normal)
                buttonView.setTitleColor(UIColor.dynamic(light: UIColor.ud.primaryOnPrimaryFill, dark: UIColor.ud.primaryContentDefault), for: .normal)
                buttonView.titleLabel?.font = UIFont.systemFont(ofSize: 12)

                buttonView.snp.makeConstraints {(make) in
                    make.top.equalTo(titleView.snp.bottom).inset(-10)
                    make.centerX.equalToSuperview()
                    make.width.equalTo(70)
                    make.height.equalTo(30)
                }

                self.url = URL(string: button.schema)
                buttonView.addTarget(self, action: #selector(onClickToApply), for: .touchUpInside)
            }
        }
    }
    @objc func onClickToApply() {
        guard let url = self.url else {
            return
        }
        let navigator = userResolver.navigator
        if let fromVC = navigator.mainSceneWindow?.fromViewController {
            navigator.push(url, from: fromVC)
        }
    }
}
