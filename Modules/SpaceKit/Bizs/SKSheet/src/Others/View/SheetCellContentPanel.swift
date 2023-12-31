//
//  SheetCellContentPanel.swift
//  SKSheet
//
//  Created by lijuyou on 2022/4/7.
//


import SKFoundation
import UIKit
import RxCocoa
import RxSwift
import RxRelay
import SKCommon
import SKBrowser
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast
import SKResource

protocol SheetCellContentPanelDelegate: AnyObject {
    func onHidePanel()
    func onClickSegment(_ segment: SheetSegmentBase, callback: String)
    func onClickToolkitButton()
    func onSizeChange(isShow: Bool, height: CGFloat)
}

class SheetCellContentPanel: DraggableBottomView {
    
    public weak var delegate: SheetCellContentPanelDelegate?
    private var callbackFunc: String?
    private var copyable: Bool = false
    
    struct Layout {
        static let contentMarginTop: CGFloat = 6 //原始12,但图标内有8的padding
        static let textContainerInset = UIEdgeInsets(top: 0, left: 16, bottom: 50, right: 12)
    }
    
    public private(set) lazy var inputTextView: SheetTextView = {
        let textView = SheetTextView()
        textView.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        textView.textColor = UDColor.textTitle
        textView.backgroundColor = UDColor.bgBody
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.textContainerInset = Layout.textContainerInset
        textView.isEditable = false
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTextViewTap(sender:)))
        textView.addGestureRecognizer(tapGestureRecognizer)
        textView.textViewDelegate = self
        return textView
    }()
    
    private lazy var toolkitButton: UIButton = {
        let button = FloatPrimaryButton(id: .toolkit)
        _ = button.rx.tap.subscribe(onNext: { [weak self] _ in self?.didPressToolkitButton() })
        return button
    }()
    
    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = [] // panel这里的防护不需要toast,因为正文已经有了
        return preventer
    }()
    
    override var canDragUp: Bool { self.inputTextView.isScrollEnabled }
    
    override init(hostView: UIView) {
        super.init(hostView: hostView)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupSubViews() {
        super.setupSubViews()
        guard let hostView = self.hostView else { return }
        
        if ViewCapturePreventer.isFeatureEnable { // 视图层级 self --> contentView --> inputTextView
            let contentView = viewCapturePreventer.contentView
            addSubview(contentView)
            contentView.snp.makeConstraints { (make) in
                make.leading.equalTo(self.safeAreaLayoutGuide.snp.leading)
                make.trailing.equalTo(self.safeAreaLayoutGuide.snp.trailing)
                make.bottom.equalToSuperview()
                make.top.equalTo(headerView.snp.bottom).offset(Layout.contentMarginTop)
            }
            
            contentView.addSubview(inputTextView)
            inputTextView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        } else { // 视图层级 self --> inputTextView
            addSubview(inputTextView)
            inputTextView.snp.makeConstraints { (make) in
                make.leading.equalTo(self.safeAreaLayoutGuide.snp.leading)
                make.trailing.equalTo(self.safeAreaLayoutGuide.snp.trailing)
                make.bottom.equalToSuperview()
                make.top.equalTo(headerView.snp.bottom).offset(Layout.contentMarginTop)
            }
        }
        
        hostView.addSubview(toolkitButton)
        toolkitButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(40)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(self.snp.top).offset(-16)
        }
    }
    
    override func hide(immediately: Bool, completion: (() -> Void)? = nil) {
        super.hide(immediately: immediately) {
            self.toolkitButton.removeFromSuperview()
            completion?()
            self.delegate?.onHidePanel()
        }
    }
    
    override func onSizeChange(isShow: Bool) {
        super.onSizeChange(isShow: isShow)
        self.delegate?.onSizeChange(isShow: isShow, height: self.bounds.height)
    }
    
    
    @objc
    private func orientationDidChange() {
        self.hide(immediately: true)
    }
    
    @objc
    private func onTextViewTap(sender: UITapGestureRecognizer) {
        guard sender.state == .recognized else {
            return
        }
        guard let callbackFunc = callbackFunc else {
            return
        }
        let location = sender.location(in: self.inputTextView)
        guard let segment = inputTextView.segmentAtPoint(location) else {
            DocsLogger.error("click on empty segment")
            return
        }
        delegate?.onClickSegment(segment, callback: callbackFunc)
    }
    
    func updateContent(_ content: NSAttributedString, copyable: Bool, hideFAB: Bool, callbackFunc: String?) {
        guard let hostView = self.hostView else { return }
        self.callbackFunc = callbackFunc
        self.copyable = copyable
        self.toolkitButton.isHidden = hideFAB
        let curWidth = hostView.bounds.width - hostView.safeAreaInsets.right - hostView.safeAreaInsets.left
        guard curWidth > 0 else {
            DocsLogger.error("cell panel width error")
            return
        }
        
        self.inputTextView.attributedText = content
        let textHeight = inputTextView.sizeThatFits(CGSize(width: curWidth, height: CGFloat.greatestFiniteMagnitude)).height
        let contentHeight = textHeight + self.headerViewHeight + Layout.contentMarginTop
        self.updateContentHeight(contentHeight)
        self.inputTextView.isScrollEnabled = maxViewHeight > initViewHeight
        self.inputTextView.setContentOffset(.zero, animated: false)
    }
    
    func didPressToolkitButton() {
        self.delegate?.onClickToolkitButton()
    }
}

extension SheetCellContentPanel: SheetTextViewDelegate {
    func textViewWillResign(_ textView: SKBrowser.SheetTextView) {
        
    }
    
    func textViewCanCopy(_ textView: SheetTextView, showTips: Bool) -> Bool {
        return self.copyable
    }
    
    func textViewOnCopy(_ textView: SheetTextView) {
        guard let hostView = self.hostView else { return }
        UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_Sheets_Copied_Toast, on: hostView)
    }

    func textViewCanCut(_ textView: SheetTextView, showTips: Bool) -> Bool {
        return true
    }
}

extension SheetCellContentPanel {
    /// 设置允许被截图
    func setCaptureAllowed(_ allow: Bool) {
        DocsLogger.info("SheetCellContentPanel setCaptureAllowed => \(allow)")
        viewCapturePreventer.isCaptureAllowed = allow
    }
}
