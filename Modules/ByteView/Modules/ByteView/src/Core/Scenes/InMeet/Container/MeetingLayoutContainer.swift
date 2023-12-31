//
//  MeetingFloatingContainer.swift
//  ByteView
//
//  Created by liujianlong on 2023/3/29.
//

import UIKit
import SnapKit
import ByteViewCommon
import RxSwift

extension Logger {
    static let container = getLogger("Container")
}

enum InMeetLayoutAnchor: Int, Hashable {
    case top = 0
    case topSafeArea
    case topSingleVideoNaviBar // 单流放大的导航栏，独立的全屏导航栏
    case topNavigationBar
    case topExtendBar    // 彩排 bar https://www.figma.com/file/n55LvX7qptBy8DGfD3iFIN
    case topShrinkBar    // 缩略视图模式下, 向上折叠
    case topShareBar
    case topFloatingStatusBar // 顶部录制、转录等悬浮状态条
    case topFloatingExtendBar // 悬浮的彩排 bar

    case left
    case leftSafeArea
    case rightSafeArea
    case right

    case invisibleBottomShareBar // 白板 bottom bar 隐藏时，需要保持占位
    case reactionButton // 表情按钮初始位置，聊天和表情气泡需要基于此按钮布局

    case bottomSubtitle
    case bottomSketchBar
    case bottomShareBar
    case bottomToolbar
    case bottomSafeArea
    case bottom
}

private extension InMeetLayoutAnchor {
    static func <= (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue <= rhs.rawValue
    }

    static func >= (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue >= rhs.rawValue
    }
}

// TODO: @liujianlong support query layoutContainer property
enum ContainerLayoutEvent: Hashable {
    case orientation
    case contentMode
    case toggleSingleVideo
    case meetingLayoutStyle
    case horizontalRegular
}

protocol LayoutContextProtocol {
    var contentMode: InMeetSceneManager.ContentMode { get }
    var interfaceOrientation: UIInterfaceOrientation { get }
    var isLandscapeOrientation: Bool { get }
    var meetingLayoutStyle: MeetingLayoutStyle { get }
    var horizontalIsRegular: Bool { get }
    var isSingleVideoVisible: Bool { get }
}

struct LayoutContextPropertyHolder {
    var interfaceOrientation: UIInterfaceOrientation
    var isLandscapeOrientation: Bool
    var contentMode: InMeetSceneManager.ContentMode
    var meetingLayoutStyle: MeetingLayoutStyle
    var horizontalIsRegular: Bool
    var isSingleVideoVisible: Bool
}

private class LayoutContext: LayoutContextProtocol {
    init(properties: LayoutContextPropertyHolder) {
        self.properties = properties
    }
    var events: Set<ContainerLayoutEvent> = []
    let properties: LayoutContextPropertyHolder
    var interfaceOrientation: UIInterfaceOrientation {
        events.insert(.orientation)
        return properties.interfaceOrientation
    }
    var isLandscapeOrientation: Bool {
        events.insert(.orientation)
        return properties.isLandscapeOrientation
    }
    var meetingLayoutStyle: MeetingLayoutStyle {
        events.insert(.meetingLayoutStyle)
        return properties.meetingLayoutStyle
    }
    var horizontalIsRegular: Bool {
        events.insert(.horizontalRegular)
        return properties.horizontalIsRegular
    }
    var isSingleVideoVisible: Bool {
        events.insert(.toggleSingleVideo)
        return properties.isSingleVideoVisible
    }

    var contentMode: InMeetSceneManager.ContentMode {
        events.insert(.contentMode)
        return properties.contentMode
    }
}

protocol InMeetLayoutContainerAware {
    func didAttachToLayoutContainer(_ layoutContainer: InMeetLayoutContainer)
    func didDetachFromLayoutContainer(_ layoutContainer: InMeetLayoutContainer)
}

private struct FlattenGuideQuery: InMeetLayoutGuideQuery {
    private let factory: (_ context: LayoutContextProtocol) -> InMeetLayoutGuideQuery
    init(factory: @escaping (_ context: LayoutContextProtocol) -> InMeetLayoutGuideQuery) {
        self.factory = factory
    }

