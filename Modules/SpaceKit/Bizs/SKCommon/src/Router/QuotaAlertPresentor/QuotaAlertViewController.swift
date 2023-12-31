//
//  QuotaAlertViewController.swift
//  SKCommon
//
//  Created by bupozhuang on 2021/7/19.
//

import Foundation
import SKUIKit
import SpaceInterface
import EENavigator
import SKResource
import SKFoundation
import UniverseDesignToast
import LarkAppConfig

protocol QuotaAlertDelegate: NSObject {
    func gotoCustomService(type: QuotaAlertType, from: UIViewController)
    func handleAttribute(info: QuotaAttributeInfo, from: UIViewController, bizParams: SpaceBizParameter?, quotaInfo: QuotaInfo?, quotaUploadInfo: QuotaUploadInfo?)
    func conformClose(quotaInfo: QuotaInfo?, bizParams: SpaceBizParameter?)
    func uploadEventReport(quotaUploadInfo: QuotaUploadInfo?, clickEvent: QuotaUploadClickEvent)
}

public final class QuotaAlertViewController: DraggableViewController, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate {
    fileprivate struct Const {
        static let contentHeight: CGFloat = 368
        static let topMargin: CGFloat = 48.0
        static let bottomMargin: CGFloat = 48.0
        static let titleTop: CGFloat = 12.0
        static let detailTop: CGFloat = 4.0
        static let buttonTop: CGFloat = 16.0
        static let imageHeight: CGFloat = 120.0
        static let buttonHeight: CGFloat = 36.0
    }
    weak var fromVC: UIViewController?
    weak var delegate: QuotaAlertDelegate?
    private var viewWdith: CGFloat = 0.0
    private var quotaType: QuotaAlertType
    private var customAttTips: NSAttributedString?
    private var isUserQuota: Bool { // 用户容量提示不展示联系客服按钮
        return !showContact
    }
    private var showContact: Bool // 是否展示联系客服
    private var quotaUploadInfo: QuotaUploadInfo? //上传相关数据上报用
    private var quotaInfo: QuotaInfo? // 数据上报用
    var bizParams: SpaceBizParameter? // 数据上报用
    private lazy var header = QuotaAlertViewHeader()
    private lazy var closeBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(BundleResources.SKResource.Common.Close.confirmClose, for: .normal)
        btn.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        return btn
    }()
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        label.textColor = UIColor.ud.N900
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        label.textColor = UIColor.ud.N600
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var button: UIButton = {
        let btn = UIButton()
        btn.setTitle(BundleI18n.SKResource.CreationMobile_Docs_StorageFull_ContactSupport_btn, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.setTitleColor(UIColor.ud.N00, for: .normal)
        btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        btn.backgroundColor = UIColor.ud.colorfulBlue
        btn.layer.cornerRadius = 4.0
        btn.layer.masksToBounds = true
        btn.addTarget(self, action: #selector(click(_:)), for: .touchUpInside)
        return btn
    }()
    
    private lazy var businessInfoView: QuotaBusinessSuiteView = {
        let view = QuotaBusinessSuiteView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let handler: ((QuotaBusinessSuiteView) -> Void)?
    private var businessInfoViewHeight: CGFloat = 140.0
    
    init(quotaType: QuotaAlertType,
                fromVC: UIViewController,
                customTips: NSAttributedString? = nil,
                showContact: Bool = true,
                quotaInfo: QuotaInfo? = nil,
                quotaUploadInfo: QuotaUploadInfo? = nil,
                handler: ((QuotaBusinessSuiteView) -> Void)? = nil) {
        self.quotaType = quotaType
        self.fromVC = fromVC
        self.customAttTips = customTips
        self.showContact = showContact
        self.quotaInfo = quotaInfo
        self.quotaUploadInfo = quotaUploadInfo
        self.handler = handler
        super.init(nibName: nil, bundle: nil)
        transitioningDelegate = self
        if self.handler == nil {
            self.businessInfoViewHeight = 0
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        viewWdith = view.bounds.width
        contentViewMinY = view.bounds.maxY * 0.2
        contentViewMaxY = view.bounds.maxY - contentHeight
        setupUI()
        addGestureRecognizer()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let newContentHeight = caculateContentHeight(width: view.bounds.width)
        if viewWdith != view.bounds.width || newContentHeight != contentHeight {
            viewWdith = view.bounds.width
            contentHeight = newContentHeight
            contentViewMaxY = view.bounds.maxY - newContentHeight
            configContentView(height: newContentHeight)
        }
        _updateContentViewMaskLayer()
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if SKDisplay.pad {
            self.dismiss(animated: true, completion: nil)
        }
    }

    private lazy var contentHeight: CGFloat = {
        let bottomSafeAreaHeight = self.view.safeAreaInsets.bottom
        return Const.contentHeight + bottomSafeAreaHeight
    }()
    private func setupUI() {
        contentView = UIView().construct({
            $0.backgroundColor = UIColor.ud.N00
        })
        
        imageView.image = quotaType.image
        let titleParag = NSMutableParagraphStyle()
        titleParag.lineHeightMultiple = 1.2
        titleParag.alignment = .center
        
        titleLabel.attributedText = NSAttributedString(string: quotaType.title,
                                                       attributes: [NSAttributedString.Key.paragraphStyle: titleParag])
        if let tips = customAttTips {
            detailLabel.attributedText = tips
        } else {
            let detailParag = NSMutableParagraphStyle()
            detailParag.lineHeightMultiple = 1.2
            detailParag.alignment = .center
            detailLabel.attributedText = NSAttributedString(string: quotaType.detail,
                                                            attributes: [NSAttributedString.Key.paragraphStyle: detailParag])
        }
        
        if !showContact {
            button.setTitle(BundleI18n.SKResource.CreationMobile_ECM_SpaceKnewButton, for: .normal)
        }

        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        detailLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        detailLabel.setContentHuggingPriority(.required, for: .vertical)
        view.addSubview(contentView)
        contentView.addSubview(header)
        header.addSubview(closeBtn)
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(button)
        configContentView(height: contentHeight)
        
        closeBtn.snp.makeConstraints { make in
            make.width.height.equalTo(24.0)
            make.top.equalToSuperview().offset(18.0)
            make.left.equalToSuperview().offset(18.0)
        }
        header.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(48.0)
        }
        imageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(48.0)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(120.0)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(12.0)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
        if let viewHandler = handler {
            contentView.addSubview(businessInfoView)
            businessInfoView.snp.makeConstraints { (make) in
                make.top.equalTo(titleLabel.snp.bottom).offset(4.0)
                make.height.equalTo(140)
                make.centerX.equalToSuperview()
            }
            viewHandler(businessInfoView)
        }
        detailLabel.snp.makeConstraints { (make) in
            if handler != nil {
                make.top.equalTo(businessInfoView.snp.bottom).offset(4.0)
            } else {
                make.top.equalTo(titleLabel.snp.bottom).offset(8.0)
            }
            make.left.equalToSuperview().offset(16.0)
            make.right.equalToSuperview().offset(-16.0)
        }
        
        button.snp.makeConstraints { (make) in
            make.width.greaterThanOrEqualTo(88.0)
            make.height.equalTo(36.0)
            make.centerX.equalToSuperview()
            make.top.equalTo(detailLabel.snp.bottom).offset(16.0)
        }
    }
    
    private func configContentView(height: CGFloat) {
        if modalPresentationStyle == .formSheet {
            closeBtn.isHidden = false
            header.topLine.isHidden = true
            // 这个 preferredContentSize 是用来设置 formSheet 的大小的
            preferredContentSize = CGSize(width: CGFloat.scaleBaseline, height: height)
            contentView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        } else {
            closeBtn.isHidden = true
            if panGestureRecognizer.view == nil {
                header.addGestureRecognizer(panGestureRecognizer)
            }
            contentView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(contentViewMaxY)
                make.height.equalTo(height)
            }
        }
    }
    
    func addGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapDimiss))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    
    private func checkIfClickAtInfo(sender: UIGestureRecognizer) {
        let contentLabel = self.detailLabel
        let detailLocation = sender.location(in: contentLabel)
        if contentLabel.bounds.contains(detailLocation), let attributedText = contentLabel.attributedText {
            let storage = NSTextStorage(attributedString: attributedText)
            let manager = NSLayoutManager()
            storage.addLayoutManager(manager)
            let container = NSTextContainer(size: CGSize(width: contentLabel.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
            container.lineFragmentPadding = 0
            container.maximumNumberOfLines = contentLabel.numberOfLines
            container.lineBreakMode = contentLabel.lineBreakMode
            manager.addTextContainer(container)
            let index = manager.characterIndex(for: detailLocation, in: container, fractionOfDistanceBetweenInsertionPoints: nil)
            let attributes = attributedText.attributes(at: index, effectiveRange: nil)
            
            if let atinfo = attributes[QuotaContact.attributedStringAtInfoKey] as? QuotaAttributeInfo,
                let from = fromVC {
                self.dismiss(animated: true, completion: nil)
                delegate?.handleAttribute(info: atinfo, from: from, bizParams: bizParams, quotaInfo: quotaInfo, quotaUploadInfo: quotaUploadInfo)
            }
        }
    }

    private func caculateContentHeight(width: CGFloat) -> CGFloat {
        titleLabel.sizeToFit()
        detailLabel.sizeToFit()
        return Const.topMargin +
            Const.bottomMargin + Const.titleTop + Const.detailTop +
            Const.buttonTop + Const.buttonHeight +
            Const.imageHeight + self.businessInfoViewHeight +
            titleLabel.calculateLabelHeight(textWidth: width - 32.0) +
            detailLabel.calculateLabelHeight(textWidth: width - 32.0) +
            self.view.safeAreaInsets.bottom
    }
    
    private func _updateContentViewMaskLayer() {
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: contentView.bounds.width, height: contentView.bounds.height),
                                byRoundingCorners: UIRectCorner(rawValue: UIRectCorner.topLeft.rawValue | UIRectCorner.topRight.rawValue),
                                cornerRadii: CGSize(width: 6, height: 6))
        maskLayer.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: contentView.bounds.height)
        maskLayer.path = path.cgPath
        contentView.layer.mask = maskLayer
    }
    
    @objc
    private func onTapDimiss(sender: UIGestureRecognizer) {
        let location = sender.location(in: contentView)
        guard contentView.bounds.contains(location) else {
            reportClose()
            self.dismiss(animated: true, completion: nil)
            return
        }
        checkIfClickAtInfo(sender: sender)
    }
    
    public override func dragDismiss() {
        reportClose()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc
    func click(_ button: UIButton) {
        if showContact, let from = fromVC { // 点击联系客服按钮
            delegate?.gotoCustomService(type: quotaType, from: from)
            delegate?.uploadEventReport(quotaUploadInfo: quotaUploadInfo, clickEvent: .contact)
        } else {
            reportClose()
            delegate?.uploadEventReport(quotaUploadInfo: quotaUploadInfo, clickEvent: .alreadyKonw)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc
    func closeAction() {
        reportClose()
        delegate?.uploadEventReport(quotaUploadInfo: quotaUploadInfo, clickEvent: .close)
        self.dismiss(animated: true, completion: nil)
    }
    private func reportClose() {
        if isUserQuota {
            delegate?.conformClose(quotaInfo: quotaInfo, bizParams: bizParams)
        }
    }

    // UIGestureRecognizerDelegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    // UIViewControllerTransitioningDelegate
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if self.modalPresentationStyle == .formSheet {
           // 当modalPresentationStyle为formSheet，转场动画交由系统负责
            return nil
        }
        return DimmingPresentAnimation(animateDuration: 0.25,
                                       willPresent: { [weak self] in
                                        self?._updateContentViewMaskLayer()
                                       }, completion: nil)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if self.modalPresentationStyle == .formSheet {
           // 当modalPresentationStyle为formSheet，转场动画交由系统负责
            return nil
        }
        return DimmingDismissAnimation(animateDuration: 0.25)
    }
}

class QuotaAlertViewHeader: UIView {
    let topLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N300
        view.layer.cornerRadius = 3
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupInit()
        setupLayout()
    }

    func setupInit() {
        backgroundColor = UIColor.ud.N00
        addSubview(topLine)
    }
    
    func setupLayout() {
        topLine.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(8)
            make.centerX.equalToSuperview()
            make.height.equalTo(4)
            make.width.equalTo(40)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height),
                                byRoundingCorners: UIRectCorner(rawValue: UIRectCorner.topLeft.rawValue | UIRectCorner.topRight.rawValue),
                                cornerRadii: CGSize(width: 6, height: 6))
        maskLayer.frame = bounds
        maskLayer.path = path.cgPath
        layer.mask = maskLayer
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
