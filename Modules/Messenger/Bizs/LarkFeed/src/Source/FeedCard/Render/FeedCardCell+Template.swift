//
//  FeedCardCell+Template.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/5/11.
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

// MARK: - 坑位，创建组件并添加到对应的坑位
extension FeedCardCell {
    // 配置view(子容器)属性
    func setup() {
        self.clipsToBounds = true
        // 禁用Cell自带选中态/高亮: Cell自带选中态/高亮的会使subView的背景色都置为clear
        selectionStyle = .none
        setupBackgroundViews(highlightOn: true)
        titleContainerView.axis = .horizontal
        titleContainerView.alignment = .center
        titleContainerView.distribution = .fill
        titleContainerView.spacing = FeedCardLayoutCons.titleSpace

        statusContainerView.axis = .horizontal
        statusContainerView.alignment = .center
        statusContainerView.distribution = .fill

        subTitleContainerView.axis = .horizontal
        subTitleContainerView.alignment = .center
        subTitleContainerView.distribution = .fill
        subTitleContainerView.spacing = FeedCardLayoutCons.subTitleSpace

        digestContainerView.axis = .horizontal
        digestContainerView.alignment = .center
        digestContainerView.distribution = .fill
        digestContainerView.spacing = FeedCardLayoutCons.digestSpace
        // 尝试解决 stack view 出现布局错位的问题
        digestContainerView.isBaselineRelativeArrangement = true
    }

    // 布局view(子容器)
    func layout(singleLineHeightMap: [FeedCardComponentType: CGFloat]) {
        swipeView.addSubview(avatarView)
        swipeView.addSubview(topContainerView)

        swipeView.addSubview(titleContainerView)
        swipeView.addSubview(statusContainerView)

        let subTitleBGView = UIView()
        subTitleBGView.addSubview(subTitleContainerView)
        swipeView.addSubview(subTitleBGView)

        let digestBGView = UIView()
        digestBGView.addSubview(digestContainerView)
        swipeView.addSubview(digestBGView)

        let bottomBGView = UIView()
        bottomBGView.addSubview(bottomContainerView)
        swipeView.addSubview(bottomBGView)

        avatarView.snp.makeConstraints { make in
            make.top.equalTo(titleContainerView)
            make.leading.equalToSuperview().offset(FeedCardLayoutCons.hMargin)
        }

        topContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(FeedCardLayoutCons.vNaviMargin)
            make.leading.equalTo(avatarView.snp.trailing).offset(FeedCardLayoutCons.avatarTitlePadding)
            make.trailing.equalToSuperview().offset(-FeedCardLayoutCons.hMargin)
            make.height.equalTo(singleLineHeightMap[.navigation] ?? 0)
        }

        titleContainerView.snp.makeConstraints { make in
            make.top.equalTo(topContainerView.snp.bottom).offset(FeedCardLayoutCons.vTitleMargin)
            make.leading.equalTo(avatarView.snp.trailing).offset(FeedCardLayoutCons.avatarTitlePadding)
            make.trailing.lessThanOrEqualTo(statusContainerView.snp.leading).offset(-FeedCardLayoutCons.titleStatusPadding)
            make.height.equalTo(FeedCardTitleComponentView.Cons.titleHeight)
        }

        statusContainerView.snp.makeConstraints { make in
            make.centerY.equalTo(titleContainerView)
            make.trailing.equalToSuperview().offset(-(FeedCardLayoutCons.hMargin))
        }

        subTitleBGView.snp.makeConstraints { make in
            make.top.equalTo(titleContainerView.snp.bottom)
            make.leading.equalTo(titleContainerView)
            make.trailing.lessThanOrEqualToSuperview().offset(-FeedCardLayoutCons.hMargin)
        }

        subTitleContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(FeedCardLayoutCons.lineSpace)
            make.leading.bottom.trailing.equalToSuperview()
            make.height.equalTo(singleLineHeightMap[.subtitle] ?? 0)
        }

        digestBGView.snp.makeConstraints { make in
            make.top.equalTo(subTitleBGView.snp.bottom)
            make.leading.equalTo(titleContainerView)
            make.trailing.equalToSuperview().offset(-FeedCardLayoutCons.hMargin)
        }

        digestContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(FeedCardLayoutCons.lineSpace)
            make.leading.bottom.trailing.equalToSuperview()
            make.height.equalTo(singleLineHeightMap[.digest] ?? 0)
        }

        bottomBGView.snp.makeConstraints { make in
            make.top.equalTo(digestBGView.snp.bottom)
            make.leading.equalTo(titleContainerView)
            make.trailing.equalToSuperview().offset(-FeedCardLayoutCons.hMargin)
        }

        bottomContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset((FeedCardLayoutCons.lineSpace))
            make.leading.bottom.trailing.equalToSuperview()
            make.height.equalTo(singleLineHeightMap[.cta] ?? 0)
        }
    }

    // 创建并组装各个 sub view 到指定的坑位里
    func loadAllSubviews(
        componentFactories: [FeedCardComponentType: FeedCardBaseComponentFactory],
        packInfo: FeedCardComponentPackInfo) {
        // 按顺序和坑位来组装
        loadView(componentTypesOrder: packInfo.avatarArea,
                 containerView: self.avatarView,
                 componentFactories: componentFactories)
        loadView(componentTypesOrder: packInfo.topArea,
                 containerView: self.topContainerView,
                 componentFactories: componentFactories)
        loadView(componentTypesOrder: packInfo.titleArea,
                 containerView: self.titleContainerView,
                 componentFactories: componentFactories)
        loadView(componentTypesOrder: packInfo.statusArea,
                 containerView: self.statusContainerView,
                 componentFactories: componentFactories)
        loadView(componentTypesOrder: packInfo.subTitleArea,
                 containerView: self.subTitleContainerView,
                 componentFactories: componentFactories)
        loadView(componentTypesOrder: packInfo.digestArea,
                 containerView: self.digestContainerView,
                 componentFactories: componentFactories)
        loadView(componentTypesOrder: packInfo.bottomArea,
                 containerView: self.bottomContainerView,
                 componentFactories: componentFactories)
    }
}

// MARK: - 处理组件间依赖关系
extension FeedCardCell {
    // 处理互斥逻辑：
    // 方法1: module：存在重复代码，且vo生成比较麻烦
    // 方法2: 在module上再加一层，用来处理这种逻辑？
    // 方法3: component：跟组件间隔离产生了冲突
    // 方法4: 将多个冲突组件写在一个大的组件里，在大的组件里写互斥逻辑
    // 方法5: ✅框架内：引入了业务逻辑，且只处理了互斥逻辑，更广泛的组件间依赖没有处理好
    func handleComponentsRelation(
        componentVMMap: [FeedCardComponentType: FeedCardBaseComponentVM],
        subViewsMap: [FeedCardComponentType: UIView]) {
        var isFindFirstVisibleView = false
        FeedCardComponentPackInfo.statusShowOrder.forEach({ componentType in
            guard let componentVM = componentVMMap[componentType] as? FeedCardStatusVisible,
                  let view = subViewsMap[componentType] else { return }
            if isFindFirstVisibleView {
                view.isHidden = true
            } else {
                view.isHidden = !componentVM.isVisible
                if componentVM.isVisible {
                    isFindFirstVisibleView = true
                }
            }
        })
    }

    func handleStatusRelation(statusShowOrder: [FeedCardComponentType],
                              componentVMMap: [FeedCardComponentType: FeedCardBaseComponentVM],
                              subViewsMap: [FeedCardComponentType: UIView]) {
        var isFindFirstVisibleView = false
        statusShowOrder.forEach({ componentType in
            guard let componentVM = componentVMMap[componentType] as? FeedCardStatusVisible,
                  let view = subViewsMap[componentType] else { return }
            if isFindFirstVisibleView {
                view.isHidden = true
            } else {
                view.isHidden = !componentVM.isVisible
                if componentVM.isVisible {
                    isFindFirstVisibleView = true
                }
            }
        })
    }
}
