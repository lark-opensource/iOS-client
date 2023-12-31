//
//  SKPDFPreviewController+Grid.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/1/9.
//  

import UIKit
import SnapKit
import SKFoundation

extension SKPDFPreviewController {

    private var thumbnailCellIdentifier: String {
        return "spacekit.pdfkit.thumbnail.collection.cell"
    }

    func createThumbnailGridView() -> UICollectionView {
        let layout = SKPDFGridLayout()
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = UIColor.ud.bgBase
        view.register(SKPDFThumbnailCell.self, forCellWithReuseIdentifier: thumbnailCellIdentifier)
        view.dataSource = self
        view.delegate = self
        return view
    }

    func setupGridModeView() {
        view.addSubview(gridModeView)
        gridModeView.snp.makeConstraints { (make) in
            make.height.width.equalTo(32)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-20)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-18)
            make.bottom.lessThanOrEqualTo(view.snp.bottom).offset(-16)
        }
    }

    func setupThumbnailGridView() {
        let thumbnailGridView = createThumbnailGridView()
        view.addSubview(thumbnailGridView)
        thumbnailGridView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            make.bottom.equalToSuperview()
        }
        self.thumbnailGridView = thumbnailGridView
    }

    /// 翻页时通知网格式图
    /// - Parameter newPageNumber: 从1开始的页码
    func notifyThumbnailGridViewForPageChanged(from: Int?, to: Int) {
        if let fromPageNumber = from, fromPageNumber > 0 {
            let fromIndexItem = Int(fromPageNumber) - 1
            let fromIndexPath = IndexPath(item: fromIndexItem, section: 0)
            guard let cell = thumbnailGridView?.cellForItem(at: fromIndexPath) as? SKPDFThumbnailCell else {
                return
            }
            cell.resetHighlightLabel()
        }
        guard to > 0 else {
            DocsLogger.error("drive.pdfkit.grid --- invalid new page number", extraInfo: ["pageNumber": to])
            return
        }
        let toIndexItem = Int(to) - 1
        let toIndexPath = IndexPath(item: toIndexItem, section: 0)
        guard let cell = thumbnailGridView?.cellForItem(at: toIndexPath) as? SKPDFThumbnailCell else {
            return
        }
        cell.highlightLabel()
    }
}

// MARK: - SKPDFModeDelegate
extension SKPDFPreviewController: SKPDFModeDelegate {
    public func previewModeChanged(currentMode: SKPDFModeView.PreviewMode) {
        switch currentMode {
        case .grid:
            showThumbnailGrid()
        case .preview:
            hideThumbnailGrid()
        }
    }

    @objc
    open func showThumbnailGrid() {
        if thumbnailGridView == nil {
            setupThumbnailGridView()
        }
        thumbnailGridView?.reloadData()
        thumbnailGridView?.layoutIfNeeded()
        view.bringSubviewToFront(gridModeView)
        thumbnailGridView?.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
            self.scrollThumbnailGridToCurrentItem()
        }
    }

    @objc
    open func hideThumbnailGrid() {
        thumbnailGridView?.isHidden = true
    }
}

// MARK: - UICollectionViewDelegate
extension SKPDFPreviewController: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        gridModeView.reset()
        guard go(to: indexPath.item) else {
            DocsLogger.error("drive.pdfkit.grid --- failed to change page when select thumbnail cell", extraInfo: ["indexPath": indexPath])
            return
        }
    }
}

// MARK: - UICollectionViewDataSource
extension SKPDFPreviewController: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(viewModel.pageCount)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: thumbnailCellIdentifier, for: indexPath)
        guard let newCell = cell as? SKPDFThumbnailCell else {
            DocsLogger.warning("drive.pdfkit.thumbnail.cell --- get unexcepted reuseable cell type")
            return cell
        }
        let pageForCell = indexPath.item + 1
        newCell.update(page: pageForCell)
        if let currentPage = currentPageNumber,
            currentPage == pageForCell {
            newCell.highlightLabel()
        }
        DocsLogger.debug("drive.pdfkit.thumbnail.cell --- begin for indexPath: \(indexPath.item)")
        let thumbnailSize = CGSize(width: 160 * SKDisplay.scale, height: 160 * SKDisplay.scale)
        viewModel.getThumbnail(pageNumber: indexPath.item, size: thumbnailSize) { (result: Result<(Int, UIImage), SKPDFViewModel.ThumbnailError>) in
            switch result {
            case let .success((_, thumbnailImage)):
                newCell.update(image: thumbnailImage, page: pageForCell)
            case let .failure(error):
                DocsLogger.error("drive.pdfkit.thumbnail.cell --- failed to get thumbnail for cell", extraInfo: ["pageNumber": pageForCell], error: error)
            }
        }
        return newCell
    }
}
