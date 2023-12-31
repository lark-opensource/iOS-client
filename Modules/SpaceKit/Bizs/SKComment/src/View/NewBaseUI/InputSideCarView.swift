//
//  InputSideCarView.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2020/4/27.
//

import Foundation
import UIKit
import RxSwift
import RxRelay
import SKFoundation
import SKResource
import UniverseDesignFont
import UniverseDesignInput
import SpaceInterface
import SKCommon

protocol CommentInputSideCarViewDelegate: NSObjectProtocol {
    func didClickInputActiveBtn(attributedText: NSAttributedString, imageList: [CommentImageInfo])
    func didClickInputSendBtn(attributedText: NSAttributedString, imageList: [CommentImageInfo])
}

class InputSideCarView: UIView {

    weak var delegate: CommentInputSideCarViewDelegate?

    weak var commentDraftKeyDataSource: CommentDraftKeyProvider?
    
    /// containerView
    private(set) lazy var containerView: UIView = setupContainerView()

    /// text
    private lazy var textView: UDBaseTextView = setupTextView()

    /// 激活输入框按钮
    private(set) lazy var activeBtn: UIButton = setupActiveBtn()

    /// 发送按钮
    private(set) lazy var sendButton: UIButton = setupSendButton()

    /// 评论原始数据
    private var originData: (NSAttributedString, [CommentImageInfo]) = (.init(), [])
    
    private var commentDraftInfo: (commentDraftKey: CommentDraftKey?, docsInfo: DocsInfo?) = (nil, nil)
    
    private var disposeBag: DisposeBag = DisposeBag()

    var canShowDarkName = true
    
    var zoomable: Bool = false {
        didSet {
            textView.font = textFont
            if textView.superview != nil {
                textView.snp.updateConstraints { make in
                    make.height.equalTo(textFont.lineHeight + 10)
                }
            }
        }
    }
    
    var textFont: UIFont {
        return zoomable ? UIFont.ud.body0 : UIFont.systemFont(ofSize: 16)
    }
    
    override private init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
        setupBind()
        _ = NotificationCenter.default.addObserver(forName: UniverseDesignFont.UDZoom.didChangeNotification,
                                                   object: nil, queue: .main) { [weak self] (_) in
            guard let self = self, self.zoomable else {
                return
            }
            self.resetAttributedText()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(fetchAtUserPermission), name: Notification.Name.FeatchAtUserPermissionResult, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func resetAttributedText() {
        guard let attributedText = textView.attributedText, attributedText.length > 0 else {
            return
        }
        let att = NSMutableAttributedString(attributedString: attributedText)
        att.addAttributes([NSAttributedString.Key.font: textFont], range: NSRange(location: 0, length: attributedText.length))
        textView.attributedText = att
    }

}


extension InputSideCarView {

    func textViewSet(attributedText: NSAttributedString, imageList: [CommentImageInfo], placeHolder: String?) {
        self.originData = (attributedText, imageList)
        var imageReplaceText: String = ""
        for _ in 0..<imageList.count {
            let imageResourceText = BundleI18n.SKResource.Drive_Drive_ImageType
            imageReplaceText += " [\(imageResourceText)]"
        }
        
        let imageReplaceTextAttr = NSAttributedString(string: imageReplaceText, attributes: [NSAttributedString.Key.font: textFont,
                                                                  NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle])
        let mutable = NSMutableAttributedString(attributedString: attributedText)
        mutable.append(imageReplaceTextAttr)
        mutable.addAttributes([NSAttributedString.Key.font: textFont], range: NSRange(location: 0, length: mutable.length))
        textView.placeholder = placeHolder
        textView.attributedText = mutable
        let isEmpty = textView.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true
        setSendBtnEnable(enable: !isEmpty)
    }

