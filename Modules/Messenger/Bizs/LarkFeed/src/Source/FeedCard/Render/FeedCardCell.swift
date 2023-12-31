//
//  FeedCardCell.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2022/12/5.
//

import Foundation
import UIKit
import LarkOpenFeed
import LarkFeedBase
import LarkContainer
import LarkSwipeCellKit
import RustPB
import LarkSceneManager
import LarkModel
import LarkUIKit
import UniverseDesignTheme
import UniverseDesignColor

final class FeedCardCell: SwipeTableViewCell {
    // 各个坑位子容器
    let avatarView = UIView()
    let topContainerView = UIView()
    let titleContainerView = UIStackView()
    let statusContainerView = UIStackView()
    let subTitleContainerView = UIStackView()
    let digestContainerView = UIStackView()
    let bottomContainerView = UIView()

    // 绑定的viewModel
    private(set) var cellViewModel: FeedCardCellViewModel?
    // 对应的业务方
    private(set) var module: FeedCardBaseModule?
    // sub views 集合
    private(set) var subViewsMap: [FeedCardComponentType: UIView] = [:]
    private(set) var componentViewsMap: [FeedCardComponentType: FeedCardBaseComponentView] = [:]

    // 事件监听
    private(set) var eventListeners: [FeedCardEventType: [FeedCardComponentType]] = [:]

    // 记录单行高度
    private var singleLineHeightMap: [FeedCardComponentType: CGFloat] =
    [.navigation: 0,
     .subtitle: 0,
     .digest: 0,
     .cta: 0]
    // 单行代表view
    private var containerViewMap: [FeedCardComponentType: UIView] = [:]
    // 默认背景色
    lazy var defaultColor: UIColor = {
        return UIColor.ud.bgBody
    }()
    /*
     https://stackoverflow.com/questions/6745919/uitableviewcell-subview-disappears-when-cell-is-selected
     需要自己实现选中态/高亮颜色，用UITabelViewCell自带选中态/高亮的会使subView的背景色都置为clear
     iOS12及以下设备可复现
     */
    // 点击态色
    lazy var pressColor: UIColor = {
        return UIColor.ud.fillPressed
    }()
    // 选中色 for iPad
    lazy var selectedColor: UIColor = {
        return UDMessageColorTheme.imFeedFeedFillActive
    }()
    // 临时置顶颜色
    lazy var tempTopColor: UIColor = {
        return UDColor.bgBodyOverlay
    }()

    override init(style: UITableViewCell.CellStyle,
         reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        guard let reuseIdentifier = reuseIdentifier,
              let id = Int(reuseIdentifier),
              let type = FeedPreviewType(rawValue: id) else { return }
        // TODO: 用户隔离 open feed 获取 feedCardModuleManager 的方式待优化
        guard let moduleManager = AllFeedListViewModel.feedCardModuleManager,
              let module = moduleManager.modules[type] else { return }
        self.module = module
        self.containerViewMap = [.navigation: topContainerView,
                                 .subtitle: subTitleContainerView,
                                 .digest: digestContainerView,
                                 .cta: bottomContainerView]
        self.setup()
        self.layout(singleLineHeightMap: singleLineHeightMap)
        let componentFactories = moduleManager.componentFactories
        let packInfo = module.packInfo
        self.loadAllSubviews(componentFactories: componentFactories, packInfo: packInfo)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        postEvent(eventType: .prepareForReuse, value: .none)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if !Display.pad {
            // iPad 上 cell 有 Drag 能力，关掉 highlighted 效果 UX: @彭兆元 RD: @黄浩庭
            easySetColor()
        }
        postEvent(eventType: .highlighted, value: .highlighted(highlighted))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        easySetColor()
        postEvent(eventType: .selected, value: .selected(selected))
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *),
              Display.pad,
              self.traitCollection.userInterfaceStyle != .unspecified,
              self.traitCollection.userInterfaceStyle != UDThemeManager.getRealUserInterfaceStyle() else { return }

        var view: UIView? = self
        while view != nil {
            if view?.superview?.traitCollection.userInterfaceStyle == UDThemeManager.getRealUserInterfaceStyle() {
                break
            }
            view = view?.superview
        }
        let description: String = view?.description ?? ""

