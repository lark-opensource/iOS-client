//
//  TopBarExetndBarComponent.swift
//  ByteView
//
//  Created by liujianlong on 2023/1/12.
//

import UIKit
import UniverseDesignColor
import SnapKit

extension InMeetViewContainer {
    var topExtendContainerComponent: TopExtendContainerComponent? {
        self.component(by: .topExtendContainer) as? TopExtendContainerComponent
    }
}

protocol TopExtendContainerDelegate: AnyObject {
    func notifyComponentChanged(_ component: UIView&TopExtendContainerSubcomponent)
}

protocol TopExtendContainerSubcomponent: AnyObject {
    var hideInFullScreenMode: Bool { get }
    var isFloating: Bool { get }
    var delegate: TopExtendContainerDelegate? { get set }
}

private class TouchableView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for child in self.subviews {
            let childPoint = self.convert(point, to: child)
            if child.isUserInteractionEnabled && child.point(inside: childPoint, with: event) {
                return true
            }
        }
        return false
    }
}

// 提供 topExtendContainerGuide
class TopExtendContainerComponent: InMeetViewComponent, InMeetViewChangeListener, TopExtendContainerDelegate {
    enum Component: Int, Equatable {
        case webinarRehearsal
        case shareContent
    }
    // disable-lint: magic number
    var padding: UIEdgeInsets = UIEdgeInsets(top: 8.0,
                                             left: Display.pad ? 8.0 : 7.0,
                                             bottom: 4.0,
                                             right: Display.pad ? 8.0 : 7.0)
    // enable-lint: magic number
    var spacing: CGFloat = 8.0

    var componentIdentifier: InMeetViewComponentIdentifier {
        .topExtendContainer
    }

    var sceneMode: InMeetSceneManager.SceneMode {
        didSet {
            guard self.sceneMode != oldValue else {
                return
            }
            self.updateBGColor()
        }
    }

    var meetingLayoutStyle: MeetingLayoutStyle {
        didSet {
            guard self.meetingLayoutStyle != oldValue else {
                return
            }
            updateChildComponentsLayout()
            self.updateBGColor()
        }
    }

    private let view = TouchableView()
    private lazy var bgView = UIView()
    private var components = [Component: UIView & TopExtendContainerSubcomponent]()
    private weak var container: InMeetViewContainer?
    private let topExtendBarGuideToken: MeetingLayoutGuideToken
    private let topFloatingExtendBarGuideToken: MeetingLayoutGuideToken
    let guide: UILayoutGuide
    let floatingGuide: UILayoutGuide
    var currentLayoutType: LayoutType

