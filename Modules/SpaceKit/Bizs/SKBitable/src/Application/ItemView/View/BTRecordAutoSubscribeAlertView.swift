//
//  BTRecordAutoSubscribeAlertView.swift
//  SKBitable
//
//  Created by ByteDance on 2023/11/4.
//

import UIKit
import UniverseDesignEmpty
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont
import SKUIKit
import SKFoundation
import SKCommon
import SKResource

final class BTRecordAutoSubscribeAlertView: UIView {
    var bottomContainerHeight: CGFloat = 213.0
    private lazy var bottomContainer = UIView().construct { it in
        it.layer.cornerRadius = 12
        it.layer.maskedCorners = .top
        it.layer.masksToBounds = true
    }
    
    private lazy var gradientLayer = {
        let layer = CAGradientLayer()
        layer.locations = [0.0,0.25,0.5]
        layer.startPoint = CGPoint(x: 0.0, y: 0.0)
        layer.endPoint = CGPoint(x: 0.0, y: 1.0)
        return layer
    }()
    
    private lazy var imgIcon = UIImageView().construct { it in
        it.image = UDIcon.getIconByKey(.infoCcmFilled, iconColor: UDColor.textLinkNormal, size: CGSize(width: 20, height: 20))
    }
    
    private var title: String {
        return BundleI18n.SKResource.Bitable_SubscribeRecords_DontAutoFollow_Title
    }
    private lazy var titleLabel = UILabel().construct { it in
        it.font =  UIFont.boldSystemFont(ofSize: 17)
        it.textAlignment = .left
        it.numberOfLines = 1
        it.text = title
        it.textColor = UDColor.textTitle
    }
    
    private var subTitle: String {
        return BundleI18n.SKResource.Bitable_SubscribeRecords_DontAutoFollow_Desc
    }
    private lazy var subLabel = UILabel().construct { it in
        it.font =  UIFont.systemFont(ofSize: 16)
        it.textAlignment = .left
        it.textColor = UDColor.textCaption
        it.numberOfLines = 0
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 6
        it.attributedText = NSAttributedString(string: subTitle, attributes: [NSAttributedString.Key.paragraphStyle: style])
    }
    
    private lazy var closeAutoScribeButton = UIButton().construct { it in
        it.addTarget(self, action: #selector(closeAutoScribeButtonClick), for: .touchUpInside)
        it.setTitle(BundleI18n.SKResource.Bitable_SubscribeRecords_DontAutoFollow_Confirm_Button
, for: .normal)
        it.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        it.setTitleColor(UDColor.textTitle, for: .normal)
        it.layer.cornerRadius = 6
        it.layer.masksToBounds = true
        it.layer.borderColor = UDColor.lineBorderComponent.cgColor
        it.layer.borderWidth = 1
    }
    
    private lazy var cancelButton = UIButton().construct { it in
        it.addTarget(self, action: #selector(cancelButtonClick), for: .touchUpInside)
        it.setTitle(BundleI18n.SKResource.Bitable_SubscribeRecords_DontAutoFollow_Cancel_Button
, for: .normal)
        it.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        it.setTitleColor(UDColor.textTitle, for: .normal)
        it.layer.cornerRadius = 6
        it.layer.masksToBounds = true
        it.layer.borderColor = UDColor.lineBorderComponent.cgColor
        it.layer.borderWidth = 1
    }
    private var closeAutoSubscribeHandler: () -> () = {}
    private var cancelHandler: () -> () = {}
    
    //MARK: lifeCycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupChildViews()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    init(closeAutoSubscribeCallBack: @escaping () -> (), cancelCallBack: @escaping () -> ()) {
        closeAutoSubscribeHandler = closeAutoSubscribeCallBack
        cancelHandler = cancelCallBack
        super.init(frame: .zero)
        setupChildViews()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bottomContainer.bounds
    }
    
    //MARK: publicMethod
    func showAppearAnimation() {
        setNeedsLayout()
        layoutIfNeeded()
        bottomContainerHeight = bottomContainer.bounds.size.height
        bottomContainer.transform = CGAffineTransform(translationX: 0, y: bottomContainerHeight)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.bottomContainer.transform = CGAffineTransform(translationX: 0, y: 0)
            self.layer.backgroundColor = UDColor.bgMask.cgColor
        }
    }
    