        FeedSlardarTrack.trackFeedCellUserInterfaceStyle(self.traitCollection.userInterfaceStyle,
                                                         appStyle: UDThemeManager.getRealUserInterfaceStyle(),
                                                         description: description)
    }

    override var description: String {
        "\(super.description); feedID: \(cellViewModel?.feedPreview.id ?? "nil")"
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if Display.pad {
            easySetColor()
        }
    }
}

// MARK: - 组装组件
extension FeedCardCell {
    // 构造组件，cell init 时机
    func loadView(componentTypesOrder: [FeedCardComponentType],
                  containerView: UIView,
                  componentFactories: [FeedCardComponentType: FeedCardBaseComponentFactory]) {
        componentTypesOrder.forEach { type in
            guard let componentFactory = componentFactories[type] else { return }
            let componentView = componentFactory.creatView()
            let eventTypes = componentView.subscribedEventTypes()
            eventTypes.forEach { eventType in
                var componentTypes = self.eventListeners[eventType] ?? []
                componentTypes.append(componentView.type)
                self.eventListeners[eventType] = componentTypes
            }
            componentViewsMap[type] = componentView
            let view = componentView.creatView()
            subViewsMap[type] = view
            if let containerView = containerView as? UIStackView {
                containerView.addArrangedSubview(view)
                if let layoutInfo = componentView.layoutInfo {
                    view.snp.makeConstraints { make in
                        if let width = layoutInfo.width {
                            make.width.equalTo(width)
                        }
                        if let height = layoutInfo.height {
                            make.height.equalTo(height)
                        }
                    }
                    if let padding = layoutInfo.padding {
                        containerView.setCustomSpacing(padding, after: view)
                    }
                }
            } else {
                containerView.addSubview((view))
                if let layoutInfo = componentView.layoutInfo {
                    view.snp.makeConstraints { make in
                        make.edges.equalToSuperview()
                        if let width = layoutInfo.width {
                            make.width.equalTo(width)
                        }
                        if let height = layoutInfo.height {
                            make.height.equalTo(height)
                        }
                    }
                } else {
                    view.snp.makeConstraints { make in
                        make.edges.equalToSuperview()
                    }
                }
            }
        }
    }

    // 渲染组件，cell for row时机
    func render(cellVM: FeedCardCellViewModel) {
        self.cellViewModel = cellVM
        // TODO: open feed 思考组件间的通信/依赖
//        handleComponentsRelation(
//            componentVMMap: cellVM.componentVMMap,
//            subViewsMap: subViewsMap)
        renderSubViews(componentVMMap: cellVM.componentVMMap)
        handleStatusRelation(
            statusShowOrder: FeedCardComponentPackInfo.statusShowOrder, componentVMMap: cellVM.componentVMMap,
            subViewsMap: subViewsMap)
        updateContainersHeight(componentVMMap: cellVM.componentVMMap)
        easySetColor()
    }

    // 渲染各个子组件view
    private func renderSubViews(componentVMMap: [FeedCardComponentType: FeedCardBaseComponentVM]) {
        subViewsMap.forEach { (key: FeedCardComponentType, view: UIView) in
            guard let componentView = componentViewsMap[key],
                  let componentVM = componentVMMap[key] else { return }
            componentView.updateView(view: view, vm: componentVM)
        }
        // TODO: open feed
        subViewsMap.forEach { (key: FeedCardComponentType, _) in
            guard let componentView = componentViewsMap[key],
                  let context = componentView.eventContext else { return }
            postEvent(eventType: .rendered, value: .rendered(key, context))
        }
    }

    // 记录并更新单行高度
    private func updateContainersHeight(componentVMMap: [FeedCardComponentType: FeedCardBaseComponentVM]) {
        let singleLineHeightMap = self.singleLineHeightMap
        singleLineHeightMap.forEach { (type: FeedCardComponentType, oldHeight: CGFloat) in
            guard let componentVM = componentVMMap[type] as? FeedCardLineHeight,
                  let containerView = containerViewMap[type] else { return }
            let newHeight = componentVM.height
            guard oldHeight != newHeight else { return }
            containerView.snp.updateConstraints { make in
                make.height.equalTo(newHeight)
            }
            self.singleLineHeightMap[type] = newHeight
        }
    }
}
