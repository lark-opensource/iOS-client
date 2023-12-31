//
//  SortedActionViewController.swift
//  MailSDK
//
//  Created by ByteDance on 2023/5/9.
//

import Foundation
import LarkUIKit

typealias SortedActionCallBack = (_ sender: UIView?) -> Void

struct SortedActionSection {
    var title: String
    var isSeleted: Bool
    var actionCallBack: SortedActionCallBack
    init(title: String, isSeleted:Bool, actionCallBack: @escaping SortedActionCallBack) {
        self.title = title
        self.isSeleted = isSeleted
        self.actionCallBack = actionCallBack
    }
}

final class SortedActionViewController: WidgetViewController {
    private var sectionData: [SortedActionSection]
    private let headerTitle: String
    // MARK: - Views
    private var sortedActionView: SortedActionView?
    
    init(headerTitle:String, sectionData:[SortedActionSection]) {
        self.headerTitle = headerTitle
        self.sectionData = sectionData
        super.init(contentHeight: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        needAnimated = !isPopover
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if modalPresentationStyle == .popover {
            resetHeight(view.frame.height)
        } else {
            resetHeight(view.frame.height - Display.realTopBarHeight())
        }
    }
    
    private func setupView() {
        view.backgroundColor = .clear
        contentView.backgroundColor = .clear
        if sortedActionView == nil {
            let tempSortedActionView = SortedActionView(frame: .zero, title: headerTitle, sectionData: sectionData)
            tempSortedActionView.delegate = self
            contentView.addSubview(tempSortedActionView)
            tempSortedActionView.snp.makeConstraints { make in
                make.left.right.equalTo(contentView.safeAreaLayoutGuide)
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            if modalPresentationStyle == .popover {
                view.backgroundColor = UIColor.ud.bgBase
                contentView.backgroundColor = UIColor.ud.bgBase
                preferredContentSize = CGSize(width: 0, height: tempSortedActionView.calculateHeightForPopover())
            }
            sortedActionView = tempSortedActionView
        }
    }
}

extension SortedActionViewController: SortedActionViewDelegate {
    func didClick(section: SortedActionSection) {
        animatedView(isShow: false) {
            section.actionCallBack(nil)
        }
    }
    
    func didClickMask() {
        animatedView(isShow: false)
    }
}

extension SortedActionViewController {
    static func makeSortedActionVC(headerTitle:String, sectionData: [SortedActionSection], popoverSourceView: UIView?) -> UIViewController {
        let sortedVC = SortedActionViewController(headerTitle: headerTitle, sectionData:sectionData)
        if let popoverSourceView = popoverSourceView {
            sortedVC.needAnimated = false
            sortedVC.modalPresentationStyle = .popover
            sortedVC.popoverPresentationController?.sourceView = popoverSourceView
            sortedVC.popoverPresentationController?.sourceRect = popoverSourceView.bounds

        }
        return sortedVC
    }
}
