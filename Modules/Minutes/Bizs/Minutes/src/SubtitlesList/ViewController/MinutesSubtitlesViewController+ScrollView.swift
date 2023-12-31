//
//  MinutesSubtitlesViewController+ScrollView.swift
//  Minutes
//
//  Created by yangyao on 2022/11/17.
//

import Foundation
import LarkUIKit

extension MinutesSubtitlesViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDragged = true
        hideMenu()

        lastOffset = scrollView.contentOffset.y
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let progress = (scrollView.bounds.height + scrollView.contentOffset.y) / scrollView.contentSize.height
        tracker.tracker(name: .detailClick, params: ["click": "subtitle_progress", "rate_of_subtitle_progress": "\(progress)", "target": "none"])

        queryVisibleCellDict()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let tableView = tableView else {
            return
        }
        var directionIsUp: Bool = false
        
        if lastOffset > scrollView.contentOffset.y {
            directionIsUp = false
        } else if lastOffset < scrollView.contentOffset.y {
            directionIsUp = true
        }
        scrollDirectionBlock?(directionIsUp)

        if let visibleIndexPath = tableView.indexPathsForVisibleRows, visibleIndexPath.count > 0 {
            if visibleIndexPath.contains(playingIndexPath) {
                let offsetY = scrollView.contentOffset.y
                if let cell = tableView.cellForRow(at: playingIndexPath) as? MinutesSubtitleCell {
                    var rect = cell.highlightedRect()
                    if rect.maxY < offsetY {
                        showUpFloat()
                    } else if rect.minY > offsetY + scrollView.frame.height {
                        showDownFloat()
                    } else {
                        hideFloat()
                    }
                }
            } else {
                let paths = visibleIndexPath.sorted { p1, p2 in
                    return p1.row < p2.row
                }
                let firstRow: Int = paths.first?.row ?? 0
                if playingIndexPath.row < firstRow {
                    showUpFloat()
                }
                let lastRow: Int = paths.last?.row ?? 0
                if playingIndexPath.row > lastRow {
                    showDownFloat()
                }
            }
        }
    }

    func hideMenu() {
        if let cur = currentLongPressTextView {
            if let cell = tableView?.cellForRow(at: subtitleIndexPath(cur.tag)) as? MinutesSubtitleCell {
                cell.hideMenu()
            }
        }
    }

    private func showUpFloat() {
        upFloatView.show(in: view, with: .up)
        downFloatView.hide()
    }

    private func showDownFloat() {
        guard self.delegate?.selectedType == .text else { return }

        if let dataProvider = self.dataProvider {
            if dataProvider.isDetailInLandscape() { return }
            let delta: CGFloat = dataProvider.isDetailInTranslationMode() || dataProvider.isDetailInSearching() ? 24 : 0

            var bottomInset: CGFloat = 0
            if dataProvider.isDetailInVideo() {
                let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
                bottomInset = bottom + 24 + delta
            } else {
                bottomInset = 24 + dataProvider.videoControlViewHeight() + delta
            }
            if isText, !Display.pad {
                bottomInset += 86
            }
            downFloatView.bottomInset = bottomInset
            if let parentView = self.parent?.parent?.view {
                downFloatView.show(in: parentView, with: .down)
            }
        }
        upFloatView.hide()
    }

    private func hideFloat() {
        upFloatView.hide()
        downFloatView.hide()
    }

    func updateDownFloat(isInTranslationMode: Bool) {
        guard downFloatView.isShowing, let dataProvider = dataProvider, !dataProvider.isDetailInLandscape() else { return }
        let delta: CGFloat = isInTranslationMode ? 24 : 0
        var bottomInset: CGFloat = 24
        if dataProvider.isDetailInVideo() {
            let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
            bottomInset = bottom + 24 + delta
        } else {
            bottomInset = 24 + dataProvider.videoControlViewHeight() + delta
        }
        if isText, !Display.pad {
            bottomInset += 86
        }
        downFloatView.snp.remakeConstraints { make in
            make.bottom.equalTo(-bottomInset)
            make.left.greaterThanOrEqualToSuperview().offset(16)
            make.right.equalTo(-16)
            make.height.equalTo(48)
        }
    }

    func showOrHideDownFloat(isCurrentSegment: Bool) {
        if downFloatView.isShowing, isCurrentSegment {
            downFloatView.isHidden = false
        }
        if downFloatView.isShowing, !isCurrentSegment {
            downFloatView.isHidden = true
        }
    }
    
    @objc func upToPlayPosition() {
        backToPlayPosition()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.upFloatView.hide()
        }
        tracker.tracker(name: .detailClick, params: ["click": "return_to_video_position", "target": "none", "location": "subtitle_above"])
    }

    @objc func downToPlayPosition() {
        backToPlayPosition()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.downFloatView.hide()
        }
        delegate?.hideHeaderBy(subtitle: self)
        tracker.tracker(name: .detailClick, params: ["click": "return_to_video_position", "target": "none", "location": "subtitle_below"])
    }

    private func backToPlayPosition() {
        guard let tableView = tableView else {
            return
        }
        var y = lastAutoScrollOffset
        if y < 0 {
            let indexPath = IndexPath(row: 0, section: 0)
            if tableView.indexPathExists(indexPath: indexPath) {
                tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        } else {
            if tableView.indexPathExists(indexPath: lastAutoScrollIndexPath) {
                tableView.scrollToRow(at: lastAutoScrollIndexPath, at: .top, animated: true)
            }
        }
        isDragged = false
    }
}

extension MinutesSubtitlesViewController: PagingViewListViewDelegate {
    public func listView() -> UIView {
        return view
    }
    
    public func listScrollView() -> UIScrollView {
        return tableView ?? UIScrollView()
    }
}