    private func showDisAppearAnimation() {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.bottomContainer.transform = CGAffineTransform(translationX: 0, y: self.bottomContainerHeight)
            self.layer.backgroundColor = UIColor.clear.cgColor
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
    
    //MARK: privateMethod
    private func setupChildViews() {
        addSubview(bottomContainer)
        bottomContainer.layer.addSublayer(gradientLayer)
        bottomContainer.addSubview(imgIcon)
        bottomContainer.addSubview(titleLabel)
        bottomContainer.addSubview(subLabel)
        bottomContainer.addSubview(cancelButton)
        bottomContainer.addSubview(closeAutoScribeButton)
        
        self.layer.backgroundColor = UIColor.clear.cgColor
        bottomContainer.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(0)
        }
        gradientLayer.ud.setColors([
            UDColor.primaryPri50,
            UDColor.bgBody,
            UDColor.bgBody])
        imgIcon.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(24)
        }
        titleLabel.sizeToFit()
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(imgIcon.snp.right).offset(6)
            make.right.equalToSuperview().offset(-24)
            make.centerY.equalTo(imgIcon.snp.centerY)
        }
        subLabel.sizeToFit()
        subLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
            make.top.equalTo(titleLabel.snp.bottom).offset(17)
        }
        cancelButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.width.equalToSuperview().multipliedBy(0.5).offset(-30)
            make.height.equalTo(48)
            make.top.equalTo(subLabel.snp.bottom).offset(23)
            make.bottom.equalToSuperview().offset(-34)
        }
        closeAutoScribeButton.snp.makeConstraints { make in
            make.left.equalTo(cancelButton.snp.right).offset(12)
            make.width.equalTo(cancelButton.snp.width)
            make.height.equalTo(48)
            make.top.equalTo(subLabel.snp.bottom).offset(23)
            make.bottom.equalToSuperview().offset(-34)
        }
    }
    
    @objc
    private func orientationDidChange() {
        if self.superview != nil {
            setNeedsLayout()
            layoutIfNeeded()
            bottomContainerHeight = bottomContainer.bounds.size.height
        }
    }
    
    //MARK: 交互事件
    @objc
    private func cancelButtonClick() {
        showDisAppearAnimation()
        cancelHandler()
    }
    
    @objc
    private func closeAutoScribeButtonClick() {
        showDisAppearAnimation()
        closeAutoSubscribeHandler()
    }
}

final class BTRecordAutoSubscribeAlertController: UIViewController {
    private let leftMargin: CGFloat = 24.0
    private let topMargin: CGFloat = 42.0
    private let buttonH: CGFloat = 48.0
    private let dlTopMargin: CGFloat = 13.0
    private let btnTopMargin: CGFloat = 18.0
    private let btnBottomMargin: CGFloat = 24.0
    