    func horizontalRelationWithAnchor(_ anchor: InMeetLayoutAnchor, context: LayoutContextProtocol) -> HorizontalLayoutRelation {
        factory(context).horizontalRelationWithAnchor(anchor, context: context)
    }

    func verticalRelationWithAnchor(_ anchor: InMeetLayoutAnchor, context: LayoutContextProtocol) -> VerticalLayoutRelation {
        factory(context).verticalRelationWithAnchor(anchor, context: context)
    }
}

private extension InMeetLayoutGuideQuery {
    func isAffectedByAnchor(_ anchor: InMeetLayoutAnchor, context: LayoutContextProtocol) -> Bool {
        if case .none = self.horizontalRelationWithAnchor(anchor, context: context),
           case .none = self.verticalRelationWithAnchor(anchor, context: context) {
            return false
        } else {
            return true
        }
    }
}


private struct AnoymousLayoutGuideQuery: InMeetLayoutGuideQuery {
    private let vertical: (_ bar: InMeetLayoutAnchor, _ context: LayoutContextProtocol) -> VerticalLayoutRelation
    private let horizontal: ((_ bar: InMeetLayoutAnchor, _ context: LayoutContextProtocol) -> HorizontalLayoutRelation)?

    init(vertical: @escaping (_ bar: InMeetLayoutAnchor, _ context: LayoutContextProtocol) -> VerticalLayoutRelation,
         horizontal: ((_ bar: InMeetLayoutAnchor, _ context: LayoutContextProtocol) -> HorizontalLayoutRelation)?) {
        self.vertical = vertical
        self.horizontal = horizontal
    }
    func verticalRelationWithAnchor(_ anchor: InMeetLayoutAnchor, context: LayoutContextProtocol) -> VerticalLayoutRelation {
        return self.vertical(anchor, context)
    }

    func horizontalRelationWithAnchor(_ anchor: InMeetLayoutAnchor, context: LayoutContextProtocol) -> HorizontalLayoutRelation {
        guard let block = self.horizontal else {
            let query = InMeetOrderedLayoutGuideQuery(topAnchor: .top, bottomAnchor: .bottom, leftAnchor: .left, rightAnchor: .right)
            return query.horizontalRelationWithAnchor(anchor, context: context)
        }
        return block(anchor, context)
    }
}


struct InMeetOrderedLayoutGuideQuery: InMeetLayoutGuideQuery {
    let topAnchor: InMeetLayoutAnchor
    let bottomAnchor: InMeetLayoutAnchor
    let leftAnchor: InMeetLayoutAnchor
    let rightAnchor: InMeetLayoutAnchor
    let ignoreAnchors: [InMeetLayoutAnchor]?
    let verticalInsets: CGFloat
    let horizontalInsets: CGFloat
    let specificInsets: [InMeetLayoutAnchor: CGFloat]?
    init(topAnchor: InMeetLayoutAnchor = .top,
         bottomAnchor: InMeetLayoutAnchor = .bottom,
         leftAnchor: InMeetLayoutAnchor = .left,
         rightAnchor: InMeetLayoutAnchor = .right,
         ignoreAnchors: [InMeetLayoutAnchor]? = nil,
         verticalInsets: CGFloat = 0.0,
         horizontalInsets: CGFloat = 0.0,
         specificInsets: [InMeetLayoutAnchor: CGFloat]? = nil) {
        self.topAnchor = topAnchor
        self.bottomAnchor = bottomAnchor
        self.leftAnchor = leftAnchor
        self.rightAnchor = rightAnchor
        self.ignoreAnchors = ignoreAnchors
        self.verticalInsets = verticalInsets
        self.horizontalInsets = horizontalInsets
        self.specificInsets = specificInsets
    }

    func verticalRelationWithAnchor(_ anchor: InMeetLayoutAnchor, context: LayoutContextProtocol) -> VerticalLayoutRelation {
        if let ignoreAnchors = self.ignoreAnchors,
           ignoreAnchors.contains(anchor) {
            return .none
        }
        let insets = self.specificInsets?[anchor] ?? self.verticalInsets
        if topAnchor >= anchor {
            return .below(insets)
        } else if bottomAnchor <= anchor {
            return .above(insets)
        }
        return .none
    }

