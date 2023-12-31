//
//  BorderOperationView.swift
//  SKBrowser
//
//  Created by 吴珂 on 2020/8/17.
//  

import Foundation
import SKCommon
import SKUIKit
import SKResource
import UniverseDesignColor

public final class BorderOperationView: SKSubToolBarPanel {

    private let operationViewHeight: CGFloat = 300
    private let navigationHeight: CGFloat = 48
    private let info: ToolBarItemInfo

    lazy private var borderOperationPanel: BorderOperationPanel = {
        let view = BorderOperationPanel(frame: .zero)
        return view
    }()

    lazy private var borderOperationNavigationView: BorderOperationPanelNavigationView = {
        let view = BorderOperationPanelNavigationView(frame: .zero)
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    public init(info: ToolBarItemInfo) {
        self.info = info
        super.init(frame: .zero)
        setupSubviews()
    }

    public override func getCurrentDisplayHeight() -> CGFloat? {
        return operationViewHeight + navigationHeight
    }
    public override func showRootView() {
        self.removeFromSuperview()
    }
    
    public override var shouldShowMainPanel: Bool {
        false
    }

    private func setupSubviews() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
        layer.shadowOffset = CGSize(width: 0, height: -6)
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 24
        borderOperationPanel.delegate = self
        borderOperationNavigationView.delegate = self
        borderOperationNavigationView.updateTitle(BundleI18n.SKResource.Doc_Doc_ToolbarCellBorderLine)
        contentView.backgroundColor = UDColor.bgBody

        addSubview(borderOperationNavigationView)
        addSubview(contentView)
        contentView.addSubview(borderOperationPanel)

        contentView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
        }

        borderOperationPanel.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
            make.height.equalTo(operationViewHeight)
        }

        borderOperationNavigationView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(contentView.snp.top)
            make.height.equalTo(navigationHeight)
        }
        
        updateBorder(info: info)
    }

    private func updateBorder(info: ToolBarItemInfo?) {
        guard let info = info else { return }

        if let borderInfo = info.borderInfo {
            borderOperationPanel.updateInfos(info: borderInfo)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func refreshViewLayout() {
        borderOperationPanel.refreshLayout()
    }
}

extension BorderOperationView: BorderOperationPanelDelegate {
    public func hasUpdate(params: [String: Any], in panel: BorderOperationPanel) {
        panelDelegate?.select(item: info, update: params, view: self)
    }
}

extension BorderOperationView: BorderOperationPanelNavigationViewDelegate {
    func borderOperationPanelNavigationViewRequestExit(view: BorderOperationPanelNavigationView) {
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .push
        transition.subtype = .fromLeft
        self.superview?.layer.add(transition, forKey: nil)
        self.removeFromSuperview()
    }
}
