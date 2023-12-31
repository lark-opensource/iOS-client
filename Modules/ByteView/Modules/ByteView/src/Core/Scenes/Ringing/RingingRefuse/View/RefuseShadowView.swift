//
//  RefuseShadowView.swift
//  ByteView
//
//  Created by wangpeiran on 2023/3/19.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import SnapKit

protocol RefuseShadowViewDelegate: AnyObject {
    func refuseShadowPanGesture(_ sender: UIPanGestureRecognizer)
}

class RefuseShadowView: UIView {

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.bgFloatPush
        view.layer.shadowOpacity = 1.0
        view.layer.shadowRadius = 24
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.ud.setShadow(type: .s5Down)
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var visualEffectView: UIVisualEffectView = {
        let veView = UIVisualEffectView()
        veView.effect = UIBlurEffect(style: .regular)
        veView.layer.masksToBounds = true
        veView.layer.cornerRadius = 12
        return veView
    }()

    weak var delegate: RefuseShadowViewDelegate?

    init(delegate: RefuseShadowViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView(needPan: Bool = true) {
        if needPan {
            let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            self.addGestureRecognizer(panRecognizer)
        }
        addSubview(visualEffectView)
        addSubview(containerView)
        visualEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// 滑动手势
    @objc
    func handlePan(_ sender: UIPanGestureRecognizer) {
        self.delegate?.refuseShadowPanGesture(sender)
    }
}


class RefuseNoticeView: RefuseShadowView {
    private lazy var callImageView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.callEndFilled, iconColor: .ud.iconN3, size: CGSize(width: 24, height: 24))
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_CallDeclined
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        label.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_SendAMessageOption
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }()

    private lazy var arrowView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.rightOutlined, iconColor: .ud.iconN3, size: CGSize(width: 14, height: 14))
        return view
    }()

    private lazy var pressButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        return button
    }()

    var tapBlock: (() -> Void)?

    // disable-lint: duplicated code
    override func setupView(needPan: Bool = true) {
        super.setupView()

        containerView.addSubview(callImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(arrowView)
        containerView.addSubview(pressButton)

        callImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(24)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(callImageView.snp.right).offset(10)
            make.height.equalTo(22)
            make.centerY.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.right).offset(16)
            make.height.equalTo(22)
            make.centerY.equalToSuperview()
        }

        arrowView.snp.makeConstraints { (make) in
            make.left.equalTo(subtitleLabel.snp.right).offset(2)
            make.right.equalToSuperview().offset(-12)
            make.size.equalTo(14)
            make.centerY.equalToSuperview()
        }

        pressButton.snp.makeConstraints { (make) in
            make.left.equalTo(subtitleLabel.snp.left)
            make.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }
    // enable-lint: duplicated code

    @objc func handleTap() {
        Logger.ringRefuse.info("handle tap")
        tapBlock?()
    }
}

class RefuseResView: RefuseShadowView {

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.succeedColorful, size: CGSize(width: 20, height: 20))
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        label.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        return label
    }()

    var isSuccess: Bool = true {
        didSet {
            let icon: UniverseDesignIcon.UDIconType = isSuccess ? .succeedColorful : .errorColorful
            iconView.image = UDIcon.getIconByKey(icon, size: CGSize(width: 20, height: 20))
        }
    }

    override func setupView(needPan: Bool = true) {
        super.setupView()
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)

        iconView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(17)
            make.size.equalTo(20)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.right.top.bottom.equalToSuperview().inset(16)
        }
    }

    func setTitle(_ title: String, isSuccess: Bool) {
        titleLabel.attributedText = NSAttributedString(string: title, config: .body)
        self.isSuccess = isSuccess
        self.setNeedsUpdateConstraints()
    }
}
