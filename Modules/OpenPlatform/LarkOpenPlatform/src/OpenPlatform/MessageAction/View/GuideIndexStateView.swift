//
//  GuideIndexStateView.swift
//  LarkOpenPlatform
//
//  Created by  bytedance on 2020/9/14.
//

import UIKit
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignLoading
import FigmaKit
import LarkBoxSetting

/// 导索页-加载页面
/// 设计稿：https://www.figma.com/file/dNfKypVJW1Y58WO8JYQ3oK/20210331-%E6%B6%88%E6%81%AF%E5%BF%AB%E6%8D%B7%E6%93%8D%E4%BD%9C%E4%BD%93%E9%AA%8C%E8%BF%AD%E4%BB%A3?node-id=432%3A48489
class LoadingView: UIView {
    /// 要显示的cell数量
    private var loadingCellNum: Int
    private lazy var topLabel: UIView = {
        let label = UIView(frame: .zero)
        label.isSkeletonable = true
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()
    init(frame: CGRect, cellNum: Int) {
        self.loadingCellNum = cellNum
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /// view composition
    private func setupViews() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(topLabel)
        topLabel.snp.makeConstraints { (make) in
            make.height.equalTo(17)
            make.width.equalTo(80)
            make.top.equalToSuperview().offset(19)
            make.left.equalTo(16)
        }
        topLabel.showUDSkeleton()
        var cellMargin: CGFloat = 56.0
        for _ in 0..<loadingCellNum {
            let cell = LoadingCellView()
            addSubview(cell)
            cell.snp.makeConstraints { (make) in
                make.height.equalTo(LoadingCellView.height)
                make.top.equalToSuperview().offset(cellMargin)
                make.left.right.equalToSuperview().inset(16)
            }
            cellMargin += LoadingCellView.height + 16
            cell.startLoading()
        }
    }
}

//导索空态
class GuideIndexPageEmptyView: UIView, UITextViewDelegate {
    //占位，按照设计规范 https://www.figma.com/file/FY8KFZj9GqC2c5D42oBcVK/20201202-msg-action-及加号菜单无推荐应用时入口可见并展示引导内容?node-id=0%3A1 顶出30%的空间
    let aview = UIView()
    //无应用icon
    let img: UIImageView = {
        let img = UIImageView()
        img.image = UDEmptyType.noContent.defaultImage()
        return img
    }()
    lazy var title: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16.0, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        label.text = BundleI18n.MessageAction.Lark_OpenPlatform_ScNoAvailAppsDesc
        return label
    }()
    //参考原导索页header和footer
    lazy var text: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.delegate = textDelegate
        textView.attributedText = {
            let linkUrl = NSURL() as URL
            // Setting the attributes
            let linkAttributes = [
                NSAttributedString.Key.link: linkUrl,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0),
                NSAttributedString.Key.foregroundColor: UIColor.ud.textLinkNormal
            ] as [NSAttributedString.Key: Any]
            
            let tipAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0),
                NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption
            ] as [NSAttributedString.Key: Any]
            let tipText = BundleI18n.MessageAction.Lark_OpenPlatform_ScTryCustomAppsDesc
            let linkText = BundleI18n.MessageAction.Lark_OpenPlatform_ScCustomAppsBpHyperlink
            let text = tipText + " " + linkText
            let attributedString = NSMutableAttributedString(string: text)
            // Set substring to be the link
            attributedString.setAttributes(tipAttributes, range: NSRange(location: 0, length: tipText.count))
            attributedString.setAttributes(linkAttributes, range: NSRange(location: text.count - linkText.count, length: linkText.count))
            return attributedString
        }()
        textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textLinkNormal]
        textView.textAlignment = .center
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()
    private let bizScene: BizScene
    private weak var textDelegate: UITextViewDelegate?
    init(frame: CGRect, bizScene: BizScene, delegate: UITextViewDelegate) {
        self.bizScene = bizScene
        super.init(frame: frame)
        textDelegate = delegate
        setupViews()
        setupConstraint()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// view composition
    private func setupViews() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(aview)
        addSubview(img)
        addSubview(title)
        addSubview(text)
    }

    /// link是否需要隐藏
    func updateViews(linkTipsHidden: Bool) {
        if BoxSetting.isBoxOff() {
            text.isHidden = true
        } else {
            text.isHidden = linkTipsHidden
        }

    }

    private func setupConstraint() {
        aview.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.25)
        }
        img.snp.makeConstraints { (make) in
            make.width.height.equalTo(100)
            make.centerX.equalToSuperview()
            make.top.equalTo(aview.snp.bottom)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(img.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
        }
        text.snp.makeConstraints { (make) in
            make.top.equalTo(title.snp.bottom).offset(6)
            make.left.right.equalToSuperview().inset(16)
        }
    }
}