    func setupBind() {
        sendButton.rx.tap
            .observeOn(MainScheduler.instance)
            .bind { [weak self] in
                self?.doSend()
            }.disposed(by: disposeBag)

        activeBtn.rx.tap
            .observeOn(MainScheduler.instance)
            .bind { [weak self] in
                self?.doActive()
            }.disposed(by: disposeBag)
        
        let name = Notification.Name.commentDraftClear
        NotificationCenter.default.addObserver(self, selector: #selector(handleDraftClear), name: name, object: nil)
    }


    func setSendBtnEnable(enable: Bool) {
        if enable == true {
            sendButton.isUserInteractionEnabled = true
            sendButton.tintColor = UIColor.ud.colorfulBlue
        } else {
            sendButton.isUserInteractionEnabled = false
            sendButton.tintColor = UIColor.ud.B300
        }
    }

    @objc
    private func doSend() {
        DocsLogger.info("InputSideCarView, doSend", component: LogComponents.comment)
        self.delegate?.didClickInputSendBtn(attributedText: originData.0,
                                            imageList: originData.1)
    }

    @objc
    private func doActive() {
        DocsLogger.info("InputSideCarView, doActive", component: LogComponents.comment)
        self.delegate?.didClickInputActiveBtn(attributedText: originData.0,
                                              imageList: originData.1)
    }
    
    @objc
    private func handleDraftClear(_ noti: Notification) {
        guard let key1 = noti.object as? CommentDraftKey else { return }
        guard let key2 = self.commentDraftKeyDataSource?.commentDraftKey else { return }
        guard key1 == key2, case .newReply = key1.sceneType else { return } // 回复的场景下，清空
        clearDraft()
    }
    
    func clearDraft() {
        textViewSet(attributedText: .init(), imageList: [], placeHolder: textView.placeholder)
    }
    
    func updateDraft(with key: CommentDraftKey?, docsInfo: DocsInfo?) {
        commentDraftInfo = (key, docsInfo)
        if let draftKey = key,
           let content = CommentDraftManager.shared.commentContent(for: draftKey, textFont: textFont, docsInfo: docsInfo, checkPermission: canShowDarkName) {
            textViewSet(attributedText: content.attrContent ?? .init(),
                        imageList: content.imageInfos ?? [],
                        placeHolder: textView.placeholder)
        } else {
            clearDraft()
        }
    }
    
    func updatePlaceHolder(with text: String?) {
        textView.placeholder = text
    }

    @objc
    private func fetchAtUserPermission() {
        updateDraft(with: commentDraftInfo.commentDraftKey, docsInfo: commentDraftInfo.docsInfo)
    }
}

extension InputSideCarView {

    func setupUI() {
        layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)
        layer.shadowOpacity = 1.0
        layer.shadowOffset = CGSize(width: 0, height: -8)

        addSubview(containerView)
        containerView.backgroundColor = UIColor.ud.bgFloat
        containerView.layer.borderWidth = 0.5
        containerView.layer.ud.setBorderColor(UIColor.ud.N300)
        containerView.layer.cornerRadius = 8
        containerView.layer.masksToBounds = true

        containerView.addSubview(textView)
        containerView.addSubview(activeBtn)
        containerView.addSubview(sendButton)
        textView.isUserInteractionEnabled = false

        containerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        textView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(sendButton.snp.left).offset(-16)
            make.centerY.equalToSuperview().offset(-3)
            make.height.equalTo(textFont.lineHeight + 10)
        }

        activeBtn.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(sendButton.snp.left).offset(-16)
        }
        activeBtn.accessibilityIdentifier = "docs.comment.input.activeBtn"

        sendButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-18)
            make.height.equalTo(24)
            make.width.equalTo(24)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    private func setupContainerView() -> UIView {
        let v = UIView()
        return v
    }

    private func setupTextView() -> UDBaseTextView {
        let textView = UDBaseTextView()
        textView.font = textFont
        textView.textContainer.maximumNumberOfLines = 1
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.backgroundColor = UIColor.ud.bgFloat
        return textView
    }

    private func setupActiveBtn() -> UIButton {
        let button = UIButton()
        button.backgroundColor = .clear
        return button
    }


    private func setupSendButton() -> UIButton {
        let button = UIButton()
        let image = BundleResources.SKResource.Common.Global.icon_global_send_nor.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        return button
    }
}
