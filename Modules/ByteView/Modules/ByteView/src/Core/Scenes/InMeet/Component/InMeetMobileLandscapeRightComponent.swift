//
//  InMeetMobileLandscapeRightComponent.swift
//  ByteView
//
//  Created by liujianlong on 2023/8/16.
//

import UIKit

private class LandscapeRightContainerView: IrregularHittableView {


    func addWidget(_ key: Int, view: UIView?) {
        if widgets[key] == view {
            return
        }
        if let view = view {
            view.snp.removeConstraints()
            view.translatesAutoresizingMaskIntoConstraints = true
            self.addSubview(view)
        }
        widgets[key] = view
    }

    func removeWidget(_ key: Int) {
        if let view = widgets.removeValue(forKey: key),
           view?.superview === self {
            view?.removeFromSuperview()
        }
    }
    func setInterpreter(view: UIView?) {
        guard interpreterView != view else {
            return
        }
        interpreterView = view
        if let view = view {
            view.snp.removeConstraints()
            view.translatesAutoresizingMaskIntoConstraints = true
            self.addSubview(view)
        }
    }

    func updateBottomInset(_ bottomInset: CGFloat) {
        self.bottomInset = bottomInset
        layoutWidgets()
    }

    private var widgets: [Int: UIView?] = [:] {
        didSet {
            layoutWidgets()
        }
    }
    private var interpreterView: UIView? {
        didSet {
            layoutWidgets()
        }
    }
    private var bottomInset: CGFloat = 0
    private var rightInset: CGFloat = 0
    private var interpreterRightInset: CGFloat = 0
    private var buttonSpacing: CGFloat = 12.0
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutWidgets()
    }

    func layoutWidgets() {
        var (buttonRects, interpreterRect) = computeLayouts(layoutArea: self.bounds,
                                                            bottomInset: self.bottomInset,
                                                            rightInset: self.rightInset,
                                                            buttonSize: CGSize(width: 48.0, height: 48.0),
                                                            buttonSpacing: buttonSpacing,
                                                            interpreterSize: CGSize(width: 40.0, height: 75.0),
                                                            interpreterRightInset: self.interpreterRightInset,
                                                            buttonCount: widgets.count)
        if interpreterRect.minY < self.bounds.minY {
            (buttonRects, interpreterRect) = computeLayouts(layoutArea: self.bounds,
                                                            bottomInset: self.bottomInset,
                                                            rightInset: self.rightInset,
                                                            buttonSize: CGSize(width: 40.0, height: 40.0),
                                                            buttonSpacing: 8.0,
                                                            interpreterSize: CGSize(width: 40.0, height: 75.0),
                                                            interpreterRightInset: self.interpreterRightInset,
                                                            buttonCount: widgets.count)
        }

        for (idx, k) in widgets.keys.sorted().enumerated() {
            widgets[k]??.frame = buttonRects[idx]
        }
        interpreterView?.frame = interpreterRect
    }

    private func computeLayouts(layoutArea: CGRect,
                                bottomInset: CGFloat,
                                rightInset: CGFloat,
                                buttonSize: CGSize,
                                buttonSpacing: CGFloat,
                                interpreterSize: CGSize,
                                interpreterRightInset: CGFloat,
                                buttonCount: Int) -> ([CGRect], CGRect) {
        var bottomPos = layoutArea.maxY - bottomInset
        let rightPos = layoutArea.maxX - rightInset
        var buttonRects: [CGRect] = []
        for _ in 0..<buttonCount {
            let rect = CGRect(origin: CGPoint(x: rightPos - buttonSize.width,
                                              y: bottomPos - buttonSize.height),
                              size: buttonSize)
            buttonRects.append(rect)
            bottomPos -= buttonSize.height + buttonSpacing
        }

        var interpreterRect = CGRect(origin: CGPoint(x: rightPos - interpreterSize.width,
                                                     y: layoutArea.midY - interpreterSize.height * 0.5),
                                     size: interpreterSize)
        if interpreterRect.maxY > bottomPos {
            interpreterRect.origin = CGPoint(x: layoutArea.maxX - interpreterRightInset - interpreterSize.width,
                                             y: bottomPos - interpreterSize.height)
        }
        return (buttonRects, interpreterRect)
    }
}

/// 负责布局右侧组件：标注编辑、麦克风、旋转屏幕、传译
final class InMeetMobileLandscapeRightComponent: InMeetViewComponent, InMeetViewChangeListener {
    enum WidgetID: Int {
        case whiteboardEdit
        case microphone
        case orientation
        case interpreter
    }

    private let view = LandscapeRightContainerView()
    weak var container: InMeetViewContainer?

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.container = container
        container.addContent(self.view, level: .landscapeTools)
        self.view.snp.remakeConstraints { make in
            make.edges.equalTo(container.accessoryGuide)
        }

        container.context.addListener(self, for: [.whiteboardMenu, .whiteboardEditAuthority])
    }

    func containerDidLoadComponent(container: InMeetViewContainer) {
        updateWhiteboardEditBtn()
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .mobileLandscapeRightContainer
    }

    func addWidget(_ widget: WidgetID, _ view: UIView?) {
        if widget == .interpreter {
            self.view.setInterpreter(view: view)
        } else {
            self.view.addWidget(widget.rawValue, view: view)
        }
    }

    func removeWidget(_ widget: WidgetID) {
        if widget == .interpreter {
            self.view.setInterpreter(view: nil)
        } else {
            self.view.removeWidget(widget.rawValue)
        }
    }

    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        switch change {
        // TODO: @liujianlong add whiteboard edit button to view hierarchy
        case .whiteboardMenu, .whiteboardEditAuthority:
            updateWhiteboardEditBtn()
        default:
            return
        }
    }

    func updateWhiteboardEditBtn() {
        guard let context = self.container?.context else {
            return
        }
        let displayWhiteEditFloatingButton = !context.isWhiteboardMenuEnabled && context.isWhiteboardEditEnable
        if displayWhiteEditFloatingButton {
            self.addWidget(.whiteboardEdit, nil)
        } else {
            self.removeWidget(.whiteboardEdit)
        }
    }

    func updateBottomInset(_ bottomInset: CGFloat) {
        self.view.updateBottomInset(bottomInset)
    }
}
