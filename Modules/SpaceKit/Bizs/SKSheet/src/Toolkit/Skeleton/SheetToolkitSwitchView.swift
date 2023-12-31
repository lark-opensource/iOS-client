//
// Created by duanxiaochen.7 on 2019/7/28.
// Affiliated with SpaceKit.
//
// Description: Sheet Redesign - Toolkit Panel - Toolkit Tab Menu

import Foundation
import SKCommon
import SKUIKit

protocol SheetToolkitSwitchViewDelegate: AnyObject {
    func didClickNormalButton(_ btn: String, byUser: Bool, view: SheetToolkitSwitchView)
    func didClickDisableButton(_ btn: String, byUser: Bool, view: SheetToolkitSwitchView)
    func didClickBack(view: SheetToolkitSwitchView)
    func shouldDisplayRedPoint(_ buttonIdentitifer: String) -> Bool
}

extension SheetToolkitSwitchViewDelegate {
    func shouldDisplayRedPoint(_ buttonIdentitifer: String) -> Bool { return false }
}

class SheetToolkitSwitchView: UIView {

    struct ButtonModel {
        var title: String = ""
        var identifier: String = ""
        var enable = false
        func equalTo(_ another: ButtonModel) -> Bool {
            return self.title == another.title && self.identifier == another.identifier && self.enable == another.enable
        }
    }

    class TapButton: UIButton {
        var tapId: String = ""
        var titleWidth: CGFloat {
            let text = self.titleLabel?.text ?? ""
            return text.estimatedSingleLineUILabelWidth(in: UIFont.systemFont(ofSize: 17, weight: .medium))
        }
    }

    enum ButtonStatus {
        case highlighted
        case normal
        case disabled

        var color: UIColor {
            switch self {
            case .highlighted:
                return UIColor.ud.colorfulBlue
            case .normal:
                return UIColor.ud.N900
            case .disabled:
                return UIColor.ud.N400
            }
        }

        var font: UIFont {
            return UIFont.systemFont(ofSize: 17, weight: .medium)
        }
    }

