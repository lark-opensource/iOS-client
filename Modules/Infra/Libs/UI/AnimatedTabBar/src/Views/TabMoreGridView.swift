//
//  TabMoreGridView.swift
//  AnimatedTabBar
//
//  Created by phoenix on 2023/9/15.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignFont

public enum TabMoreGridLayoutType: String {
    // 未定义
    case none
    // 口字布局
    case one
    // 吕字布局
    case two
    // 品字布局
    case three
    // 器字布局
    case four
}

public class TabMoreGridView: UIView {

    private var layoutType: TabMoreGridLayoutType = .none

    public var tabBarItems: [AbstractTabBarItem] = [] {
        didSet { reloadData() }
    }

    /// 顶部导航栏容器
    lazy var quickItemViewA: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        return view
    }()
    
    lazy var quickItemViewB: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        return view
    }()
    
    lazy var quickItemViewC: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        return view
    }()
    
    lazy var quickItemViewD: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        return view
    }()

    lazy var quickItemEmptyView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    init(tabBarItems: [AbstractTabBarItem]) {
        self.tabBarItems = tabBarItems
        super.init(frame: .zero)
        setupSubview()
        reloadData()
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubview() {
        self.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
        self.layer.cornerRadius = 7
        self.clipsToBounds = true
        addSubview(quickItemViewA)
        addSubview(quickItemViewB)
        addSubview(quickItemViewC)
        addSubview(quickItemViewD)
        addSubview(quickItemEmptyView)
    }

    public func reloadData() {
        let items = self.tabBarItems
        let oldLayout = layoutType
        if items.count >= 4 {
            layoutType = .four
            quickItemViewA.image = items[0].stateConfig.quickBarIcon
            quickItemViewB.image = items[1].stateConfig.quickBarIcon
            quickItemViewC.image = items[2].stateConfig.quickBarIcon
            quickItemViewD.image = items[3].stateConfig.quickBarIcon
            quickItemEmptyView.image = nil
        } else if items.count == 3 {
            layoutType = .three
            quickItemViewA.image = items[0].stateConfig.quickBarIcon
            quickItemViewB.image = items[1].stateConfig.quickBarIcon
            quickItemViewC.image = items[2].stateConfig.quickBarIcon
            quickItemViewD.image = nil
            quickItemEmptyView.image = nil
        } else if items.count == 2 {
            layoutType = .two
            quickItemViewA.image = items[0].stateConfig.quickBarIcon
            quickItemViewB.image = items[1].stateConfig.quickBarIcon
            quickItemViewC.image = nil
            quickItemViewD.image = nil
            quickItemEmptyView.image = nil
        } else if items.count == 1 {
            layoutType = .one
            quickItemViewA.image = items[0].stateConfig.quickBarIcon
            quickItemViewB.image = nil
            quickItemViewC.image = nil
            quickItemViewD.image = nil
            quickItemEmptyView.image = nil
        } else {
            layoutType = .none
            let placeHolder = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.iconN3)
            quickItemViewA.image = placeHolder
            quickItemViewB.image = placeHolder
            quickItemViewC.image = placeHolder
            quickItemViewD.image = placeHolder
            quickItemEmptyView.image = UDIcon.getIconByKey(.moreLauncherOutlined, iconColor: UIColor.ud.iconN3)
        }
        if oldLayout != layoutType {
            layout()
        }
    }

    private func layout() {
        let width = (Cons.gridViewSize.width - Cons.padding * 2) / 2 - 1
        self.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.05)
        self.layer.cornerRadius = 7
        self.clipsToBounds = true
        if layoutType == .one {
            // 口字布局
            quickItemViewA.isHidden = false
            quickItemViewB.isHidden = true
            quickItemViewC.isHidden = true
            quickItemViewD.isHidden = true
            quickItemEmptyView.isHidden = true
            quickItemViewA.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(Cons.padding)
                make.leading.equalToSuperview().offset(Cons.padding)
                make.bottom.equalToSuperview().offset(-Cons.padding)
                make.trailing.equalToSuperview().offset(-Cons.padding)
                
            }
        } else if layoutType == .two {
            // 吕字布局
            quickItemViewA.isHidden = false
            quickItemViewB.isHidden = false
            quickItemViewC.isHidden = true
            quickItemViewD.isHidden = true
            quickItemEmptyView.isHidden = true
            quickItemViewA.snp.remakeConstraints { make in
                make.width.height.equalTo(width)
                make.leading.equalToSuperview().offset(Cons.padding)
                make.centerY.equalToSuperview()
            }
            quickItemViewB.snp.remakeConstraints { make in
                make.width.height.equalTo(width)
                make.trailing.equalToSuperview().offset(-Cons.padding)
                make.centerY.equalToSuperview()
            }
        } else if layoutType == .three {
            // 品字布局
            quickItemViewA.isHidden = false
            quickItemViewB.isHidden = false
            quickItemViewC.isHidden = false
            quickItemViewD.isHidden = true
            quickItemEmptyView.isHidden = true
            quickItemViewA.snp.remakeConstraints { make in
                make.width.height.equalTo(width)
                make.top.equalToSuperview().offset(Cons.padding)
                make.centerX.equalToSuperview()
            }
            quickItemViewB.snp.remakeConstraints { make in
                make.width.height.equalTo(width)
                make.leading.equalToSuperview().offset(Cons.padding)
                make.bottom.equalToSuperview().offset(-Cons.padding)
            }
            quickItemViewC.snp.remakeConstraints { make in
                make.width.height.equalTo(width)
                make.trailing.equalToSuperview().offset(-Cons.padding)
                make.bottom.equalToSuperview().offset(-Cons.padding)
            }
        } else if layoutType == .four {
            // 器字布局
            quickItemViewA.isHidden = false
            quickItemViewB.isHidden = false
            quickItemViewC.isHidden = false
            quickItemViewD.isHidden = false
            quickItemEmptyView.isHidden = true
            quickItemViewA.snp.remakeConstraints { make in
                make.width.height.equalTo(width)
                make.top.equalToSuperview().offset(Cons.padding)
                make.leading.equalToSuperview().offset(Cons.padding)
            }
            quickItemViewB.snp.remakeConstraints { make in
                make.width.height.equalTo(width)
                make.top.equalToSuperview().offset(Cons.padding)
                make.trailing.equalToSuperview().offset(-Cons.padding)
            }
            quickItemViewC.snp.remakeConstraints { make in
                make.width.height.equalTo(width)
                make.leading.equalToSuperview().offset(Cons.padding)
                make.bottom.equalToSuperview().offset(-Cons.padding)
            }
            quickItemViewD.snp.remakeConstraints { make in
                make.width.height.equalTo(width)
                make.trailing.equalToSuperview().offset(-Cons.padding)
                make.bottom.equalToSuperview().offset(-Cons.padding)
            }
        } else {
            quickItemViewA.isHidden = true
            quickItemViewB.isHidden = true
            quickItemViewC.isHidden = true
            quickItemViewD.isHidden = true
            quickItemEmptyView.isHidden = false
            quickItemEmptyView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(Cons.padding)
                make.leading.equalToSuperview().offset(Cons.padding)
                make.bottom.equalToSuperview().offset(-Cons.padding)
                make.trailing.equalToSuperview().offset(-Cons.padding)
            }
            self.backgroundColor = UIColor.clear
            self.layer.cornerRadius = 0
            self.clipsToBounds = false
        }
    }
}

extension TabMoreGridView {

    enum Cons {
        static let gridViewSize: CGSize = .square(28)
        static let padding: CGFloat = 4
    }

}
