//
//  SKPDFPreviewController+ScrollBar.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/1/6.
//  

import UIKit
import SnapKit
import SKFoundation

extension SKPDFPreviewController {

    func setupScrollBarView() {
        view.addSubview(scrollBarView)
        scrollBarView.snp.makeConstraints { (make) in
            make.width.equalTo(43)
            make.right.equalToSuperview()
            // 22: 滚动球高度的一半，保证滚动球到达顶端时上半部分不会被挡住，底部同理
            // 8: 设计稿要求距离顶部和底部保留8pt的间距
            let ballHalfHeight = 30 // = 22 + 8
            make.top.equalTo(self.view.safeAreaInsets.top).offset(ballHalfHeight).priority(.high)
            make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.top).offset(ballHalfHeight)
            // 50: gridmode切换按钮顶部位置
            // 22: 滚动球高度的一半，保证滚动球到达顶端时上半部分不会被挡住，底部同理
            let bottomOffset = 50 + 22
            make.bottom.equalTo(self.pdfView.snp.bottom).offset(-bottomOffset).priority(.high)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-bottomOffset)
        }

        scrollBarView.delegate = self

        if #available(iOS 13, *), viewModel.pageCount > 1 {
            scrollBarView.fadeIn()
        } else {
            // 1. iOS 13 以下，避免闪动，需要隐藏
            // 2. pdf 只有一页也需要隐藏
            scrollBarView.fadeOut()
        }

        viewModel.thumbnailUpdated
            .drive(onNext: { [weak self] (page, thumbnail) in
                guard let self = self else { return }
                guard page > 0 else {
                    DocsLogger.info("drive.pdfkit.thumbnail --- page is 0 when updating thumbnail!")
                    return
                }
                DocsLogger.info("drive.pdfkit.thumbnail --- updating thumbnail", extraInfo: ["page": page, "size": thumbnail.size])
                self.thumbnailView.update(thumbnailImage: thumbnail)
                let width = thumbnail.size.width
                let height = thumbnail.size.height
                let ratio = width / height
                let thumbnailWidth: CGFloat
                let thumbnailHeight: CGFloat
                if ratio > 1 {
                    thumbnailWidth = 160
                    thumbnailHeight = 160 / ratio
                } else {
                    thumbnailWidth = 160 * ratio
                    thumbnailHeight = 160
                }
                self.thumbnailView.snp.updateConstraints { make in
                    make.width.equalTo(thumbnailWidth)
                    make.height.equalTo(thumbnailHeight)
                }
            })
            .disposed(by: disposeBag)
    }

    func setupThumbnailView() {
        view.addSubview(thumbnailView)
        thumbnailView.isHidden = true
        thumbnailView.snp.makeConstraints { make in
            make.width.equalTo(160)
            make.height.equalTo(160)
            make.right.equalTo(self.scrollBarView.snp.left).offset(-12)
            make.centerY.equalTo(self.scrollBarView.snp.top).priority(.low)
            make.top.greaterThanOrEqualTo(self.pdfView.snp.top).offset(8)
            make.bottom.lessThanOrEqualTo(self.pdfView.snp.bottom).offset(-8)
            make.top.greaterThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.top).offset(8)
            make.bottom.lessThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-8)
        }
    }

    func setupScrollingMaskView() {
        view.addSubview(scrollingMaskView)
        scrollingMaskView.isHidden = true
        scrollingMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func notifyScrollBarViewForPageChanged(from: Int?, to: Int) {
        scrollBarView.updateScrollBar(page: UInt(to))
    }
}

extension SKPDFPreviewController: SKPDFScrollBarViewDelegate {

    public func scrollBarDidBeginScroll(_ scrollBar: SKPDFScrollBarView) {
        thumbnailView.isHidden = false
        scrollingMaskView.isHidden = false
    }

    public func scrollBarDidScroll(_ scrollBar: SKPDFScrollBarView, page: UInt, ratio: CGFloat) {
        if viewModel.originConfig.enableThumbnail {
            thumbnailThrottleUpdatedSubject.onNext(Int(page) - 1)
            thumbnailView.snp.updateConstraints { (make) in
                make.centerY.equalTo(self.scrollBarView.snp.top)
                    .offset(ratio * self.scrollBarView.frame.height).priority(.low)
            }
            thumbnailView.update(hintContent: "\(page)/\(viewModel.pageCount)")
        }
    }

    public func scrollBarDidEndScroll(_ scrollBar: SKPDFScrollBarView) {
        thumbnailView.isHidden = true
        scrollingMaskView.isHidden = true
        // 将页码从 0-index 转换为 1-index
        let pageIndex = max(Int(scrollBar.currentPage) - 1, 0)
        guard go(to: pageIndex) else {
            DocsLogger.error("drive.pdfkit.scrollbar --- failed to get page when stop scrolling", extraInfo: ["pageIndex": pageIndex])
            return
        }
    }
}