    func horizontalRelationWithAnchor(_ anchor: InMeetLayoutAnchor, context: LayoutContextProtocol) -> HorizontalLayoutRelation {
        if let ignoreAnchors = self.ignoreAnchors,
           ignoreAnchors.contains(anchor) {
            return .none
        }
        let insets = self.specificInsets?[anchor] ?? self.horizontalInsets
        if leftAnchor == anchor {
            return .onRight(insets)
        } else if rightAnchor == anchor {
            return .onLeft(insets)
        }
        return .none
    }
}

enum VerticalLayoutRelation {
    case above(CGFloat)
    case below(CGFloat)
    case none
}

enum HorizontalLayoutRelation {
    case onLeft(CGFloat)
    case onRight(CGFloat)
    case none
}

protocol InMeetLayoutGuideQuery {
    func verticalRelationWithAnchor(_ anchor: InMeetLayoutAnchor, context: LayoutContextProtocol) -> VerticalLayoutRelation
    func horizontalRelationWithAnchor(_ anchor: InMeetLayoutAnchor, context: LayoutContextProtocol) -> HorizontalLayoutRelation
}

protocol InMeetLayoutContainer: AnyObject {
    func requestLayoutGuide(identifier: String,
                            query: InMeetLayoutGuideQuery) -> MeetingLayoutGuideToken

    func registerAnchor(anchor: InMeetLayoutAnchor) -> MeetingLayoutGuideToken

    func notifyEvent(event: ContainerLayoutEvent)
}

extension InMeetLayoutContainer {
    func requestLayoutGuide(query: InMeetLayoutGuideQuery, events: [ContainerLayoutEvent] = [], file: String = #fileID, line: Int = #line) -> MeetingLayoutGuideToken {
        #if DEBUG
        let identifier = "\((file as NSString).lastPathComponent):\(line)"
        #else
        let identifier = ""
        #endif
        return self.requestLayoutGuide(identifier: identifier, query: query)
    }

    func requestOrderedLayoutGuide(topAnchor: InMeetLayoutAnchor,
                                   bottomAnchor: InMeetLayoutAnchor,
                                   ignoreAnchors: [InMeetLayoutAnchor]? = nil,
                                   insets: CGFloat = 0.0,
                                   horizontalInsets: CGFloat = 0.0,
                                   specificInsets: [InMeetLayoutAnchor: CGFloat]? = nil,
                                   file: String = #fileID,
                                   line: Int = #line) -> MeetingLayoutGuideToken {
        #if DEBUG
        let identifier = "\((file as NSString).lastPathComponent):\(line)"
        #else
        let identifier = ""
        #endif
        let query = InMeetOrderedLayoutGuideQuery(topAnchor: topAnchor,
                                                  bottomAnchor: bottomAnchor,
                                                  ignoreAnchors: ignoreAnchors,
                                                  verticalInsets: insets,
                                                  horizontalInsets: horizontalInsets,
                                                  specificInsets: specificInsets)
        return self.requestLayoutGuide(identifier: identifier, query: query)
    }

    func requestLayoutGuideFactory(_ factory: @escaping (_ ctx: LayoutContextProtocol) -> InMeetLayoutGuideQuery,
                                   file: String = #fileID,
                                   line: Int = #line) -> MeetingLayoutGuideToken {

        #if DEBUG
        let identifier = "\((file as NSString).lastPathComponent):\(line)"
        #else
        let identifier = ""
        #endif
        let query = FlattenGuideQuery(factory: factory)
        return self.requestLayoutGuide(identifier: identifier, query: query)
    }