    weak var delegate: SheetToolkitSwitchViewDelegate?
    var buttonModels = [ButtonModel]()
    var tapId: String?
    var lastHighlightedButton: TapButton?
    var indicatorView = SheetToolKitIndicatorView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        clipsToBounds = true
        setupIndicatorView()
    }
    
    func setupIndicatorView() {
        addSubview(indicatorView)
        indicatorView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(2)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ models: [ButtonModel], preferWidth: CGFloat?) {
        guard shouldUpdate(newModels: models) else { return }
        buttonModels = models
        subviews.forEach {
            if let tapView = $0 as? TapButton {
                tapView.removeFromSuperview()
            }
        }
        //根据models数量均分，左右各留15%的空白
        var width = preferWidth ?? self.frame.size.width
        let windowWidth = SKDisplay.activeWindowBounds.width
        if width < 100 { width = windowWidth }
        let widthRatio = (0.8 / CGFloat(models.count)) * 0.6
        let itemWidth = width * (0.8 / CGFloat(models.count))
        let buttonWidth = width * widthRatio
        let padding = (itemWidth - buttonWidth) / 2
        var leftOffset = padding + width * 0.1
        refreshTapIdIfNeed()
        var buttonFrames: [CGRect] = []
        var titleWidths: [CGFloat] = []
        var highlightedIdx = 0
        for (index, model) in models.enumerated() {
            let btn = makeButton(title: model.title, identifier: model.identifier, enable: model.enable)
            addSubview(btn)
            btn.snp.makeConstraints { (make) in
                make.width.equalTo(buttonWidth)
                make.height.equalTo(24)
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(leftOffset)
            }
            showGuideIfNeed(btn: btn)
            buttonFrames.append(CGRect(x: leftOffset, y: 0, width: buttonWidth, height: 0))
            titleWidths.append(btn.titleWidth)
            leftOffset += buttonWidth
            leftOffset += (padding * 2)
            if tapId == nil,
               model.enable {
                tapId = model.identifier
                setButtonStatus(button: btn, status: .highlighted)
                lastHighlightedButton = btn
                highlightedIdx = index
            } else if btn.tapId == tapId {
                setButtonStatus(button: btn, status: .highlighted)
                lastHighlightedButton = btn
                highlightedIdx = index
            }
        }
        indicatorView.update(pageWidth: width,
                             buttonFrames: buttonFrames,
                             titleWidths: titleWidths)
        indicatorView.reset(to: highlightedIdx)
        bringSubviewToFront(indicatorView)
    }

    func shouldUpdate(newModels: [ButtonModel]) -> Bool {
        let oldModels = buttonModels
        guard newModels.count > 0 else { return false }
        if newModels.count != oldModels.count { return true }
        var allMatch = true
        for i in 0..<newModels.count {
            if oldModels[i].equalTo(newModels[i]) == false {
                allMatch = false
            }
        }
        return !allMatch
    }

    func makeButton(title: String, identifier: String, enable: Bool) -> TapButton {
        let btn = TapButton().construct { it in
            it.backgroundColor = .clear
            it.tapId = identifier
            it.isAccessibilityElement = true
            it.accessibilityIdentifier = "sheets.toolkit.tab.\(identifier)"
            it.accessibilityLabel = "sheets.toolkit.tab.\(identifier)"
            it.setTitle(title, for: .normal)
            it.setTitle(title, for: .highlighted)
            it.addTarget(self, action: #selector(didClickButton(_:)), for: .touchUpInside)
            it.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            it.titleLabel?.adjustsFontSizeToFitWidth = true
            it.docs.addStandardHighlight()
        }
        setButtonStatus(button: btn, status: .normal)
        if !enable {
            setButtonStatus(button: btn, status: .disabled)
        }
        return btn
    }

    private func refreshTapIdIfNeed() {
        guard let lastButtonIdentifier = tapId, let info = buttonInfo(by: lastButtonIdentifier) else { return }
        tapId = info.enable ? tapId : nil
    }

    private func showGuideIfNeed(btn: TapButton) {
        let showGuide = delegate?.shouldDisplayRedPoint(btn.tapId) ?? false
        if showGuide {
            let pointView = SheetOperationGuideView(frame: .zero)
            btn.titleLabel?.addSubview(pointView)
            if pointView.superview != nil {
                pointView.snp.makeConstraints { (make) in
                    make.width.height.equalTo(8)
                    make.top.equalToSuperview().offset(-4)
                    make.right.equalToSuperview().offset(4)
                }
            }
        }
    }

    func setButtonStatus(button: TapButton?, status: ButtonStatus) {
        button?.setTitleColor(status.color, for: .highlighted)
        button?.setTitleColor(status.color, for: .normal)
        button?.titleLabel?.font = status.font
        guard let label = button?.titleLabel else { return }
        switch status {
        case .highlighted:
            for view in label.subviews where view as? SheetOperationGuideView != nil {
                view.removeFromSuperview()
            }
        case .normal, .disabled:
            for view in label.subviews {
                view.removeFromSuperview()
            }
        }
    }

    @objc
    func didClickButton(_ sender: TapButton) {
        handleClick(sender, byUser: true)
    }

    func mockClickButton(tapId: String, byUser: Bool = false) {
        let dstButton = subviews.first(where: { (view) -> Bool in
            let dstView = view as? TapButton
            return dstView?.tapId == tapId
        }) as? TapButton
        guard let button = dstButton else { return }
        handleClick(button, byUser: byUser)
    }

    private func handleClick(_ button: TapButton, byUser: Bool) {
        guard let model = buttonInfo(by: button.tapId), model.enable else {
            delegate?.didClickDisableButton(button.tapId, byUser: byUser, view: self)
            return
        }
        setButtonStatus(button: button, status: .highlighted)
        if let lastId = lastHighlightedButton?.tapId, lastId != button.tapId {
            let lastButtonEnable = buttonInfo(by: lastId)?.enable ?? false
            let status: ButtonStatus = lastButtonEnable ? .normal : .disabled
            setButtonStatus(button: lastHighlightedButton, status: status)
        }
        tapId = button.tapId
        lastHighlightedButton = button
        delegate?.didClickNormalButton(button.tapId, byUser: byUser, view: self)
    }

    private func buttonInfo(by identifier: String) -> ButtonModel? {
        return self.buttonModels.first { (model) -> Bool in
            return model.identifier == identifier
        }
    }
}

extension SheetToolkitSwitchView {
    
    func vcScrollViewDidScroll(_ scrollView: UIScrollView) {
        indicatorView.scrollViewDidScroll(offset: scrollView.contentOffset.x)
    }
    
}

class SheetOperationGuideView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 4
        backgroundColor = UIColor.ud.colorfulRed
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
