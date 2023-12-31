//
//  FeedMainViewController+BindFilterTab.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/9.
//

import Foundation
import UniverseDesignTabs
import RustPB
import RxSwift
import RxCocoa

extension FeedMainViewController {
    func bindFilter() {
        filterTabViewModel.displayDriver.drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.layoutFilterTabsView()
        }).disposed(by: disposeBag)

        self.filterTabViewModel.isSupportCeilingDriver.drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.layoutFilterTabsView()
        }).disposed(by: disposeBag)

        self.mainViewModel.backFirstListCallBack = { [weak self] _ in
            guard let self = self else { return }
            self.backFirstList()
        }

        self.mainViewModel.deleteListCallBack = { [weak self] tabs in
            guard let self = self else { return }
            tabs.forEach { tab in
                self.remove(tab)
            }
        }

        self.mainViewModel.updatePosisionCallBack = { [weak self] type in
            guard let self = self else { return }
            let newfilterTypes = self.filterTabViewModel.filterFixedViewModel.fixedDataSource.map({ $0.type })
            let currentType = self.mainViewModel.currentFilterType
            if let tempFilterTypes = self.mainViewModel.tempFixedFilterTypes,
               tempFilterTypes.contains(currentType), !newfilterTypes.contains(currentType) {
                // 固定分组栏数据更新后，当前分组由固定栏tab变更为非固定栏tab时，需要back回首个分组
                self.backFirstList()
            } else {
                self.filterTabView.filterFixedView?.changeViewTab(type)
            }
            self.mainViewModel.tempFixedFilterTypes = newfilterTypes
        }

        self.filterTabView.menuClickHandler = { [weak self] sendar in
            guard let self = self else { return }
            if self.styleService.currentStyle == .padRegular {
                if Feed.Feature(userResolver).groupPopOverForPad {
                    self.popover(sendar: sendar)
                } else {
                    guard let splitVC = self.larkSplitViewController else { return }
                    switch splitVC.splitMode {
                    case .oneBesideSecondary, .oneOverSecondary:
                        splitVC.updateSplitMode(.twoBesideSecondary, animated: true)
                    case .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary:
                        splitVC.updateSplitMode(.oneBesideSecondary, animated: true)
                    default:
                        break
                    }
                }
            } else {
                self.showDrawer()
            }
        }
    }

    private func layoutFilterTabsView() {
        filterTabView.snp.updateConstraints { make in
            make.height.equalTo(self.filterTabViewModel.viewHeight)
        }
        let isSupportCeiling = filterTabViewModel.isSupportCeiling
        let filterViewHeight = filterTabViewModel.viewHeight
        let diff = isSupportCeiling ? filterViewHeight : 0
        moduleVCContainerView.snp.updateConstraints { (make) in
            make.height.equalToSuperview().offset(-diff)
        }
    }
}
