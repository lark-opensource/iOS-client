// 
// Created by duanxiaochen.7 on 2020/3/16.
// Affiliated with DocsSDK.
// 
// Description:

import Foundation
import SKCommon
import SKFoundation
import SKBrowser
import UIKit
import SpaceInterface

extension BTController: UICollectionViewDelegateFlowLayout {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard !isTransitioningSize else { return }
        var params = viewModel.getCommonTrackParams()
        let businessParams = [
            "source": "swipe",
            "switch_type": "next_record",
            "bitable_view_type": viewModel.tableModel.viewType
        ]
        params.merge(other: businessParams)
        DocsTracker.log(enumEvent: .bitableCardSwitch, parameters: params)
        
        let stopScrolling = !scrollView.isTracking && !scrollView.isDragging && !scrollView.isDecelerating
        if stopScrolling {
            scrollViewDidEndScroll(scrollView)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isTransitioningSize &&
              (scrollView.isTracking || scrollView.isDecelerating) else { return }
        //不处理代码设置触发的滚动回调，handleUserScroll会重新计算currentRecordID记录到本地并传给前端
        //但是代码触发的回调都是滚动到currentRecord或者diff 删除和插入卡片导致的，这些操作最终都会调用滚动到currentRecord，不会影响currentRecordID
        //因此不需要再走下面handleUserScroll去重新计算currentRecordID了
        handleUserScroll(offsetX: scrollView.contentOffset.x, fetch: true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard !isTransitioningSize else { return }
        recordIsScrolling = true
        currentEditAgent?.stopEditing(immediately: true, sync: true)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !isTransitioningSize else { return }
        showBitableNotReadyToast()
        if !decelerate {
            scrollViewDidEndScroll(scrollView)
        }
    }

    func scrollViewDidEndScroll(_ scrollView: UIScrollView) {
        recordIsScrolling = false
        //若滚动过程中有update事件，需要先保留，待滚动完成后再更新卡片，避免在滚动的过程中更新卡片出现卡片跳动的问题
        if let appendingUpdateModel = appendingUpdateModel {
            self.appendingUpdateModel = nil
            didUpdateModel(model: appendingUpdateModel)
        }
        
        if !isTransitioningSize {
            handleUserScroll(offsetX: scrollView.contentOffset.x)
        }
    }
    
    func handleSwitch(pageIndex: Int, fetch: Bool) {
        guard !isTransitioningSize, let diffableDataSource = diffableDataSource else { return }
        var pageIndex = pageIndex
        let pageCount = diffableDataSource.getRecordCount()
        guard pageIndex < pageCount,
              var recordID = diffableDataSource.getRecordID(forCardIndex: pageIndex),
              var groupValue = diffableDataSource.getRecordGroupValue(forCardIndex: pageIndex)
        else {
            return
        }
        
        if let loadingRecordID = BTSpecialRecordID(rawValue: recordID) {
            guard loadingRecordID != .initLoading else {
                //初始化的loading卡片不需要走下面的通知流程
                return
            }
            
            //加载中的虚拟卡片，此时recordId需要重新计算
            if loadingRecordID == .leftLoading {
                //正在请求左边的卡片，此时currentRecord应该为当前loading卡片的下一张
                pageIndex = min(pageCount - 1, pageIndex + 1)
            } else if loadingRecordID == .rightLoading {
                //正在请求右边的卡片，此时currentRecord应该为当前loading卡片的上一张
                pageIndex = max(0, pageIndex - 1)
            }
            viewModel.updatecurrentLoadingRecordID(recordID)
            
            //重新获取currentRecordId
            guard let currentRecordID = diffableDataSource.getRecordID(forCardIndex: pageIndex),
                  let currentGroupValue = diffableDataSource.getRecordGroupValue(forCardIndex: pageIndex) else {
                return
            }
            
            recordID = currentRecordID
            groupValue = currentGroupValue
        } else {
            viewModel.updatecurrentLoadingRecordID(nil)
        }
        
        let shouldEndEdit = (pageIndex != viewModel.currentRecordIndex)
        if shouldEndEdit {
            currentEditAgent?.stopEditing(immediately: true, sync: true)
        }
        
        notifyFESwitchCard(to: recordID, newRecordGroupValue: groupValue, pageIndex: pageIndex)

        if spaceFollowAPIDelegate?.followRole != .follower {
            //follower不需要更新currentRecordID，前端发送switchCard通知follower切换卡片的时候就会更新currentRecordID
            //前端发送switchCard会调到这里，如果触发了fetchRecords，在完成回调时会滚动到currentRecord，如果此时offsetX在两张卡片中间的时候会导致pageIndex计算为上一张卡片，从而导致滚动到了错误的currentRecord
            viewModel.updateCurrentRecordIndex(pageIndex)
            viewModel.updateCurrentRecordID(recordID)
            viewModel.updateCurrentRecordGroupValue(groupValue)
        }
    }
    
    func switchCard(pageIndex: Int, fetch: Bool) {
        handleSwitch(pageIndex: pageIndex, fetch: fetch)
        if fetch {
            preloadRecords(offsetX: 0, pageIndex: pageIndex)
        }
    }

    private func handleUserScroll(offsetX: CGFloat, fetch: Bool = false) {
        var pageIndex: Int = (offsetX <= 0) ? 0 : Int(round(offsetX / pageOffset))
        handleSwitch(pageIndex: pageIndex, fetch: fetch)
        if fetch {
            preloadRecords(offsetX: offsetX, pageIndex: pageIndex)
        }
    }
    
    private func notifyFESwitchCard(to recordID: String, newRecordGroupValue: String, pageIndex: Int) {
        guard viewModel.mode == .card,
              recordID != viewModel.currentRecordID,
              recordID != lastSwitchCardAction.to,
              viewModel.currentRecordID != lastSwitchCardAction.from else {
            return
        }
        //限制回调前端次数
        lastSwitchCardAction.from = viewModel.currentRecordID
        lastSwitchCardAction.to = recordID
        delegate?.card(self,
                       didSwitchTo: recordID,
                       from: viewModel.currentRecordID,
                       newRecordGroupValue: newRecordGroupValue,
                       currentBaseID: viewModel.actionParams.data.baseId,
                       currentTableID: viewModel.actionParams.data.tableId,
                       topFieldId: getCard(at: pageIndex)?.topVisibleFieldID ?? "",
                       originBaseID: viewModel.actionParams.originBaseID,
                       originTableID: viewModel.actionParams.originTableID,
                       callback: viewModel.actionParams.callback)
    }
    
    ///预加载拉取卡片数据
    private func preloadRecords(offsetX: CGFloat, pageIndex: Int) {
        //首次打开卡片不触发预加载
        guard pageIndex != currentPageIndex,
              didAppear,
              viewModel.bitableIsReady,
              let diffableDataSource = diffableDataSource else {
            return
        }
        
        var isScrollToLeft = true
        var isScrollToRight = true
        
        if let currentPageIndex = currentPageIndex {
            //初次滑动时，滑动方向不参与左右方向的预加载的判断
            //非初次滑动，判断滑动方向，来决定是否进行某个方向的预加载
            isScrollToLeft = (pageIndex < currentPageIndex)
            isScrollToRight = (pageIndex > currentPageIndex)
        }
        
        currentPageIndex = pageIndex
        let pageCount = diffableDataSource.getRecordCount()
        
        var needFetchLeft = (pageIndex == BTViewModelConst.preloadOffset && offsetX >= 0)
        var needFetchRight = (pageIndex == pageCount - 1 - BTViewModelConst.preloadOffset)
        
        if pageCount > BTViewModelConst.preloadOffset + 1 {
            needFetchLeft = needFetchLeft && isScrollToLeft
            needFetchRight = needFetchRight && isScrollToRight
        } else {
            //当前卡片数量不足时，不使用预加载，滑动到列表边缘才触发分页请求
            needFetchLeft = pageIndex == 0
            needFetchRight = pageIndex == pageCount - 1
        }
        
        // 滑动到了第二个，拉左边数据
        if needFetchLeft {
            viewModel.constructCardRequest(.left)
        }
        // 滑动到了倒数第二个，拉右边数据
        if needFetchRight {
            viewModel.constructCardRequest(.right)
        }
    }
}
