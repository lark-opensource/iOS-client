//
//  SegmentedTableViewContentable.swift
//  SegmentedTableView
//
//  Created by Hayden Wang on 2021/6/28.
//

import Foundation
import UIKit
import UniverseDesignTabs

public protocol SegmentedTableViewContentable: UIViewController, UDTabsListContainerViewDelegate {

    var segmentTitle: String { get }
    var scrollableView: UIScrollView { get }
    var contentViewDidScroll: ((UIScrollView) -> Void)? { get set }
}

public class SegmentedTableViewContent: UIViewController, SegmentedTableViewContentable {

    public var segmentTitle: String = ""

    public var scrollableView: UIScrollView = UIScrollView()

    public var contentViewDidScroll: ((UIScrollView) -> Void)?

    public func listView() -> UIView {
        return UIView()
    }
}