    func requestLayoutGuide(vertical: @escaping (InMeetLayoutAnchor, LayoutContextProtocol) -> VerticalLayoutRelation,
                            horizontal: ((InMeetLayoutAnchor, LayoutContextProtocol) -> HorizontalLayoutRelation)? = nil,
                            file: String = #fileID,
                            line: Int = #line) -> MeetingLayoutGuideToken {
        #if DEBUG
        let identifier = "\((file as NSString).lastPathComponent):\(line)"
        #else
        let identifier = ""
        #endif
        let query = AnoymousLayoutGuideQuery(vertical: vertical, horizontal: horizontal)
        return self.requestLayoutGuide(identifier: identifier, query: query)
    }
}

final class MeetingLayoutGuideToken {
    fileprivate init(container: MeetingLayoutContainer,
                     layoutGuide: UILayoutGuide,
                     bar: InMeetLayoutAnchor?) {
        self.container = container
        self.layoutGuide = layoutGuide
        self.bar = bar
    }

    private weak var container: MeetingLayoutContainer?
    private let bar: InMeetLayoutAnchor?
    let layoutGuide: UILayoutGuide

    func refresh() {
        guard self.bar == nil else {
            return
        }
        self.container?.updateOutputGuide(ObjectIdentifier(self.layoutGuide))
    }

    func invalidate() {
        guard let container = self.container else {
            return
        }
        Self.invalidate(container: container,
                        bar: self.bar,
                        layoutGuide: layoutGuide)
        self.container = nil
    }

    static func invalidate(container: MeetingLayoutContainer, bar: InMeetLayoutAnchor?, layoutGuide: UILayoutGuide) {
        if let bar = bar {
            container.unregisterBar(bar: bar)
        } else {
            container.removeLayoutGuide(layoutGuide)
        }
    }

    deinit {
        // fix: https://t.wtturl.cn/UgDX6kC/
        guard let container = self.container else {
            return
        }
        let bar = self.bar
        let layoutGuide = self.layoutGuide
        if Thread.isMainThread {
            Self.invalidate(container: container,
                            bar: bar,
                            layoutGuide: layoutGuide)
        } else {
            assertionFailure()
            DispatchQueue.main.async {
                Self.invalidate(container: container,
                                bar: bar,
                                layoutGuide: layoutGuide)
            }
        }
    }
}


class MeetingLayoutContainer: InMeetLayoutContainer {
    typealias OutputGuideEntry = (query: InMeetLayoutGuideQuery, interestedEvents: [ContainerLayoutEvent], guide: UILayoutGuide)

    private let disposeBag = DisposeBag()
    private let view: UIView
    private var anchorGuides: [InMeetLayoutAnchor: UILayoutGuide] = [:]
    private var barCount: [InMeetLayoutAnchor: Int] = [:]
    private var contextProperties: LayoutContextPropertyHolder

    private var outputGuides: [ObjectIdentifier: OutputGuideEntry] = [:]

    private var eventListeners: [ContainerLayoutEvent: Set<ObjectIdentifier>] = [:]
    weak var container: InMeetViewContainer?

    init(containerView: UIView) {
        self.view = containerView
        self.contextProperties = LayoutContextPropertyHolder(interfaceOrientation: .portrait,
                                                             isLandscapeOrientation: false,
                                                             contentMode: .flow,
                                                             meetingLayoutStyle: .fullscreen,
                                                             horizontalIsRegular: false,
                                                             isSingleVideoVisible: false)
    }

    func requestLayoutGuide(identifier: String,
                            query: InMeetLayoutGuideQuery) -> MeetingLayoutGuideToken {

        let guide = UILayoutGuide()
        guide.identifier = identifier

        self.view.addLayoutGuide(guide)

        let entry: OutputGuideEntry = (query: query, interestedEvents: [], guide: guide)
        self.outputGuides[ObjectIdentifier(guide)] = entry

        self.updateOutputGuide(entry: entry)

        return MeetingLayoutGuideToken(container: self, layoutGuide: guide, bar: nil)
    }

    fileprivate func removeLayoutGuide(_ layoutGuide: UILayoutGuide) {
        // https://t.wtturl.cn/UDBvDR4/ 概率会非主线程走到这，具体原因需要case by case分析
        Util.runInMainThread { [weak self] in
            if let view = layoutGuide.owningView {
                view.removeLayoutGuide(layoutGuide)
            }
            self?.outputGuides.removeValue(forKey: ObjectIdentifier(layoutGuide))
        }
    }


