//
//  SheetAttachmentListPanel.swift
//  SKSheet
//
//  Created by lijuyou on 2022/6/5.
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

protocol SheetAttachmentListPanelDelegate: AnyObject {
    func onHidePanel()
    func didSelectAttachment(info: SheetAttachmentInfo, callback: String)
    func onClickToolkitButton()
    func onClickKeyboardButton()
    func onSizeChange(isShow: Bool, height: CGFloat)
}

class SheetAttachmentListPanel: DraggableBottomView, UITableViewDataSource, UITableViewDelegate {
    
    public weak var delegate: SheetAttachmentListPanelDelegate?
    private var callbackFunc: String?
    
    struct Layout {
        static let contentMarginTop: CGFloat = 6 //原始12,但图标内有8的padding
        static let textContainerInset = UIEdgeInsets(top: 0, left: 16, bottom: 50, right: 12)
    }
    
    var listModel: [SheetAttachmentInfo] = []
    // 当选中对应的选项时，先将自己消失。
    var shouldDismissWhenItemIsSelected: Bool = false
    private let reuseID = "sheet.attachment.list.cell"
    private let minCellHeight: CGFloat = 56
   
    
    private lazy var toolkitButton: UIButton = {
        let button = FloatPrimaryButton(id: .toolkit)
        _ = button.rx.tap.subscribe(onNext: { [weak self] _ in self?.didPressToolkitButton() })
        return button
    }()
    
    private lazy var keyboardButton: UIButton = {
        let button = FloatSecondaryButton(id: .keyboard)
        _ = button.rx.tap.subscribe(onNext: { [weak self] _ in self?.didPressKeyboardButton() })
        return button
    }()
    
    /// 上部空白区域（用来响应点击 dismiss 事件
    lazy var blankView = UIView().construct { it in
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss))
        it.addGestureRecognizer(tapGestureRecognizer)
    }
    
    /// 附件列表本体
    lazy var listView = UITableView(frame: .zero, style: .plain).construct { it in
        it.backgroundColor = UDColor.bgBody
        it.register(SheetAttachmentListCell.self, forCellReuseIdentifier: reuseID)
        it.isScrollEnabled = true
        it.separatorColor = UDColor.lineDividerDefault
        it.dataSource = self
        it.delegate = self
        it.layer.masksToBounds = true
        it.clipsToBounds = true
        it.separatorStyle = .none
        it.estimatedRowHeight = 56
        it.rowHeight = UITableView.automaticDimension
    }
    
    
    override var canDragUp: Bool { true }
    
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
        
        hostView.addSubview(blankView)
        blankView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(self.snp.top)
        }
        
        hostView.addSubview(toolkitButton)
        toolkitButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(40)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(self.snp.top).offset(-16)
        }
        
        hostView.addSubview(keyboardButton)
        keyboardButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(40)
            make.right.equalTo(toolkitButton.snp.left).offset(-16)
            make.bottom.equalTo(self.snp.top).offset(-16)
        }
        
        self.addSubview(listView)
        listView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.equalTo(self.safeAreaLayoutGuide)
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-16)
        }
    }
    
    override func hide(immediately: Bool, completion: (() -> Void)? = nil) {
        super.hide(immediately: immediately) {
            self.toolkitButton.removeFromSuperview()
            self.keyboardButton.removeFromSuperview()
            self.blankView.removeFromSuperview()
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
    func tapToDismiss() {
        self.hide(immediately: true)
    }
    
    func update(info: [SheetAttachmentInfo], hideToolkitItem: Bool, hideKeyboardItem: Bool, callbackFunc: String?) {
        guard let hostView = self.hostView else { return }
        self.callbackFunc = callbackFunc
        self.toolkitButton.isHidden = hideToolkitItem
        self.keyboardButton.isHidden = hideKeyboardItem
        
        let curWidth = hostView.bounds.width - hostView.safeAreaInsets.right - hostView.safeAreaInsets.left
        guard curWidth > 0 else {
            DocsLogger.error("cell panel width error")
            return
        }
        
        listModel = info
        listView.reloadData()
        
        let contentHeight = minCellHeight * CGFloat(info.count) + self.headerViewHeight + Layout.contentMarginTop + hostView.safeAreaInsets.bottom + 16
        self.updateContentHeight(contentHeight)

    }
    
    func update(hideToolkitItem: Bool, hideKeyboardItem: Bool) {
        self.toolkitButton.isHidden = hideToolkitItem
        self.keyboardButton.isHidden = hideKeyboardItem
    }
    
    func didPressToolkitButton() {
        self.delegate?.onClickToolkitButton()
    }
    
    func didPressKeyboardButton() {
        self.delegate?.onClickKeyboardButton()
    }
    
    // MARK: - UITableViewDataSource, UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let callbackFunc = callbackFunc else {
            return
        }

        if shouldDismissWhenItemIsSelected {
            self.hide(immediately: true) {
                self.delegate?.didSelectAttachment(info: self.listModel[indexPath.row], callback: callbackFunc)
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            self.delegate?.didSelectAttachment(info: self.listModel[indexPath.row], callback: callbackFunc)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listModel.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        if let cell = cell as? SheetAttachmentListCell {
            let model = listModel[indexPath.row]
            cell.reloadInfo(model)
        }
        return cell
    }
}
