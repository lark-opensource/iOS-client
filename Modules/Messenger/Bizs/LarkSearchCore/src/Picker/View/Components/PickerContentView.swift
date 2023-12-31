//
//  PickerContentView.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/4/6.
//

import UIKit
import SnapKit

class PickerContentView: UIView {
    private var navigationBar: UIView
    private var headerView: UIView?
    private var selectionView: UIView?
    private var topView: UIView?
    private var listView: UIView
    private var defaultView: UIView?

    private let stackView = UIStackView()
    private let listContainer = UIView()

    private var context: PickerContext
    init(context: PickerContext,
         navigationBar: UIView,
         headerView: UIView? = nil,
         selectionView: UIView? = nil,
         topView: UIView? = nil,
         defaultView: UIView, listView: UIView) {
        self.context = context
        self.navigationBar = navigationBar
        self.headerView = headerView
        self.selectionView = selectionView
        self.topView = topView
        self.listView = listView
        self.defaultView = defaultView
        super.init(frame: .zero)
        render()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
        self.backgroundColor = UIColor.ud.bgBase
        stackView.axis = .vertical
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        navigationBar.backgroundColor = UIColor.ud.bgBody
        stackView.addArrangedSubview(navigationBar)

        if let headerView = headerView {
            stackView.addArrangedSubview(headerView)
        }
        if let selectedView = selectionView {
            let borderView = UIView(frame: CGRect.zero)
            selectedView.addSubview(borderView)
            borderView.backgroundColor = UIColor.ud.commonTableSeparatorColor
            borderView.snp.makeConstraints { make in
                make.bottom.equalTo(0)
                make.leading.equalTo(selectedView).priority(.low)
                make.trailing.equalTo(selectedView).priority(.low)
                make.height.equalTo(1 / UIScreen.main.scale)
            }
            stackView.addArrangedSubview(selectedView)
        }
        if context.featureConfig.searchBar.hasBottomSpace {
            let space = UIView()
            space.snp.makeConstraints {
                $0.height.equalTo(8)
            }
            stackView.addArrangedSubview(space)
        }
        if let topView = topView {
            stackView.addArrangedSubview(topView)
        }

        stackView.addArrangedSubview(listContainer)
        if let defaultView = defaultView {
            listContainer.addSubview(defaultView)
            defaultView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }
        listContainer.addSubview(listView)
        listView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
