//
//  AtListContainerViewController.swift
//  SKCommon
//
//  Created by CJ on 2021/2/1.
//

import Foundation
import SKFoundation
import SpaceInterface

public final class AtListContainerViewController: UIViewController {
    private let contentWidth: CGFloat = 375
    private var dataSource: AtDataSource
    private let requestType: Set<AtDataSource.RequestType>
    private let type: AtViewType
    public var disappearCallBack: (() -> Void)?
    public var dismissCallBack: (() -> Void)?
    

    deinit {
        dismissCallBack?()
        DocsLogger.info("AtListContainerViewController deinit")
    }
    
    public lazy var atListView: AtListView = {
        let atListView = AtListView(dataSource, type: type, presentType: .popover, showCancel: self.showCancel)
        atListView.clipsToBounds = true
        return atListView
    }()
    
    var showCancel: Bool = true
    
    public init(_ dataSource: AtDataSource, type: AtViewType, requestType: Set<AtDataSource.RequestType>, showCancel: Bool = false) {
        self.dataSource = dataSource
        self.requestType = requestType
        self.type = type
        self.showCancel = showCancel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.disappearCallBack?()
        atListView.reset()
    }
    
    private func setupView() {
        view.addSubview(atListView)
        preferredContentSize = CGSize(width: contentWidth, height: 0)
        atListView.snp.makeConstraints { (make) in
            make.width.equalTo(contentWidth)
            make.top.leading.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        atListView.atTypeSelectView.setBackButton(isHidden: true)
        view.layoutIfNeeded()
        if type == .docs || type == .larkDocs, type == .syncedBlock {
            updateContentOffset(requestType: requestType)
        }
    }
    
    public func updateContentOffset(requestType: Set<AtDataSource.RequestType>) {
        atListView.atTypeSelectView.updateRequestType(to: requestType)
        atListView.updateScrollViewRequestType(to: requestType)
    }
    public func didReceiveMagicKeyboardTabAction() {
        atListView.handleMagicKeyboardTabAction()
    }
    
    public func configCheckboxData(_ checkboxData: AtCheckboxData?) {
        atListView.configCheckboxData(checkboxData, contentWidth: contentWidth)
    }
}
