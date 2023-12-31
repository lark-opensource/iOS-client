//
//  SheetFilterFacadeViewController.swift
//  SpaceKit
//
//  Created by Webster on 2019/9/25.
//  筛选二级页面，可以点击具体类型进入三级页面

import Foundation
import SKCommon
import SKBrowser
import SKUIKit

protocol SheetFilterFacadeViewControllerDelegate: AnyObject {
    func filterDidRequstUpdate(identifier: String, value: String?, controller: SheetFilterFacadeViewController)
}

class SheetFilterFacadeViewController: SheetScrollableToolkitViewController {
    weak var delegate: SheetFilterFacadeViewControllerDelegate?
    private var lastFilterTypes: [[ToolBarItemInfo]] = []
    private var filterTypesHeight: CGFloat {
        return SKOperationView.estimateContentHeight(infos: lastFilterTypes)
    }
    private var preferWidth: CGFloat
    override var resourceIdentifier: String {
        return BadgedItemIdentifier.filter.rawValue
    }
    private lazy var cancelButton: SheetTouchFeedbackTextButton = {
        let button = SheetTouchFeedbackTextButton { [weak self] in
            self?.didClickCancelButton()
        }
        return button
    }()

    private lazy var filterItemView: SKOperationView = {
        let view = SKOperationView(frame: .zero, displayIcon: false)
        view.delegate = self
        return view
    }()

    init(info: ToolBarItemInfo, preferWidth: CGFloat) {
        self.preferWidth = preferWidth
        super.init()
        itemInfo = info
        
        scrollView.addSubview(filterItemView)
        filterItemView.snp.makeConstraints { (make) in
            make.left.top.right.equalTo(scrollView.contentLayoutGuide)
            make.height.equalTo(200)
        }
        
        scrollView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { (make) in
            make.left.right.equalTo(scrollView.contentLayoutGuide).inset(itemSpacing)
            make.top.equalTo(filterItemView.snp.bottom)
            make.height.equalTo(itemHeight)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(itemSpacing)
        }

        update(info)
    }

    func update(_ info: ToolBarItemInfo) {
        itemInfo = info
        navigationBar.setTitleText(itemInfo.title)
        if let filterTypeInfos = itemInfo.children {
            var processedFilterTypeInfos: [[ToolBarItemInfo]] = []
            let filterByCellInfo = filterTypeInfos.filter {
                $0.identifier == BarButtonIdentifier.filterByCell.rawValue || $0.identifier == BarButtonIdentifier.cancelFilterByCell.rawValue
            }
            if !filterByCellInfo.isEmpty {
                processedFilterTypeInfos.append(filterByCellInfo)
            }
            let otherFilterTypes = filterTypeInfos.filter {
                $0.identifier != BarButtonIdentifier.cellFilterClear.rawValue &&
                    $0.identifier != BarButtonIdentifier.filterByCell.rawValue &&
                    $0.identifier != BarButtonIdentifier.cancelFilterByCell.rawValue
            }
            let expandableFilterType: Set<String> = [BarButtonIdentifier.cellFilterByValue.rawValue,
                                                     BarButtonIdentifier.cellFilterByColor.rawValue,
                                                     BarButtonIdentifier.cellFilterByCondition.rawValue]
            otherFilterTypes.forEach {
                if expandableFilterType.contains($0.identifier) {
                    $0.children = [ToolBarItemInfo(identifier: "default")]
                }
            }
            processedFilterTypeInfos.append(otherFilterTypes)
            lastFilterTypes = processedFilterTypeInfos
            filterItemView.snp.updateConstraints { (make) in
                make.height.equalTo(filterTypesHeight)
            }
            filterItemView.refresh(infos: processedFilterTypeInfos)
        }

        if let cancelInfos = itemInfo.children?.filter({ $0.identifier == BarButtonIdentifier.cellFilterClear.rawValue }),
            cancelInfos.count > 0 {
            cancelButton.setTitle(cancelInfos[0].title, for: .normal)
            cancelButton.isHidden = false
        } else {
            cancelButton.isHidden = true
        }
    }

    func didClickCancelButton() {
        navigationController?.popViewController(animated: true)
        delegate?.filterDidRequstUpdate(identifier: BarButtonIdentifier.cellFilterClear.rawValue, value: nil, controller: self)
    }

    override func willExistControllerByUser() {
        super.willExistControllerByUser()
        delegate?.filterDidRequstUpdate(identifier: SheetToolkitNavigationController.backIdentifier, value: nil, controller: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension SheetFilterFacadeViewController: SKOperationViewDelegate {
    var isInPopover: Bool { false }

    func shouldDisplayBadge(identifier: String, at view: SKOperationView) -> Bool {
        return false
    }
    
    func didClickItem(identifier: String, finishGuide: Bool, itemIsEnable: Bool, disableReason: OperationItemDisableReason, at view: SKOperationView) {
        delegate?.filterDidRequstUpdate(identifier: identifier, value: nil, controller: self)
    }
}
