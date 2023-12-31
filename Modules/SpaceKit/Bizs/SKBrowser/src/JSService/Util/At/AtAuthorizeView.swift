//
//  AtAuthorizeView.swift
//  SpaceKit
//
//  Created by xurunkang on 2018/9/6.
//

import Foundation
import SnapKit
import SKCommon
import SKUIKit
import SKFoundation
import UniverseDesignNotice
import UniverseDesignIcon

// image 通过 base64 的字符串获取
struct AtAuthorizeViewConfig {
    struct Button {
        var id: Int = 0
        var base64Image: String = ""
        var text: String = ""
    }

    var leftButton: Button = Button()
    var rightButton: Button = Button()
    var titleString: String = ""
    var callBack: String = ""
}

protocol AtAuthorizeViewDelegate: AnyObject {
    func clickButton(callback: String, params: [String: Any]?)
}

// @功能授权管理 View
class AtAuthorizeView: UIView, BannerItem {
    public var permStatistics: PermissionStatistics?
    weak var uiDelegate: BannerUIDelegate?
    var itemType: SKBannerContainer.ItemType {
        return .authority
    }
    var contentView: UIView {
        return self
    }

    private var leftButton: UIButton = UIButton()
    private var rightButton: UIButton = UIButton()
    private var titleLabel: UILabel = UILabel()
    private var hideRightButtonConstraint: SnapKit.Constraint?

    private var config: AtAuthorizeViewConfig!

    weak var delegate: AtAuthorizeViewDelegate!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UDNoticeColorTheme.noticeInfoBgColor
        setupSubviews()
    }

    func setupConfig(_ config: AtAuthorizeViewConfig) {
        self.config = config
    }

    func layoutHorizontalIfNeeded(preferedWidth: CGFloat) {
        updateSubviewsContent()
        uiDelegate?.shouldUpdateHeight(self, newHeight: titleLabel.frame.height + 12 * 2)
    }

    /// MLeaksFinder傻傻的，vc引用了这个view，即使其在deinit里销毁掉了，
    /// 这个库还是会因为BrowserView的重用机制报内存泄露(因为这个view宿主是browserView),所以骗它一下
    @objc
    func willDealloc() -> Bool {
        return false
    }

    func setupSubviews() {
        leftButton.addTarget(self, action: #selector(clickButton(_:)), for: .touchUpInside)
        addSubview(leftButton)

        rightButton.addTarget(self, action: #selector(clickButton(_:)), for: .touchUpInside)
        addSubview(rightButton)

        addSubview(titleLabel)

        initLayout()
    }

    func updateSubviewsContent() {
        leftButton.tag = config.leftButton.id
        let image = UDIcon.infoColorful
        leftButton.setImage(image, for: .normal)


//        if !config.leftButton.base64Image.isEmpty {
//            leftButton.setImage(UIImage.docs.image(base64: config.leftButton.base64Image), for: .normal)
//        } else if !config.leftButton.text.isEmpty {
//            leftButton.setTitle(config.leftButton.text, for: .normal)
//            leftButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
//            leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
//            leftButton.sizeToFit()
//        }

        rightButton.tag = config.rightButton.id
        if !config.rightButton.base64Image.isEmpty {
            rightButton.setImage(UIImage.docs.image(base64: config.rightButton.base64Image), for: .normal)
        } else if !config.rightButton.text.isEmpty {
            rightButton.setTitle(config.rightButton.text, for: .normal)
            rightButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
            rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            rightButton.sizeToFit()
        }

        if !config.titleString.isEmpty {
            titleLabel.font = UIFont.systemFont(ofSize: 15)
            titleLabel.text = config.titleString
            titleLabel.numberOfLines = 3
        }

        updateLayoutIfNeeded()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Layout
extension AtAuthorizeView {
    private func initLayout() {
        leftButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(18)
            make.left.equalTo(9)
            make.centerY.equalToSuperview()
        }

        rightButton.snp.makeConstraints { (make) in
            make.height.equalTo(38)
            make.right.equalTo(-9)
            make.centerY.equalToSuperview()
            hideRightButtonConstraint = make.width.equalTo(0).labeled("隐藏").constraint
        }
        rightButton.setContentHuggingPriority(.init(998), for: .horizontal)
        hideRightButtonConstraint?.deactivate()

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(leftButton.snp.right).offset(8)
            make.right.equalTo(rightButton.snp.left).offset(-8)
            make.centerY.equalToSuperview()
        }
    }

    private func updateLayoutIfNeeded() {
        var leftOffsetOfTitle = 8
        var rightOffsetOfTitle = leftOffsetOfTitle + 9
//        if config.leftButton.text.isEmpty && config.leftButton.base64Image.isEmpty {
//            leftButton.snp.updateConstraints { (make) in
//                make.width.height.equalTo(0)
//            }
//        } else {
            leftButton.snp.updateConstraints { (make) in
                make.width.height.equalTo(18)
            }
            leftOffsetOfTitle += 18
//        }

        if config.rightButton.text.isEmpty && config.rightButton.base64Image.isEmpty {
            hideRightButtonConstraint?.activate()
        } else {
            hideRightButtonConstraint?.deactivate()
            rightOffsetOfTitle += 32 // 约定右边按钮只能是两个字的话
        }
        var frame = titleLabel.frame
        frame.size.width = bounds.width - CGFloat(leftOffsetOfTitle + rightOffsetOfTitle)
        titleLabel.frame = frame
        titleLabel.sizeToFit()

    }
}

// MARK: 点击事件处理
extension AtAuthorizeView {
    @objc
    func clickButton(_ sender: UIButton) {
        let id = sender.tag
        if id == config.rightButton.id {
            self.permStatistics?.reportPermissionCommentWithoutPermissionClick(click: .true, target: .noneTargetView)
        }
        DocsLogger.info(self.config.callBack + "(\(id))")
        self.delegate.clickButton(callback: self.config.callBack, params: ["id": id])
    }
}
