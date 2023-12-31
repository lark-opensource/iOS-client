//
//  BTURLEditBoardView.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/4/8.
//


import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignShadow
import RxSwift
import LarkEMM
import SpaceInterface
import SKInfra

struct BTURLEditBoardViewModel {
    var text: String
    var link: String
}

enum BTURLEditBoardChangeType {
    case none
    case onlyText
    case onlyLink
    case both
}

enum BTURLEditBoardFinishContentType {
    case normal(data: BTURLEditBoardViewModel, changeType: BTURLEditBoardChangeType)
    case atInfo(_: AtInfo)
}

protocol BTURLEditBoardViewDelegate: AnyObject {
    func urlEditBoardDidFinish(contentType: BTURLEditBoardFinishContentType)
    func urlEditBoardDidCancel(isByClose: Bool)
}

final class BTURLEditBoardView: UIView {
    
    weak var delegate: BTURLEditBoardViewDelegate?
    
    private let urlParser = BTURLParser()
    
    private var atInfo: AtInfo?
    
    private var originalData = BTURLEditBoardViewModel(text: "", link: "")
    
    private var toolBar: BTURLEditBoardToolBar = BTURLEditBoardToolBar()
    
    private lazy var dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    private lazy var itemsContainerView: UIStackView = {
        let containerView = UIStackView(arrangedSubviews: [textItemView, urlItemView])
        containerView.axis = .vertical
        containerView.spacing = 20
        containerView.distribution = .fillEqually
        return containerView
    }()
    
    private var textItemView: BTURLEditBoardItemView
    
    private var urlItemView: BTURLEditBoardItemView
    
    init(frame: CGRect, baseContext: BaseContext?) {
        textItemView = BTURLEditBoardItemView(frame: .zero, baseContext: baseContext)
        urlItemView = BTURLEditBoardItemView(frame: .zero, baseContext: baseContext)
        super.init(frame: frame)
        setupViews()
        setupLayouts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func focusFirstTextField() {
        _ = self.textItemView.becomeFirstResponder()
        self.urlItemView.setTextFieldLongPressEnable(false)
    }
    
    func updateData(_ data: BTURLEditBoardViewModel) {
        originalData = data
        textItemView.updateData(BTURLEditBoardItemViewModel(title: BundleI18n.SKResource.Bitable_Field_HyperlinkText,
                                                            content: data.text,
                                                            placeholder: BundleI18n.SKResource.Bitable_Common_PleaseEnterMobileVer))
        urlItemView.updateData(BTURLEditBoardItemViewModel(title: BundleI18n.SKResource.Bitable_Field_HyperlinkAddress,
                                                           content: data.link,
                                                           placeholder: BundleI18n.SKResource.Bitable_Form_EnterOrPasteLinkMobileVer))
    }
    
    @objc
    private func selfPressed() {
        // 这里是为了拦截父视图点击事件。
    }
    
    private func handleCompleteAction() {
        var text = textItemView.content
        var link = BTUtil.addHttpScheme(to: urlItemView.content)
        
        // 完成时，哪个为空，只使用另外的值
        switch (text.isEmpty, link.isEmpty) {
        case (false, true): link = BTUtil.addHttpScheme(to: text)
        case (true, false): text = link
        case (true, true): break
        case (false, false): break
        }
        
        let changeType: BTURLEditBoardChangeType
        switch (text == originalData.text, link == originalData.link) {
        case (true, true): changeType = .none
        case (false, true): changeType = .onlyText
        case (true, false): changeType = .onlyLink
        case (false, false): changeType = .both
        }
        
        if let atInfo = atInfo, atInfo.href == link, atInfo.at == text {
            self.delegate?.urlEditBoardDidFinish(contentType: .atInfo(atInfo))
        } else {
            self.delegate?.urlEditBoardDidFinish(contentType: .normal(data: BTURLEditBoardViewModel(text: text, link: link),
                                                                      changeType: changeType))
        }
    }
    
    private func doPaste() {
        guard let url = SKPasteboard.string(psdaToken: PSDATokens.Pasteboard.base_link_info_text_edit_do_paste) else { return }
        guard urlItemView.content.isEmpty else { return }
        urlParser.parseAtInfoFormURL(url) { [weak self] atInfo in
            guard let self = self, let atInfo = atInfo, self.textItemView.content.isEmpty else {
                return
            }
            self.atInfo = atInfo
            self.atInfo?.href = url
            self.textItemView.content = atInfo.at
        }
    }
    
    private func setupViews() {
        self.backgroundColor = UDColor.bgFloat
        self.layer.ud.setShadow(type: .s4Up)
        self.layer.cornerRadius = 12
        self.layer.maskedCorners = .top
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(selfPressed))
        self.addGestureRecognizer(tapGR)
        
        toolBar.didPressClose = { [weak self] in
            self?.delegate?.urlEditBoardDidCancel(isByClose: true)
        }
        toolBar.didPressComplete = {[weak self] in
            self?.handleCompleteAction()
        }
        
        urlItemView.pasteOperation = {[weak self] in
            self?.doPaste()
        }
        
        self.addSubview(toolBar)
        self.addSubview(dividerLineView)
        self.addSubview(itemsContainerView)
    }

    private func setupLayouts() {
        toolBar.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.height.equalTo(48)
        }
        
        dividerLineView.snp.makeConstraints {
            $0.top.equalTo(toolBar.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(1 / SKDisplay.scale)
        }
        
        itemsContainerView.snp.makeConstraints {
            $0.top.equalTo(dividerLineView.snp.bottom).offset(16)
            $0.left.right.bottom.equalToSuperview().inset(16)
        }
    }
}
