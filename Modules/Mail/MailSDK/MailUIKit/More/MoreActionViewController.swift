//
//  MoreActionViewController.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2020/8/4.
//

import Foundation
import LarkUIKit

enum LayoutType {
    case vertical
}

struct MoreActionSection {
    let layout: LayoutType
    var items: [MailActionItemProtocol]
}

final class MoreActionViewController: WidgetViewController {
    private let headerConfig: MoreActionHeaderConfig?
    private let sectionData: [MoreActionSection]

    private static let popoverBottomOffset: CGFloat = 8
    var arrowUp: Bool = true

    // MARK: - Views
    private var moreActionView: MoreActionView?

    init(headerConfig: MoreActionHeaderConfig?, sectionData: [MoreActionSection]) {
        self.sectionData = sectionData
        self.headerConfig = headerConfig
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
            if self.arrowUp {
                resetHeight(view.frame.height - MoreActionViewController.popoverBottomOffset)
            } else {
                resetHeight(view.frame.height)
            }

        } else {
            resetHeight(view.frame.height - Display.realTopBarHeight())
        }
    }

    private func setupView() {
        view.backgroundColor = .clear
        contentView.backgroundColor = .clear

        if moreActionView == nil {
            let tempMoreActionView = MoreActionView(frame: .zero, draggable: !isPopover,
                                                    headerConfig: headerConfig, sectionData: sectionData)
            tempMoreActionView.delegate = self
            contentView.addSubview(tempMoreActionView)
            tempMoreActionView.snp.makeConstraints { (make) in
                make.left.right.equalTo(contentView.safeAreaLayoutGuide)
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            if modalPresentationStyle == .popover {
                view.backgroundColor = UIColor.ud.bgBase
                contentView.backgroundColor = UIColor.ud.bgBase
                preferredContentSize = CGSize(width: 0, height: tempMoreActionView.calculateHeightForPopover(hasHeader: headerConfig != nil))
            }
            moreActionView = tempMoreActionView
        }
    }
}

extension MoreActionViewController: MoreActionViewDelegate {
    func didClick(item: MailActionItemProtocol) {
        if let item = item as? MailActionItem {
            animatedView(isShow: false) {
                item.actionCallBack(nil)
            }
        } else if let item = item as? MailActionStatusItem {
            animatedView(isShow: false) {
                item.actionCallBack(nil)
            }
        } else if item is MailActionSwitchItem {
            // switch cell 不响应整个 cell 的点击
        }
    }

    func didClickMask() {
        animatedView(isShow: false)
    }
}

extension MoreActionViewController {
    static func makeMoreActionVC(headerConfig: MoreActionHeaderConfig?, sectionData: [MoreActionSection], popoverSourceView: UIView?, arrowUp: Bool?) -> UIViewController {
        let moreVC = MoreActionViewController(headerConfig: headerConfig, sectionData: sectionData)
        if let popoverSourceView = popoverSourceView {
            moreVC.needAnimated = false
            moreVC.modalPresentationStyle = .popover
            moreVC.popoverPresentationController?.sourceView = popoverSourceView
            moreVC.popoverPresentationController?.sourceRect = popoverSourceView.bounds
            if let flag = arrowUp {
                moreVC.arrowUp = flag
            }
        }
        return moreVC
    }
}