    required init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.topExtendBarGuideToken = container.layoutContainer.registerAnchor(anchor: .topExtendBar)
        self.topFloatingExtendBarGuideToken = container.layoutContainer.registerAnchor(anchor: .topFloatingExtendBar)
        self.guide = topExtendBarGuideToken.layoutGuide
        self.floatingGuide = topFloatingExtendBarGuideToken.layoutGuide
        self.meetingLayoutStyle = container.meetingLayoutStyle
        self.sceneMode = container.sceneMode
        self.container = container
        self.currentLayoutType = layoutContext.layoutType
        self.bgView.isUserInteractionEnabled = false
        self.view.addSubview(bgView)
        container.addContent(view, level: .topExtendContainer)
        self.setupInitialConstraints(container: container)
        self.updateBGColor()
        container.context.addListener(self, for: [.contentScene])
    }

    private var hasNonFloatingChildComponent: Bool = false {
        didSet {
            guard self.hasNonFloatingChildComponent != oldValue else {
                return
            }
            self.updateBGColor()
        }
    }

    private func updateBGColor() {
        self.bgView.backgroundColor = UIColor.ud.bgBody
        self.bgView.isHidden = self.meetingLayoutStyle == .tiled
        // nolint-next-line: magic number
        self.bgView.alpha = self.meetingLayoutStyle != .tiled && hasNonFloatingChildComponent ? 0.92 : 0.0
        if self.meetingLayoutStyle == .overlay {
            bgView.vc.addOverlayShadow(isTop: true)
        } else {
            bgView.vc.removeOverlayShadow()
        }
    }

    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        self.meetingLayoutStyle = container.meetingLayoutStyle
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.currentLayoutType = newContext.layoutType
        self.updateChildComponentsLayout()
    }

    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        guard let container = self.container else {
            return
        }
        switch change {
        case .contentScene:
            self.sceneMode = container.sceneMode
        case .flowShrunken:
            self.updateBGColor()
        default:
            break
        }
    }

    func notifyComponentChanged(_ component: UIView & TopExtendContainerSubcomponent) {
        self.updateChildComponentsLayout()
    }

    private func setupInitialConstraints(container: InMeetViewContainer) {
        bgView.snp.remakeConstraints { make in
            make.top.equalTo(container.topBarGuide.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        container.topExtendContainerGuide.snp.remakeConstraints { make in
            make.edges.equalTo(self.guide)
        }
        self.guide.snp.remakeConstraints { make in
            make.left.right.bottom.equalTo(container.topBarGuide)
            make.top.equalTo(container.topBarGuide.snp.bottom)
        }
        updateChildComponentsLayout()
    }


    func addChild(_ child: UIView&TopExtendContainerSubcomponent, for component: Component) {
        guard components[component] !== child else {
            return
        }
        if let oldComponent = components.removeValue(forKey: component) {
            oldComponent.removeFromSuperview()
        }
        child.delegate = self
        components[component] = child
        updateChildComponentsLayout()
    }

    func removeChild(for component: Component) {
        guard let oldComponent = components.removeValue(forKey: component) else {
            return
        }
        oldComponent.removeFromSuperview()
        updateChildComponentsLayout()
    }

    // nolint: long_function
    private func updateChildComponentsLayout() {
        guard let container = self.container else { return }
        let sortedViews = components.keys.sorted(by: { $0.rawValue < $1.rawValue }).map { components[$0]! }
        let lastNonFloatingChild = sortedViews.last(where: { !$0.isFloating && !(self.meetingLayoutStyle == .fullscreen && $0.hideInFullScreenMode) })
        var prevChild: UIView?
        let floatingChildren = sortedViews.filter({ $0.isFloating })
        let notFloatingChildren = sortedViews.filter({ !$0.isFloating })
        for child in notFloatingChildren {
            child.backgroundColor = .clear
            if self.meetingLayoutStyle == .fullscreen && child.hideInFullScreenMode {
                child.alpha = 0.0
                if child.superview != nil {
                    // 过渡动画效果
                    child.snp.remakeConstraints { make in
                        make.top.equalToSuperview().offset(child.frame.origin.y)
                        make.left.equalToSuperview().offset(child.frame.origin.x)
                        make.size.equalTo(child.frame.size)
                    }
                }
                continue
            }
            child.alpha = 1.0
            self.view.insertSubview(child, aboveSubview: prevChild ?? self.bgView)
            child.snp.remakeConstraints { make in
                if let prev = prevChild {
                    make.top.equalTo(prev.snp.bottom).offset(spacing)
                } else {
                    make.top.equalToSuperview().offset(padding.top)
                }
                make.left.equalToSuperview().offset(padding.left)
                make.right.equalToSuperview().offset(-padding.right)
                if child === lastNonFloatingChild {
                    make.bottom.equalToSuperview().offset(-padding.bottom)
                }
            }
            prevChild = child
        }
        var firstFloatingChild: UIView?
        var lastFloatingChild: UIView?
        prevChild = nil
        for child in floatingChildren {
            if self.meetingLayoutStyle == .fullscreen && child.hideInFullScreenMode {
                child.alpha = 0.0
                continue
            }
            child.alpha = 1.0
            self.view.addSubview(child)
            child.snp.remakeConstraints { make in
                if let prev = prevChild {
                    make.top.equalTo(prev.snp.bottom).offset(spacing)
                } else {
                    if firstFloatingChild == nil {
                        firstFloatingChild = child
                    }
                    if currentLayoutType.isPhoneLandscape {
                        make.top.equalTo(container.contentGuide).offset(8.0)
                    } else {
                        if let lastNonFloatingChild = lastNonFloatingChild {
                            if container.meetingLayoutStyle.isOverlayFullScreen {
                                make.top.equalTo(lastNonFloatingChild.snp.bottom).offset(16.0)
                            } else {
                                make.top.equalTo(lastNonFloatingChild.snp.bottom).offset(20.0)
                            }
                        } else {
                            make.top.equalTo(container.contentGuide).offset(8.0)
                        }
                    }
                }
                make.left.equalToSuperview().offset(padding.left)
                make.right.equalToSuperview().offset(-padding.right)
            }
            prevChild = child
            lastFloatingChild = child
        }
        self.hasNonFloatingChildComponent = lastNonFloatingChild != nil
        if lastNonFloatingChild == nil {
            self.view.snp.remakeConstraints { make in
                make.top.greaterThanOrEqualTo(container.topBarGuide.snp.bottom)
                make.top.equalTo(container.topBarGuide.snp.bottom).priority(.veryHigh)
                make.top.greaterThanOrEqualTo(container.view.safeAreaLayoutGuide)
                make.top.equalTo(container.view.safeAreaLayoutGuide).priority(.veryHigh)
                make.left.right.equalToSuperview()
                // 过渡动画效果
                make.height.equalTo(self.view.bounds.height)
            }
            self.guide.snp.remakeConstraints { make in
                make.left.right.bottom.equalTo(container.topBarGuide)
                make.top.equalTo(container.topBarGuide.snp.bottom)
            }
        } else {
            self.view.snp.remakeConstraints { make in
                make.top.greaterThanOrEqualTo(container.topBarGuide.snp.bottom)
                make.top.equalTo(container.topBarGuide.snp.bottom).priority(.veryHigh)
                make.top.greaterThanOrEqualTo(container.view.safeAreaLayoutGuide)
                make.top.equalTo(container.view.safeAreaLayoutGuide).priority(.veryHigh)
                make.left.right.equalToSuperview()
            }
            self.guide.snp.remakeConstraints { make in
                make.edges.equalTo(self.view)
            }
        }

        if let firstFloatingChild = firstFloatingChild, let lastFloatingChild = lastFloatingChild {
            self.floatingGuide.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(firstFloatingChild.snp.top)
                make.bottom.equalTo(lastFloatingChild.snp.bottom)
            }
        } else {
            self.floatingGuide.snp.remakeConstraints { make in
                make.left.right.top.equalTo(container.view.safeAreaLayoutGuide)
                make.bottom.equalTo(container.view.safeAreaLayoutGuide.snp.top)
            }
        }
    }
}
