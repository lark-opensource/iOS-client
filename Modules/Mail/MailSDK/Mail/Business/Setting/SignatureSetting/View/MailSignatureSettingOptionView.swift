//
//  MailSignatureSettingOptionView.swift
//  MailSDK
//
//  Created by majx on 2020/1/9.
//

import Foundation
import LarkUIKit
import UniverseDesignCheckBox
import FigmaKit

struct MailSignatureSettingOptionConfig {
    let title: String
    var detail: MailSignatureSettingDetail?
    var showDetail: Bool = true
}

protocol MailSignatureSettingOptionViewDelegate: AnyObject {
    func didClickOption(view: MailSignatureSettingOptionView)
}

enum SignCellType {
    case none
    case mobile
    case pc
}

class MailSignatureSettingOptionView: SquircleView {
    static let DetailViewTag = 10000

    var cellType: SignCellType?
    weak var delegate: MailSignatureSettingOptionViewDelegate?
    var selected: Bool = false {
        didSet {
            checkBox.isSelected = selected
            config.detail?.selected = selected
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    private lazy var checkBox: UDCheckBox = {
        let v = UDCheckBox(boxType: .single, config: UDCheckBoxUIConfig(), tapCallBack: nil)
        return v
    }()
    private lazy var titleLabel: UILabel = UILabel()
    var config: MailSignatureSettingOptionConfig

    init(config: MailSignatureSettingOptionConfig) {
        self.config = config
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let cellType = cellType else {
            return
        }
        switch cellType {
//        case .none:
//            layer.ux.setSmoothCorner(
//                radius: 10,
//                corners: [.topLeft, .topRight],
//                smoothness: .natural
//            )
        case .pc:
            layer.ux.setSmoothCorner(
                radius: 10,
                corners: [.bottomLeft, .bottomRight],
                smoothness: .natural
            )
        default:
            break
        }
    }

    func setupViews() {
        backgroundColor = UIColor.ud.bgFloat
        addSubview(titleLabel)
        addSubview(checkBox)
        /// add content view
        var contentView: UIView?
        if let myContentView = config.detail?.contentView,
            let contentHeight = config.detail?.contentHeight {
            contentView = myContentView
            contentView?.tag = MailSignatureSettingOptionView.DetailViewTag
            addSubview(myContentView)
            contentView?.snp.makeConstraints { (make) in
                make.left.equalTo(46)
                make.right.equalTo(-16)
                make.height.equalTo(contentHeight)
                make.bottom.equalTo(-16)
            }
            contentView = myContentView
        }

        titleLabel.text = config.title
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(44)
            make.top.equalTo(16)
            make.right.equalTo(-16)
            if let contentView = contentView {
                make.bottom.equalTo(contentView.snp.top).offset(-16)
            } else {
                make.bottom.equalTo(-16)
            }
        }
        checkBox.isUserInteractionEnabled = false
        checkBox.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(LKCheckbox.Layout.iconMidSize)
        }

//        if cellType == .pc {
//            let topSeparator = UIView()
//            topSeparator.backgroundColor = UIColor.ud.lineDividerDefault
//            addSubview(topSeparator)
//            topSeparator.snp.makeConstraints { (make) in
//                make.left.equalTo(48)
//                make.right.top.equalTo(0)
//                make.height.equalTo(0.5)
//            }
//        } else if cellType == .mobile {
//            let bottomSeparator = UIView()
//            bottomSeparator.backgroundColor = UIColor.ud.lineDividerDefault
//            addSubview(bottomSeparator)
//            bottomSeparator.snp.makeConstraints { (make) in
//                make.left.equalTo(48)
//                make.right.bottom.equalTo(0)
//                make.height.equalTo(0.5)
//            }
//        }

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onClick))
        self.addGestureRecognizer(tapRecognizer)
    }

    func getConfig() -> MailSignatureSettingOptionConfig {
        return config
    }

    func update(signature: String?) {
        DispatchQueue.main.async {
            self.config.detail?.signature = signature ?? ""
            if let contentView = self.viewWithTag(MailSignatureSettingOptionView.DetailViewTag),
                contentView == self.config.detail?.contentView,
                let contentHeight = self.config.detail?.contentHeight {
                contentView.snp.updateConstraints { (make) in
                    make.height.equalTo(contentHeight)
                }
                contentView.layoutIfNeeded()
            }
        }
    }

    func update(newHeight: CGFloat) {
        var newHeight = newHeight
        if config.detail?.signature.isEmpty == true {
            newHeight = 32
        }
        DispatchQueue.main.async {
            if let contentView = self.viewWithTag(MailSignatureSettingOptionView.DetailViewTag),
                contentView == self.config.detail?.contentView {
                _ = self.config.detail?.updateHeight(newHeight: newHeight)
                contentView.snp.updateConstraints { (make) in
                    make.height.equalTo(newHeight)
                }
                contentView.layoutIfNeeded()
            }
        }
    }

    func showPreview(_ show: Bool) {
        DispatchQueue.main.async {
            if self.config.showDetail == show {
                return
            }
            self.config.showDetail = show
            if let contentView = self.viewWithTag(MailSignatureSettingOptionView.DetailViewTag) {
                contentView.isHidden = !show
                self.titleLabel.snp.remakeConstraints { (make) in
                    make.left.equalTo(44)
                    make.top.equalTo(16)
                    make.right.equalTo(-16)
                    if show {
                        make.bottom.equalTo(contentView.snp.top).offset(-16)
                    } else {
                        make.bottom.equalTo(-16)
                    }
                }
                self.layoutIfNeeded()
            }
        }
    }

    @objc
    func onClick() {
        delegate?.didClickOption(view: self)
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        titleLabel.sizeToFit()
        var height = titleLabel.frame.maxY + 16
        if let detail = self.config.detail, self.config.showDetail {
            height += detail.contentHeight + 16
        }
        return CGSize(width: size.width, height: height)
    }
}
