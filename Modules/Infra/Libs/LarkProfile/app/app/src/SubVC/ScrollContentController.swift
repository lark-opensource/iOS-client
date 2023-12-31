//
//  ScrollContentController.swift
//  SegmentedTableView
//
//  Created by Hayden on 2021/6/24.
//

import Foundation
import UIKit
import LarkProfile

class ScrollContentController: UIViewController {

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceHorizontal = false
        scrollView.delegate = self
        return scrollView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        print("Scroll VC did load")

        // Do any additional setup after loading the view.
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let view1 = UIView()
        view1.backgroundColor = .systemRed
        view1.frame = CGRect(x: 10, y: 10, width: view.bounds.width - 20, height: 150)

        let view2 = UIView()
        view2.backgroundColor = .systemOrange
        view2.frame = CGRect(x: 10, y: 170, width: view.bounds.width - 20, height: 150)

        let view3 = UIView()
        view3.backgroundColor = .systemYellow
        view3.frame = CGRect(x: 10, y: 330, width: view.bounds.width - 20, height: 150)

        let view4 = UIView()
        view4.backgroundColor = .systemGreen
        view4.frame = CGRect(x: 10, y: 490, width: view.bounds.width - 20, height: 150)

        let view5 = UIView()
        view5.backgroundColor = .systemBlue
        view5.frame = CGRect(x: 10, y: 650, width: view.bounds.width - 20, height: 150)

        let view6 = UIView()
        if #available(iOS 13.0, *) {
            view6.backgroundColor = .systemIndigo
        } else {
            view6.backgroundColor = .blue
        }
        view6.frame = CGRect(x: 10, y: 810, width: view.bounds.width - 20, height: 150)

        let view7 = UIView()
        view7.backgroundColor = .systemPurple
        view7.frame = CGRect(x: 10, y: 970, width: view.bounds.width - 20, height: 150)

        scrollView.contentSize = CGSize(width: view.bounds.width, height: 1_130)

        scrollView.addSubview(view1)
        scrollView.addSubview(view2)
        scrollView.addSubview(view3)
        scrollView.addSubview(view4)
        scrollView.addSubview(view5)
        scrollView.addSubview(view6)
        scrollView.addSubview(view7)

        scrollView.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Scroll VC did appear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("Scroll VC did disappear")
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        print("Scroll VC init")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("Scroll VC deinit")
    }

    var contentViewDidScroll: ((UIScrollView) -> Void)?
}

extension ScrollContentController: SegmentedTableViewContentable {

    public func listView() -> UIView {
        return view
    }

    var segmentTitle: String {
        "ContentView"
    }

    var scrollableView: UIScrollView {
        scrollView
    }
}

extension ScrollContentController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        contentViewDidScroll?(scrollView)
    }
}
