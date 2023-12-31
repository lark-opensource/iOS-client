//
//  ViewController.swift
//  LarkPickerDemo
//
//  Created by Yuri on 2022/11/11.
//

import Foundation
import UIKit
import SnapKit
import RustPB
@testable import LarkSearchCore
// swiftlint:disable all
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        typealias SearchType = Search_V2_UniversalFilters.UserFilter.SearchType
        var searchTypeTemp = Int32(SearchType.resigned.rawValue | SearchType.unTalked.rawValue)
        let mask = ~Int32(SearchType.resigned.rawValue | SearchType.unResigned.rawValue)
        searchTypeTemp = searchTypeTemp & mask
        NSLog(" \(searchTypeTemp)")

        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .red
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .red
        var context = PickerContext()
        context.style = .picker
        let searchBar = PickerSearchBar(context: context, searchBar: textField)
        searchBar.frame = CGRect(x: 0, y: 100, width: 375, height: 56)
        searchBar.snp.makeConstraints {
            $0.height.equalTo(52)
        }
//        let defaultView = UIView()
//        defaultView.backgroundColor = .red
//        let contentView = PickerContentView(navigationBar: searchBar, defaultView: defaultView, listView: UIView())
//        view.addSubview(contentView)
//        contentView.snp.makeConstraints {
//            $0.edges.equalToSuperview()
//        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let vc = SecondViewControoler()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    @objc func injected() {
        viewDidLoad()
    }
}

class SecondViewControoler: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let searchBar = UIView()
        searchBar.backgroundColor = .lightGray
        let nav = PickerSearchBar(context: PickerContext(), searchBar: searchBar)
        nav.snp.makeConstraints { $0.height.equalTo(52) }
        let headerView = UIView()
        headerView.backgroundColor = .red
        headerView.snp.makeConstraints { $0.height.equalTo(40) }
        let selectedView = UIView()
        selectedView.backgroundColor = .blue
        selectedView.snp.makeConstraints { $0.height.equalTo(40) }
        let topView = UIView()
        topView.backgroundColor = .green
        topView.snp.makeConstraints { $0.height.equalTo(40) }
        headerView.snp.makeConstraints { $0.height.equalTo(40) }
        let contentView = PickerContentView(navigationBar: nav, headerView: headerView,
                                            selectionView: selectedView, topView: topView,
                                            defaultView: UIView(), listView: UIView())
        view.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.trailing.leading.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    @objc func injected() {
        view.subviews.forEach { $0.removeFromSuperview() }
        viewDidLoad()
    }
}
// swiftlint:enable all