    func registerAnchor(anchor: InMeetLayoutAnchor) -> MeetingLayoutGuideToken {
        let count = self.barCount[anchor] ?? 0
        self.barCount[anchor] = count + 1
        if let guide = self.anchorGuides[anchor] {
            Logger.container.warn("duplicate register \(anchor)")
            return MeetingLayoutGuideToken(container: self, layoutGuide: guide, bar: anchor)
        }
        Logger.container.info("register \(anchor)")

        let guide = UILayoutGuide()
        self.anchorGuides[anchor] = guide
        guide.identifier = "\(anchor)"
        self.view.addLayoutGuide(guide)

        var affectedOutputGuides: [OutputGuideEntry] = []

        for entry in outputGuides.values {
            if entry.query.isAffectedByAnchor(anchor, context: self.context) {
                affectedOutputGuides.append(entry)
            }
        }
        affectedOutputGuides.forEach(updateOutputGuide)
        return MeetingLayoutGuideToken(container: self, layoutGuide: guide, bar: anchor)
    }

    fileprivate func unregisterBar(bar: InMeetLayoutAnchor) {
        let cnt = self.barCount[bar] ?? 0
        if cnt <= 0 {
            assertionFailure()
            return
        }

        self.barCount[bar] = cnt - 1
        if cnt > 1 {
            return
        }

        guard let guide = self.anchorGuides.removeValue(forKey: bar) else {
            Logger.container.info("unregister \(bar) not exists")
            return
        }
        Logger.container.info("unregister \(bar)")

        self.view.removeLayoutGuide(guide)

        var affectedOutputGuides: [OutputGuideEntry] = []
        for entry in outputGuides.values {
            if entry.query.isAffectedByAnchor(bar, context: self.context) {
                affectedOutputGuides.append(entry)
            }
        }
        affectedOutputGuides.forEach(updateOutputGuide)
    }

    fileprivate func updateOutputGuide(_ identifier: ObjectIdentifier) {
        guard let outputGuideEntry = self.outputGuides[identifier] else {
            return
        }
        updateOutputGuide(entry: outputGuideEntry)
    }

    private var context: LayoutContext {
        LayoutContext(properties: self.contextProperties)
    }

    func notifyEvent(event: ContainerLayoutEvent) {
        guard let listeners = self.eventListeners[event],
              !listeners.isEmpty else {
            return
        }
        let entries = listeners.compactMap { self.outputGuides[$0] }
        for entry in entries {
            self.updateOutputGuide(entry: entry)
        }
    }

    private func updateOutputGuide(entry: OutputGuideEntry) {
        let ctx = self.context
        let guide = entry.guide
        let query = entry.query
        guide.snp.remakeConstraints { make in
            for (bar, barGuide) in self.anchorGuides {
                switch query.verticalRelationWithAnchor(bar, context: ctx) {
                case .above(let inset):
                    make.bottom.lessThanOrEqualTo(barGuide.snp.top).offset(-inset)
                    make.bottom.equalTo(barGuide.snp.top).offset(-inset).priority(.veryHigh)
                case .below(let inset):
                    make.top.greaterThanOrEqualTo(barGuide.snp.bottom).offset(inset)
                    make.top.equalTo(barGuide.snp.bottom).offset(inset).priority(.veryHigh)
                case .none:
                    break
                }

                switch query.horizontalRelationWithAnchor(bar, context: ctx) {
                case .onLeft(let inset):
                    make.right.lessThanOrEqualTo(barGuide.snp.left).offset(-inset)
                    make.right.equalTo(barGuide.snp.left).offset(-inset).priority(.veryHigh)
                case .onRight(let inset):
                    make.left.greaterThanOrEqualTo(barGuide.snp.right).offset(inset)
                    make.left.equalTo(barGuide.snp.right).offset(inset).priority(.veryHigh)
                case .none:
                    break
                }
            }

            if case .onRight(let inset) = query.horizontalRelationWithAnchor(.left, context: ctx) {
                make.left.greaterThanOrEqualTo(self.view.snp.left).offset(inset)
                make.left.equalTo(self.view.snp.left).offset(inset).priority(.veryHigh)
            }
            if case .onRight(let inset) = query.horizontalRelationWithAnchor(.leftSafeArea, context: ctx) {
                make.left.greaterThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.left).offset(inset)
                make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left).offset(inset).priority(.veryHigh)
            }