    var alertContentSize: CGSize {
        let width: CGFloat = 375.0
        let labelWidth = width - leftMargin * 2
        
        //compute titleLabel Height
        let titleH = titleStr.boundingRect(with: CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude),
                          options: NSStringDrawingOptions.usesLineFragmentOrigin,
                       attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17)],
                          context: nil).height
        
        //compute desLable Height
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 6
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .paragraphStyle: style,
        ]
        let desLabH = desTitle.boundingRect(with: CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude),
                          options: NSStringDrawingOptions.usesLineFragmentOrigin,
                          attributes: attributes,
                          context: nil).height
        
        let height = topMargin + titleH + dlTopMargin + desLabH + btnTopMargin + buttonH + btnBottomMargin
        return CGSizeMake(width, height)
    }
    
    private lazy var gradientLayer = {
        let layer = CAGradientLayer()
        layer.locations = [0.0,0.25,0.5]
        layer.startPoint = CGPoint(x: 0.0, y: 0.0)
        layer.endPoint = CGPoint(x: 0.0, y: 1.0)
        return layer
    }()
    
    private lazy var img = UIImageView().construct { it in
        it.image = UDIcon.getIconByKey(.infoCcmFilled, iconColor: UDColor.textLinkNormal, size: CGSize(width: 20, height: 20))
    }
    
    
    private var titleStr: String {
        return BundleI18n.SKResource.Bitable_SubscribeRecords_DontAutoFollow_Title
    }
    private lazy var titleL = UILabel().construct { it in
        it.font =  UIFont.boldSystemFont(ofSize: 17)
        it.textAlignment = .left
        it.numberOfLines = 1
        it.text = titleStr
        it.textColor = UDColor.textTitle
    }
    
    private var desTitle: String {
        return BundleI18n.SKResource.Bitable_SubscribeRecords_DontAutoFollow_Desc
    }
    private lazy var desLab = UILabel().construct { it in
        it.font =  UIFont.systemFont(ofSize: 16)
        it.textAlignment = .left
        it.textColor = UDColor.textCaption
        it.numberOfLines = 0
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 6
        it.attributedText = NSAttributedString(string: desTitle, attributes: [NSAttributedString.Key.paragraphStyle: style])
    }
    
    private lazy var confirmBtn = UIButton().construct { it in
        it.addTarget(self, action: #selector(closeAutoScribeButtonClick), for: .touchUpInside)
        it.setTitle(BundleI18n.SKResource.Bitable_SubscribeRecords_DontAutoFollow_Confirm_Button
, for: .normal)
        it.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        it.setTitleColor(UDColor.textTitle, for: .normal)
        it.layer.cornerRadius = 6
        it.layer.masksToBounds = true
        it.layer.borderColor = UDColor.lineBorderComponent.cgColor
        it.layer.borderWidth = 1
    }
    
    private lazy var cancelBtn = UIButton().construct { it in
        it.addTarget(self, action: #selector(cancelButtonClick), for: .touchUpInside)
        it.setTitle(BundleI18n.SKResource.Bitable_SubscribeRecords_DontAutoFollow_Cancel_Button
, for: .normal)
        it.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        it.setTitleColor(UDColor.textTitle, for: .normal)
        it.layer.cornerRadius = 6
        it.layer.masksToBounds = true
        it.layer.borderColor = UDColor.lineBorderComponent.cgColor
        it.layer.borderWidth = 1
    }
    private var hasAppeared: Bool = false
    private var closeAutoSubscribeHandler: () -> () = {}
    private var cancelHandler: () -> () = {}
    
    //MARK: lifeCycle    
    init(closeAutoSubscribeCallBack: @escaping () -> (), cancelCallBack: @escaping () -> ()) {
        closeAutoSubscribeHandler = closeAutoSubscribeCallBack
        cancelHandler = cancelCallBack
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.backgroundColor = UIColor.clear.cgColor
        prepareChildViews()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if hasAppeared {
            dismiss(animated: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppeared = true
    }
        
    //MARK: privateMethod
    private func prepareChildViews() {
        gradientLayer.frame = view.bounds
        view.layer.addSublayer(gradientLayer)
        gradientLayer.ud.setColors([
            UDColor.primaryPri50,
            UDColor.bgBody,
            UDColor.bgBody])
        
        view.addSubview(img)
        img.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.top.equalToSuperview().offset(topMargin)
            make.left.equalToSuperview().offset(leftMargin)
        }
        view.addSubview(titleL)
        titleL.sizeToFit()
        titleL.snp.makeConstraints { make in
            make.left.equalTo(img.snp.right).offset(6)
            make.right.equalToSuperview().offset(-leftMargin)
            make.centerY.equalTo(img.snp.centerY)
        }
        
        view.addSubview(desLab)
        view.addSubview(cancelBtn)
        view.addSubview(confirmBtn)
        desLab.sizeToFit()
        desLab.snp.makeConstraints { make in
            make.top.equalTo(titleL.snp.bottom).offset(dlTopMargin)
            make.left.equalToSuperview().offset(leftMargin)
            make.right.equalToSuperview().offset(-leftMargin)
        }
        cancelBtn.snp.makeConstraints { make in
            make.top.equalTo(desLab.snp.bottom).offset(btnTopMargin)
            make.bottom.equalToSuperview().offset(-btnBottomMargin)
            make.left.equalToSuperview().offset(leftMargin)
            make.width.equalToSuperview().multipliedBy(0.5).offset(-30)
            make.height.equalTo(48)
        }
        confirmBtn.snp.makeConstraints { make in
            make.top.equalTo(desLab.snp.bottom).offset(btnTopMargin)
            make.bottom.equalToSuperview().offset(-btnBottomMargin)
            make.left.equalTo(cancelBtn.snp.right).offset(12)
            make.width.equalTo(cancelBtn.snp.width)
            make.height.equalTo(48)
        }
    }
    
    //MARK: 交互事件
    @objc
    private func cancelButtonClick() {
        cancelHandler()
        dismiss(animated: true)
    }
    
    @objc
    private func closeAutoScribeButtonClick() {
        closeAutoSubscribeHandler()
        dismiss(animated: true)
    }
}