/// 导索页 - 加载失败
class LoadFailView: UIView {
    /// 加载失败图标
    private lazy var failIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDEmptyType.loadingFailure.defaultImage()
        return imageView
    }()
    /// 加载失败提示
    private lazy var failTip: UILabel = {
        let tip = UILabel()
        tip.text = BundleI18n.LarkOpenPlatform.Lark_OpenPlatform_InputScFailMsg
        tip.font = .systemFont(ofSize: 14.0)
        tip.textColor = UIColor.ud.textCaption
        tip.textAlignment = .center
        tip.numberOfLines = 0
        return tip
    }()
    /// 重新加载的按钮
    private lazy var retryBtn: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.layer.cornerRadius = 4
        let text = BundleI18n.LarkOpenPlatform.Lark_OpenPlatform_InputScRldBttn
        button.setTitle(text, for: .normal)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleReload), for: .touchUpInside)
        return button
    }()
    /// 重新加载
    private var reloadEvent: (() -> Void)

    @objc
    private func handleReload() {
        GuideIndexPageVCLogger.info("user tap reload button")
        reloadEvent()
    }

    init(frame: CGRect, reload: @escaping (() -> Void)) {
        self.reloadEvent = reload
        super.init(frame: frame)
        setupViews()
        setupConstraint()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// view composition
    private func setupViews() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(failIcon)
        addSubview(failTip)
        addSubview(retryBtn)
    }

    private func setupConstraint() {
        retryBtn.snp.makeConstraints { (make) in
            make.height.equalTo(36)
            /// 动态适应宽度
            make.width.equalTo(retryBtn.intrinsicContentSize.width + 32)
            make.bottom.centerX.equalToSuperview()
        }
        failTip.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(4)
            make.bottom.equalTo(retryBtn.snp.top).offset(-16)
        }
        failIcon.snp.makeConstraints { (make) in
            make.centerX.top.equalToSuperview()
            make.width.height.equalTo(100)
            make.bottom.equalTo(failTip.snp.top).offset(-12)
        }
    }
}

class LoadingCellView: UIView {
    /// cell高度
    static let height: CGFloat = 128.0
    static let defaultLabelSize = CGRect(x: 0, y: 0, width: 375, height: 16)
    /// Item的图标
    private lazy var logoView: UIView = {
        let logoView = UIView(frame: CGRect(x: 0, y: 0, width: MoreAppCollectionViewCell.logoSize.width, height: MoreAppCollectionViewCell.logoSize.height))
        logoView.layer.masksToBounds = true
        logoView.layer.ux.setSmoothCorner(radius: 10)
        return logoView
    }()
    /// Cell的标题
    private lazy var titleLabel: UIView = {
        let label = UIView(frame: Self.defaultLabelSize)
        label.isSkeletonable = true
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()
    /// Cell的描述
    private lazy var descLabel: UIView = {
        let label = UIView(frame: Self.defaultLabelSize)
        label.isSkeletonable = true
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()
    private lazy var moreDescLabel: UIView = {
        let label = UIView(frame: Self.defaultLabelSize)
        label.isSkeletonable = true
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraint()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func startLoading() {
        subviews.forEach { view in
            view.showUDSkeleton()
        }
    }

    /// view composition
    private func setupViews() {
        backgroundColor = UIColor.ud.bgFloat
        layer.cornerRadius = MoreAppCollectionViewCell.contentViewCornerRadius
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = (UIColor.ud.N300 & UIColor.clear).cgColor
        addSubview(logoView)
        addSubview(titleLabel)
        addSubview(descLabel)
        addSubview(moreDescLabel)
    }

    /// layout constraint
    private func setupConstraint() {
        let horizontalInset = 16
        logoView.snp.makeConstraints { (make) in
            make.size.equalTo(MoreAppCollectionViewCell.logoSize)
            make.left.equalToSuperview().offset(horizontalInset)
            make.top.equalToSuperview().offset(16)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(logoView)
            make.left.equalTo(logoView.snp.right).offset(12)
            make.width.equalTo(100)
            make.height.equalTo(16)
        }
        descLabel.snp.makeConstraints { (make) in
            make.left.equalTo(logoView)
            make.height.equalTo(14)
            make.top.equalTo(logoView.snp.bottom).offset(16)
            make.right.equalToSuperview().inset(horizontalInset)
        }
        moreDescLabel.snp.makeConstraints { (make) in
            make.left.equalTo(logoView)
            make.height.equalTo(14)
            make.top.equalTo(descLabel.snp.bottom).offset(12)
            make.right.equalToSuperview().inset(horizontalInset)
        }
    }
}

class GradientBackgroudView: UIView {

    private let gradientLayer: CAGradientLayer = CAGradientLayer()
    private let gradientStartColor: UIColor
    private let gradientEndColor: UIColor

    init(gradientStartColor: UIColor, gradientEndColor: UIColor) {
        self.gradientStartColor = gradientStartColor
        self.gradientEndColor = gradientEndColor
        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        gradientLayer.frame = self.bounds
    }

    override public func draw(_ rect: CGRect) {
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [gradientStartColor.cgColor, gradientEndColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        if gradientLayer.superlayer == nil {
            layer.insertSublayer(gradientLayer, at: 0)
        }
    }

    func setCornerRedius(redius: CGFloat) {
        gradientLayer.cornerRadius = redius
    }
}
