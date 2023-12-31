import EENavigator
import Foundation
import SKBrowser
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignColor
import SpaceInterface

struct ColorPanelModel: BTDDUIPlayload, BTWidgetModelProtocol, Codable {
    
    struct ColorModel: Codable {
        
        var color: String
        
        var id: Int
        
        var textColor: String
        
    }
    
    struct PopoverLocation: Codable {
        
        var x: CGFloat
        
        var y: CGFloat
        
        var width: CGFloat
        
        var height: CGFloat
        
    }
    
    var colors: [ColorModel]
    
    var selectedColor: ColorModel
    
    var optionID: String
    
    var onClick: String?
    
    var backgroundColor: String?
    
    var borderColor: String?
    
    var location: PopoverLocation?
    
}

final class FormColorPanelComponent: BTDDUIComponentProtocol {

    typealias UIModel = ColorPanelModel
    
    private var controller: BTOptionColorSelectController?
    
    weak private var tempView: UIView?
    
    static func convert(from payload: Any?) throws -> ColorPanelModel {
        try CodableUtility.decode(ColorPanelModel.self, withJSONObject: payload ?? [:])
    }
    
    func mount(with model: ColorPanelModel) throws {
        let colorSelectView = BTOptionColorSelectController(
            colors: model
                .colors
                .map({ color in
                    BTColorModel(
                        color: color.color,
                        id: color.id,
                        textColor: color.textColor
                    )
                }),
            selectedColor: BTColorModel(
                color: model.selectedColor.color,
                id: model.selectedColor.id,
                textColor: model.selectedColor.textColor
            ),
            text: BundleI18n.SKResource.Lark_Core_custmoized_groupavatar_color,
            optionID: model.optionID,
            hostVC: context?.navigator?.currentBrowserVC
        )
        
        let onClick = model.onClick ?? ""
        colorSelectView.callback = { [weak self] (color, optionID) in
            let args: [String: Any] = [
                "color": [
                    "color": color.color,
                    "id": color.id,
                    "textColor": color.textColor
                ],
                "optionID": optionID
            ]
            self?.context?.emitEvent(onClick, args: args)

        }
        
        colorSelectView.onCloseColorPanel = { [weak self] in
            self?.onUnmounted()
            
            self?.tempView?.removeFromSuperview()
        }
        
        guard let from = context?.navigator?.currentBrowserVC as? BrowserViewController else {
            throw BTDDUIError.componentMountFailed
        }
        
        if SKDisplay.pad, from.isMyWindowRegularSize() {
            if let location = model.location {
                
                let targetRect = CGRect(
                    x: location.x,
                    y: location.y,
                    width: location.width,
                    height: location.height
                )
                
                let containerView = from.editor.editorView

                let tempTargetView = UIView(frame: targetRect)
                tempView = tempTargetView
                tempTargetView.backgroundColor = .clear
                containerView.addSubview(tempTargetView)
                tempTargetView.snp.makeConstraints { (make) in
                    make.left.equalTo(containerView.safeAreaLayoutGuide.snp.left).offset(targetRect.minX)
                    make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top).offset(targetRect.minY)
                    make.height.equalTo(targetRect.height)
                    make.width.equalTo(targetRect.width)
                }
                colorSelectView.modalPresentationStyle = .popover
                colorSelectView.popoverPresentationController?.backgroundColor = UDColor.bgFloat
                colorSelectView.popoverPresentationController?.sourceView = tempTargetView
                colorSelectView.popoverPresentationController?.sourceRect = tempTargetView.bounds
                colorSelectView.popoverPresentationController?.permittedArrowDirections = [.up, .down]
                colorSelectView.preferredContentSize = CGSize(width: 380, height: 160)
                
            } else {
                colorSelectView.modalPresentationStyle = .formSheet
                colorSelectView.preferredContentSize = CGSize(width: 380, height: 160)
            }
        } else {
            colorSelectView.modalPresentationStyle = .overFullScreen
            colorSelectView.transitioningDelegate = colorSelectView.panelTransitioningDelegate
        }
        
        Navigator.shared.present(colorSelectView, from: from)
        
        controller = colorSelectView
    }
    
    func setData(with model: ColorPanelModel) throws {
    }
    
    func unmount() {
        controller?.dismiss(animated: true)
        
    }
    
}