            if case .onLeft(let inset) = query.horizontalRelationWithAnchor(.right, context: ctx) {
                make.right.lessThanOrEqualTo(self.view.snp.right).offset(-inset)
                make.right.equalTo(self.view.snp.right).offset(-inset).priority(.veryHigh)
            }

            if case .onLeft(let inset) = query.horizontalRelationWithAnchor(.rightSafeArea, context: ctx) {
                make.right.lessThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.right).offset(-inset)
                make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right).offset(-inset).priority(.veryHigh)
            }

            if case .below(let inset) = query.verticalRelationWithAnchor(.top, context: ctx) {
                make.top.greaterThanOrEqualTo(self.view.snp.top).offset(inset)
                make.top.equalTo(self.view.snp.top).offset(inset).priority(.veryHigh)
            }
            if case .below(let inset) = query.verticalRelationWithAnchor(.topSafeArea, context: ctx) {
                make.top.greaterThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.top).offset(inset)
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(inset).priority(.veryHigh)
            }

            if case .above(let inset) = query.verticalRelationWithAnchor(.bottom, context: ctx) {
                make.bottom.lessThanOrEqualTo(self.view.snp.bottom).offset(-inset)
                make.bottom.equalTo(self.view.snp.bottom).offset(-inset).priority(.veryHigh)
            }

            if case .above(let inset) = query.verticalRelationWithAnchor(.bottomSafeArea, context: ctx) {
                make.bottom.lessThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-inset)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-inset).priority(.veryHigh)
            }
        }
        let identifier = ObjectIdentifier(entry.guide)
        for oldInterestedEvent in entry.interestedEvents {
            if !ctx.events.contains(oldInterestedEvent) {
                var listenerSet = self.eventListeners[oldInterestedEvent]
                listenerSet?.remove(identifier)
                self.eventListeners[oldInterestedEvent] = listenerSet
            }
        }
        for newInterestedEvent in ctx.events {
            var listernerSet = self.eventListeners[newInterestedEvent] ?? []
            listernerSet.insert(identifier)
            self.eventListeners[newInterestedEvent] = listernerSet
        }

        self.outputGuides[ObjectIdentifier(entry.guide)] = OutputGuideEntry(query: entry.query, interestedEvents: entry.interestedEvents, guide: entry.guide)
    }
}

extension MeetingLayoutContainer: InMeetViewChangeListener, MeetingSceneModeListener {
    func setupEvents(container: InMeetViewContainer) {
        self.container = container
        container.context.addListener(self, for: [.containerLayoutStyle, .singleVideo])
        container.addMeetSceneModeListener(self)
        InMeetOrientationToolComponent.statusBarOrientationRelay
            .asObservable()
            .subscribe { [weak self] orientation in
                self?.contextProperties.interfaceOrientation = orientation
                self?.contextProperties.isLandscapeOrientation = orientation.isLandscape
                self?.notifyEvent(event: .orientation)
            }
            .disposed(by: disposeBag)
    }

    func containerDidChangeContentMode(container: InMeetViewContainer, contentMode: InMeetSceneManager.ContentMode) {
        self.contextProperties.contentMode = contentMode
        self.notifyEvent(event: .contentMode)
    }

    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        guard let container = self.container else {
            return
        }
        switch change {
        case .containerLayoutStyle:
            self.contextProperties.meetingLayoutStyle = container.context.meetingLayoutStyle
            self.notifyEvent(event: .meetingLayoutStyle)
        case .singleVideo:
            self.contextProperties.isSingleVideoVisible = container.context.isSingleVideoVisible
            self.notifyEvent(event: .toggleSingleVideo)
        default:
            break
        }
    }
}
