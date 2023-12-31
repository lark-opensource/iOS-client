//
//  BorderOperationPanel.swift
//  SKBrowser
//
//  Created by 吴珂 on 2020/8/13.
//

import Foundation
import SKCommon
import SKResource
import SKUIKit
import HandyJSON
import UniverseDesignColor
import UniverseDesignIcon

// MARK: Border Operation Panel Impl
public protocol BorderOperationPanelDelegate: AnyObject {
    func hasUpdate(params: [String: Any], in panel: BorderOperationPanel)
}

public final class BorderOperationPanel: SKSubToolBarPanel {
    public weak var delegate: BorderOperationPanelDelegate?
    
    var borderOperationPanel: BorderOperationCorePanel
    var borderColorSeparator: UIView = UIView().construct { (it) in
        it.backgroundColor = UDColor.lineDividerDefault
    }
    var colorPickCorePanel: ColorPickerCorePanel
    
    var defalultColorIndexPath: IndexPath = IndexPath(row: -1, section: -1)
    var defaultBorderTypeIndexPath: IndexPath = IndexPath(row: -1, section: -1)
    
    var borderOperationPanelHeight = 136
    
    var borderInfo = BorderInfo()

    override public init(frame: CGRect) {
        colorPickCorePanel = ColorPickerCorePanel(frame: frame, infos: [])
        colorPickCorePanel.isHiddenDetailColor = true
        borderOperationPanel = BorderOperationCorePanel()
        super.init(frame: frame)

        addSubview(borderOperationPanel)
        addSubview(colorPickCorePanel)
        addSubview(borderColorSeparator)
        borderOperationPanel.snp.makeConstraints { (make) in
            make.height.equalTo(BorderOperationCorePanel.preferredHeight)
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(colorPickCorePanel.snp.top)
        }

        borderColorSeparator.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(0.5)
            make.top.equalTo(borderOperationPanel.snp.bottom)
        }
        
        colorPickCorePanel.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(borderOperationPanelHeight)
        }
        
        colorPickCorePanel.delegate = self
        borderOperationPanel.delegate = self
    }

    public func updateInfos(info: BorderInfo) {
        borderInfo = info
        borderOperationPanel.update(dataSource: info.border ?? [])
        colorPickCorePanel.updateInfos(infos: info.color ?? [])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func reset() {
        borderOperationPanel.reset()
        colorPickCorePanel.clearColor()
    }
    
    func notifyDelegate(_ isChooseColor: Bool) {
        let params = generateParams(isChooseColor)
        delegate?.hasUpdate(params: params, in: self)
    }
    
    func generateParams(_ isChooseColor: Bool) -> [String: Any] {
        let params: [String: Any] = [
            "border": borderOperationPanel.currentBorderType,
            "color": colorPickCorePanel.currentColor,
            "choose": isChooseColor ? "color" : "border"
        ]
        return params
    }

    public func refreshLayout() {
        colorPickCorePanel.refreshViewLayout()
        borderOperationPanel.refreshViewLayout()
    }
}

extension BorderOperationPanel: ColorPickerCorePanelDelegate {
    public func didChooseColor(panel: ColorPickerCorePanel, color: String, isTapDetailColor: Bool) {
        if !borderOperationPanel.didSelect {
            borderOperationPanel.select(type: .fullborder)
        }
        notifyDelegate(true)
    }
}

extension BorderOperationPanel: BorderOperationCorePanelDelegate {
    func didSelectBorder(_ borderType: BorderType) {
        if !colorPickCorePanel.didSelect {
            colorPickCorePanel.chooseFirstColor()
            colorPickCorePanel.isHiddenDetailColor = false
        }
        notifyDelegate(false)
    }
}

protocol BorderOperationPanelNavigationViewDelegate: AnyObject {
    func borderOperationPanelNavigationViewRequestExit(view: BorderOperationPanelNavigationView)
}

class BorderOperationPanelNavigationView: PanelNavigationView {
    
    weak var delegate: BorderOperationPanelNavigationViewDelegate?
    
    @objc
    override func didClickBackButton(sender: UIButton) {
        NotificationCenter.default.post(name: Notification.Name.NavigationShowHighlightPanel, object: nil)
        delegate?.borderOperationPanelNavigationViewRequestExit(view: self)
    }
}
