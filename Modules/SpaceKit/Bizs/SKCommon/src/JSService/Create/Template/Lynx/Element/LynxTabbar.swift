//
//  LynxTabbar.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/9.
//  


import Foundation
import Lynx
import UIKit
import SnapKit
import UniverseDesignTabs
import UniverseDesignColor

protocol LynxTabbarDelegate: NSObject {
    func tabbarDidSelectIndex(_ index: Int)
}

class LynxTabbar: LynxUI<UIView> {
    weak var delegate: LynxTabbarDelegate?
    private(set) lazy var tabView: UDTabsTitleView = {
        let view = TabsTitleView()
        view.delegate = self
        view.indicators = [UDTabsIndicatorLineView()]
        let tabConfig = view.getConfig()
        tabConfig.itemWidthIncrement = 2
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UDColor.lineDividerDefault
        view.addSubview(bottomBorder)
        bottomBorder.snp.updateConstraints { (make) in
            make.leading.bottom.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        return view
    }()
    static let name = "ud-tabbar"
    override var name: String {
        return Self.name
    }
    
    override func createView() -> UIView {
        let view = UIView()
        view.addSubview(tabView)
        tabView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }
}

extension LynxTabbar: UDTabsViewDelegate {
    func tabsView(_ tabsView: UDTabsView, didClickSelectedItemAt index: Int) {
        delegate?.tabbarDidSelectIndex(index)
        notifyLynx(selectIndex: index, isClick: true)
    }
    private func notifyLynx(selectIndex: Int, isClick: Bool) {
        let detail: [String: Any] = [
            "index": selectIndex,
            "scene": isClick ? "click" : "slide"
        ]
        let event = LynxDetailEvent(name: "change", targetSign: self.sign, detail: detail)
        self.context?.eventEmitter?.send(event)
    }
}

class TabsTitleView: UDTabsTitleView {
    
    public override func registerCellClass(in tabsView: UDTabsView) {
        tabsView.collectionView.register(TabsTitleCell.self, forCellWithReuseIdentifier: "cell")
    }
    
    public override func tabsView(cellForItemAt index: Int) -> UDTabsBaseCell {
        let cell = super.tabsView(cellForItemAt: index)
        if let titleCell = cell as? TabsTitleCell {
            titleCell.index = index
            titleCell.delegate = self
        }
        return cell
    }
}

extension TabsTitleView: TabsTitleCellDelegate {
    func didClick(at index: Int) {
        guard selectedIndex != index else { return }
        selectItemAt(index: index, selectedType: .click)
    }
}

protocol TabsTitleCellDelegate: NSObject {
    func didClick(at index: Int)
}

class TabsTitleCell: UDTabsTitleCell {
    var index: Int = 0
    var button: UIButton = UIButton(type: .custom)
    weak var delegate: TabsTitleCellDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func buttonAction() {
        delegate?.didClick(at: index)
    }
}
