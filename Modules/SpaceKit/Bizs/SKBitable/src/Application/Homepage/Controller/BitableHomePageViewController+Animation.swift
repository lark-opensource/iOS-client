//
//  BitableHomePageViewController+Animation.swift
//  SKBitable
//
//  Created by qiyongka on 2023/11/6.
//

import SKFoundation
import SpaceInterface
import SKUIKit
import SnapKit
import UniverseDesignIcon

extension BitableHomePageViewController: BitableHomePageMultiListContainerCellDelegate {
    //MARK: 全屏动画
    func showMultiListViewInFullScreenStyle() {
        guard isInAnimation == false else {
            return
        }
        guard let controller = multiListController else {
            return
        }
        guard let cell = multiListContainerCell else {
            return
        }
        isFileListEmbeded = false
        isInAnimation = true
        collectionView.isScrollEnabled = false
        forbiddenRightSlidingForBack()
        controller.collectionViewWillShowInfullScreen()
        showfullScreenAnimationStageOne(controller: controller, cell: cell)
        BTOpenHomeReportMonitor.reportCancel(context: context, type: .file_list_full_screen)
    }
        
    private func showfullScreenAnimationStageOne(controller: BitableMultiListControllerProtocol, cell: BitableHomePageMultiListContainerCell) {
        //整体框架
        view.addSubview(animationContainerView)
        animationContainerView.frame = view.bounds
        let frame = view.convert(cell.frame, from: cell.superview)
        let bgView = animationBgView
        bgView.backgroundColor = cell.contentView.backgroundColor
        bgView.layer.cornerRadius = cell.contentView.layer.cornerRadius
        bgView.layer.masksToBounds = true
        bgView.frame = frame
        animationContainerView.addSubview(bgView)
        
        //模拟containerCell
        controller.view.removeFromSuperview()
        bgView.addSubview(controller.view)
        controller.view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        cell.isHidden = true
        
        //头部标题区域
        animationContainerView.addSubview(headerBgView)
        animationContainerView.addSubview(self.header)
        headerBgView.snp.remakeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalTo(header.snp.bottom)
        }
        header.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(56)
        }
        
        //transform-Cell缩小
        UIView.animate(withDuration: 0.2,  delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0.0, options: .curveLinear) {
            bgView.transform =  CGAffineTransformMakeScale(0.95, 0.95)
        }completion: { _ in
            self.showfullScreenAnimationStageTwo(controller: controller, cell: cell, bgView: bgView)
        }
    }
    
    private func showfullScreenAnimationStageTwo(controller: BitableMultiListControllerProtocol, cell: BitableHomePageMultiListContainerCell, bgView: UIView) {
        // 导航栏和底部的工具栏移除动画
        tabBarDelegate?.hideBottomTabBar(animated: true)
        UIView.animate(withDuration: 0.75,  delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: .curveLinear) {
            bgView.transform =  CGAffineTransformMakeScale(1.0, 1.0)
            bgView.frame = self.view.bounds
            bgView.layer.cornerRadius = 0
            self.header.updateStyleForExpand()
            self.showHeaderInFullScreenStyleAnimation()
            controller.showfullScreenAnimation()
            controller.view.snp.remakeConstraints { make in
                make.top.equalTo(self.header.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
            self.animationContainerView.setNeedsLayout()
            self.animationContainerView.layoutIfNeeded()
            controller.collectionViewShouldReloadCellsForAnimation()
          } completion: { _ in
              self.isInAnimation = false
              self.collectionView.isScrollEnabled = true
              controller.collectionViewDidShowInfullScreen()
          }
      }
    
    //MARK: 内嵌动画
    func showMultiListViewInEmbededStyle() {
        guard let controller = multiListController else {
            return
        }
        guard let cell = multiListContainerCell else {
            return
        }
        isFileListEmbeded = true
        isInAnimation = true
        allowRightSlidingForBack()
        controller.collectionViewWillShowInEmbed()
        showEmbededAnimation(controller: controller, cell: cell)
    }
    
    private func showEmbededAnimation(controller: BitableMultiListControllerProtocol, cell: BitableHomePageMultiListContainerCell) {
        let frame = self.view.convert(cell.frame, from: cell.superview)
        // 导航栏和底部的工具栏恢复动画
        tabBarDelegate?.showBottomTabBar(animated: true)
        UIView.animate(withDuration: 0.85,  delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.0, options: .curveLinear) {
            controller.multiListCollectionView.setContentOffset(.zero, animated: false)
            self.animationBgView.frame = frame
            self.animationBgView.layer.cornerRadius = 20
            self.header.updateStyleForNormal()
            self.showHeaderInEmbededStyleAnimation()
            controller.view.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            controller.showEmbededAnimation()
            self.animationContainerView.setNeedsLayout()
            self.animationContainerView.layoutIfNeeded()
            controller.collectionViewShouldReloadCellsForAnimation()
        } completion: { _ in
            //恢复头部标题区域
            self.view.addSubview(self.headerBgView)
            self.view.addSubview(self.header)
            self.header.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.height.equalTo(56)
            }
            self.headerBgView.snp.remakeConstraints { make in
                make.leading.trailing.top.equalToSuperview()
                make.bottom.equalTo(self.header.snp.bottom)
            }
            //恢复containerCell区域
            cell.isHidden = false
            cell.contentView.addSubview(controller.view)
            controller.view.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
            self.animationContainerView.removeFromSuperview()
            self.isInAnimation = false
            controller.collectionViewDidShowInEmbed()
        }
    }
    
    //MARK: header更新动画
    private func showHeaderInFullScreenStyleAnimation() {
        if headerBgView.alpha != 0 {
            headerBgViewAlphaBeforeAnimation = headerBgView.alpha
            headerBgView.alpha = 1.0
            headerBgView.backgroundColor = BitableHomeLayoutConfig.multiListContainerBgColor()
        } else {
            var number = 200
            number += 100
        }
    }
    
    private func showHeaderInEmbededStyleAnimation() {
        if let alpha = headerBgViewAlphaBeforeAnimation {
            headerBgView.alpha = alpha
            headerBgView.backgroundColor = BitableHomeLayoutConfig.headerBgColor()
            headerBgViewAlphaBeforeAnimation = nil
        }
    }
    
    //MARK: others
    func allowRightSlidingForBack(){
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        delegate?.allowRightSlidingForBack()
    }
    
    func forbiddenRightSlidingForBack(){
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        delegate?.forbiddenRightSlidingForBack()
    }
    
    func multiListContainerCellDidSwipedUp () {
        showMultiListViewInFullScreenStyle()
    }
}
