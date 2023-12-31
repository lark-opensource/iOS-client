//
//  WhiteboardViewController+IPad.swift
//  Whiteboard
//
//  Created by helijian on 2023/1/16.
//

import Foundation
import LarkAlertController
import ByteViewNetwork
import UniverseDesignIcon
import UniverseDesignToast

// MARK: ipad上snapshot cell样式，和iphone上元素相同，布局略有差异
class WhiteboardIPadSnapshotCell: SnapshotBaseCell {

    fileprivate enum Layout {
        static let imageSize: CGSize = CGSize(width: 172, height: 97)
        static let deleteButtonSize: CGSize = CGSize(width: 16, height: 16)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.layer.cornerRadius = 6
        self.layer.masksToBounds = true
        self.contentView.addSubview(snapshotImageView)
        snapshotImageView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(Layout.imageSize)
        }
        self.contentView.addSubview(selectedView)
        selectedView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        self.contentView.addSubview(deleteButton)
        let image = UDIcon.getIconByKey(.closeFilled, iconColor: UIColor.ud.iconN1, size: CGSize(width: 16, height: 16))

        deleteButton.setImage(image, for: .normal)
        deleteButton.snp.makeConstraints { maker in
            maker.size.equalTo(Layout.deleteButtonSize)
            maker.top.right.equalToSuperview().inset(4)
        }
        indexLabel.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(indexLabel)
        indexLabel.snp.makeConstraints { maker in
            maker.left.top.equalToSuperview().inset(8)
        }
        self.contentView.addSubview(loadingView)
        loadingView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(CGSize(width: 28, height: 28))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configCell(with item: WhiteboardSnapshotItem) {
        super.configCell(with: item)
        indexLabel.text = "\(item.index)/\(item.totalCount)"
        if let image = item.image {
            snapshotImageView.image = image
        } else {
            snapshotImageView.backgroundColor = WhiteboardViewModel.currentTheme.color
        }
    }
}

// MARK: 白板view事件，用于设置undo redo snapshot等
extension WhiteboardViewController {
    func changeIpadDrawingState(isDrawing: Bool) {
        if isDrawing {
            self.iPadBrushAndColorView.isHidden = true
            self.iPadEraserView.isHidden = true
            self.iPadShapeTool.isHidden = true
            self.containView.isHidden = true
            self.multiPageButton.setImage(self.foldImage, for: .normal)
            self.multiPageButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        }
    }

    func changeIpadRedoState(canRedo: Bool) {
        iPadToolBar.setRedoButtonState(canRedo: canRedo)
    }

    func changeIPadUndoState(canUndo: Bool) {
        iPadToolBar.setUndoButtonState(canUndo: canUndo)
    }

    func shouldReloadIpadSnapshot(item: WhiteboardSnapshotItem) {
        if let index = ipadItems.firstIndex(where: { $0 == item }) {
            DispatchQueue.main.async {
                self.ipadItems[index] = item
                let indexPath = IndexPath(row: index, section: 0)
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
    }

    func changeIpadMultiPageInfo(currentPageNum: Int32, totalPages: Int) {
        DispatchQueue.main.async {
            // 更新多白板页码
            self.multiPageButton.setTitle("\(currentPageNum)/\(totalPages)", for: .normal)
        }
    }

    func shouldReloadIpadTotalSnapshot() {
        DispatchQueue.main.async {
            self.ipadItems = self.whiteboardView.getSnapshotItems().sorted(by: { $0.index < $1.index })
            let newPagesLayoutStype = self.calculateHeight()
            var needScroll: Bool = false
            if case .maxHeight = newPagesLayoutStype, case .maxHeight = self.pagesLayoutStyle {
                needScroll = true
            }
            self.pagesLayoutStyle = newPagesLayoutStype
            self.containView.snp.remakeConstraints { maker in
                maker.right.equalToSuperview().inset(16)
                maker.bottom.equalTo(self.multiPageButton.snp.top).offset(-8)
                maker.width.equalTo(Layout.containViewWidth)
                if case .adaption(let height) = self.pagesLayoutStyle {
                    maker.height.equalTo(height)
                } else {
                    maker.top.equalToSuperview().inset(12)
                }
            }
            self.collectionView.reloadData()
            if needScroll, let index = self.getSelectedIndex() {
                let lastItemIndex = IndexPath(item: index, section: 0)
                self.collectionView.scrollToItem(at: lastItemIndex, at: .bottom, animated: true)
            }
        }
    }

    private func getSelectedIndex() -> Int? {
        for (index, item) in self.ipadItems.enumerated() {
            if item.state == .selected {
                return index
            }
        }
        return nil
    }

    func calculateHeight() -> PagesLayoutStyle {
        let totalHeight: CGFloat = self.view.frame.height
        let contentHeight: CGFloat = CGFloat(ipadItems.count) * Layout.itemSize.height + CGFloat(ipadItems.count - 1) * Layout.itemMinimumLineSpacing
        let otherHeight: CGFloat = 80 + 76 + 12 + 3 + 16 + 16
        let remainHeight: CGFloat = totalHeight - otherHeight
        if contentHeight < remainHeight {
            // nolint-next-line: magic number
            let resultHeight = contentHeight + 16 + 16 + 76 + 3
            return .adaption(resultHeight)
        } else {
            return .maxHeight
        }
    }

    func adaptMeetingLayoutChange() {
        DispatchQueue.main.async {
            self.containView.isHidden = true
            self.multiPageButton.setImage(self.foldImage, for: .normal)
            self.multiPageButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                guard let self = self else { return }
                switch self.currentMeetingLayoutStyle {
                case .fullscreen:
                    self.multiPageButton.snp.remakeConstraints { maker in
                        maker.right.equalToSuperview().inset(16)
                        maker.bottom.equalTo(self.whiteboardView.snp.bottom).offset(-16)
                        maker.size.equalTo(Layout.multiButtonSize)
                    }
                    self.iPadToolBar.snp.remakeConstraints { maker in
                        maker.left.equalToSuperview().inset(12)
                        maker.top.equalToSuperview().inset(49)
                    }
                case .tiled:
                    self.multiPageButton.snp.remakeConstraints { maker in
                        maker.right.equalToSuperview().inset(16)
                        maker.bottom.equalTo(self.whiteboardView.snp.bottom).offset(-16)
                        maker.size.equalTo(Layout.multiButtonSize)
                    }
                    self.iPadToolBar.snp.remakeConstraints { maker in
                        maker.left.equalToSuperview().inset(12)
                        maker.top.equalToSuperview().inset(12)
                    }
                case .overlay:
                    self.multiPageButton.snp.remakeConstraints { maker in
                        maker.right.equalToSuperview().inset(16)
                        maker.bottom.equalTo(self.bottomBarGuide.snp.top).offset(-16)
                        maker.size.equalTo(Layout.multiButtonSize)
                    }
                    self.iPadToolBar.snp.remakeConstraints { maker in
                        maker.left.equalToSuperview().inset(12)
                        maker.top.equalToSuperview().inset(12)
                    }
                }
            })
        }
    }
}

// MARK: 工具栏点击切换事件
extension WhiteboardViewController {
    func didTapIPadMove() {
        self.iPadBrushAndColorView.isHidden = true
        self.iPadShapeTool.isHidden = true
        self.iPadEraserView.isHidden = true
        self.iPadSaveView.isHidden = true
        self.setFailofGestRecognizer(shouldReceive: false)
        whiteboardView.setTool(tool: .Move)
    }

    func didTapIPadEraser() {
        // 默认为擦除，其他三个擦除为点击事件，而不是常态事件
        iPadEraserView.setSelectState(.clear)
        whiteboardView.setTool(tool: .Eraser)
        self.setFailofGestRecognizer(shouldReceive: true)
        self.iPadBrushAndColorView.isHidden = true
        self.iPadShapeTool.isHidden = true
        self.iPadSaveView.isHidden = true
        self.iPadEraserView.isHidden = false
    }

    func didChangeIPadToolType(toolType: ActionToolType) {
        if toolType != .move {
            self.setFailofGestRecognizer(shouldReceive: true)
        }
        switch toolType {
        case .pen:
            self.iPadBrushAndColorView.isHidden = true
            self.iPadShapeTool.isHidden = true
            self.iPadEraserView.isHidden = true
            self.iPadSaveView.isHidden = true
            iPadBrushAndColorView.configSelection(selection: currentPenToolConfig, shouldReload: true)
            iPadBrushAndColorView.snp.remakeConstraints { maker in
                maker.left.equalTo(iPadToolBar.snp.right).offset(4)
                maker.top.equalTo(iPadToolBar.snp.top).offset(50)
                maker.size.equalTo(CGSize(width: 182, height: 227))
            }
            setToolConfig(tool: .pen)
            self.iPadBrushAndColorView.isHidden = false
        case .highlighter:
            self.iPadBrushAndColorView.isHidden = true
            self.iPadShapeTool.isHidden = true
            self.iPadEraserView.isHidden = true
            self.iPadSaveView.isHidden = true
            iPadBrushAndColorView.configSelection(selection: currentHighlighterToolConfig, shouldReload: true)
            iPadBrushAndColorView.snp.remakeConstraints { maker in
                maker.left.equalTo(iPadToolBar.snp.right).offset(4)
                maker.top.equalTo(iPadToolBar.snp.top).offset(94)
                maker.size.equalTo(CGSize(width: 182, height: 227))
            }
            setToolConfig(tool: .highlighter)
            self.iPadBrushAndColorView.isHidden = false
        case .shape:
            self.iPadBrushAndColorView.isHidden = true
            self.iPadShapeTool.isHidden = true
            self.iPadEraserView.isHidden = true
            self.iPadSaveView.isHidden = true
            iPadShapeTool.configShapeTool(shapeToolConfig: currentShapeToolConfig)
            setToolConfig(tool: .shape)
            self.iPadShapeTool.isHidden = false
        case .save:
            self.iPadBrushAndColorView.isHidden = true
            self.iPadShapeTool.isHidden = true
            self.iPadEraserView.isHidden = true
            self.iPadSaveView.isHidden = true
            iPadShapeTool.configShapeTool(shapeToolConfig: currentShapeToolConfig)
            setToolConfig(tool: .move)
            if whiteboardView.hasMultiBoards {
                self.iPadSaveView.isHidden = false
            } else {
                self.didTapSaveCurrent()
            }
        default:
            break
        }
    }

    func didTapIPadActionWithSelectedState(action: ActionToolType) {
        switch action {
        case .pen, .highlighter:
            iPadBrushAndColorView.isHidden = !iPadBrushAndColorView.isHidden
        case .shape:
            iPadShapeTool.isHidden = !iPadShapeTool.isHidden
        case .eraser:
            if iPadEraserView.isHidden {
                iPadEraserView.setSelectState(.clear)
            }
            iPadEraserView.isHidden = !iPadEraserView.isHidden
        case .save:
            if whiteboardView.hasMultiBoards {
                iPadSaveView.isHidden = !iPadSaveView.isHidden
            } else {
                self.didTapSaveCurrent()
            }
        default:
            return
        }
    }

    private func setToolConfig(tool: ActionToolType) {
        switch tool {
        case .pen:
            whiteboardView.setTool(tool: tool.wbTool)
            whiteboardView.setStrokeWidth(currentPenToolConfig.brushType.brushValue)
            whiteboardView.setColor(currentPenToolConfig.color)
        case .highlighter:
            whiteboardView.setTool(tool: tool.wbTool)
            whiteboardView.setStrokeWidth(currentHighlighterToolConfig.brushType.brushValue)
            whiteboardView.setColor(currentHighlighterToolConfig.color)
        case .shape:
            whiteboardView.setTool(tool: currentShapeToolConfig.shape.wbTool)
            let shapeBrush: BrushType = .light
            whiteboardView.setStrokeWidth(shapeBrush.brushValue)
            whiteboardView.setColor(currentShapeToolConfig.color)
            configShapeToSDK(shape: currentShapeToolConfig.shape)
        default:
            return
        }
    }
}

// MARK: 删除白板页
extension WhiteboardViewController: DeleteWhiteboardPageDeledate {
    func deletePage(item: WhiteboardSnapshotItem?) {
        self.deleteOnePage(item: item, whiteboardId: whiteboardId, userId: userId)
    }
}

// MARK: ipad 多白板页面 collection
extension WhiteboardViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.ipadItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WhiteboardIPadSnapshotCell.description(), for: indexPath) as? WhiteboardIPadSnapshotCell else {
            return UICollectionViewCell()
        }
        cell.configCell(with: ipadItems[indexPath.row])
        cell.delegate = self
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 已经选中不重复触发
        if ipadItems[indexPath.row].state == .selected { return }
        // 切换共享页面
        let pageNum = ipadItems[indexPath.row].page.pageNum
        let page: WhiteboardPage = WhiteboardPage(pageID: ipadItems[indexPath.row].page.pageID, pageNum: pageNum, isSharing: true)
        WhiteboardTracks.trackBoardClick(.multiBoardSelectPage(pageNum: Int(pageNum)), whiteboardId: whiteboardId)
        let request = OperateWhiteboardPageRequest(action: .changeSharePage, whiteboardId: ipadItems[indexPath.row].whiteboardId, pages: [page])
        HttpClient(userId: userId).getResponse(request) { [weak self] r in
            switch r {
            case .success:
                logger.info("operateWhiteboardPage changeSharePage success")
            case .failure(let error):
                logger.info("operateWhiteboardPage changeSharePage error: \(error)")
            }
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.containView.isHidden = true
                self.multiPageButton.setImage(self.foldImage, for: .normal)
                self.multiPageButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
                self.whiteboardView.setMiniScale()
            }
        }
    }
}

// MARK: 擦除动作，擦除自己，他人，全部
extension WhiteboardViewController: EraseStrokeDelegate {
    func eraseStroke(type: EraserType) {
        switch type {
        case .clearOther:
            WhiteboardTracks.trackBoardClick(.clearSelection(eraserType: .clearOther), whiteboardId: whiteboardId)
            whiteboardView.clearOthers()
        case .clearAll:
            WhiteboardTracks.trackBoardClick(.clearSelection(eraserType: .clearAll), whiteboardId: whiteboardId)
            whiteboardView.clearAll()
        case .clearMine:
            WhiteboardTracks.trackBoardClick(.clearSelection(eraserType: .clearMine), whiteboardId: whiteboardId)
            whiteboardView.clearMine()
        default:
            return
        }
        self.iPadEraserView.isHidden = true
    }
}

// MARK: ipad 二级菜单操作（包含笔画颜色形状）
extension WhiteboardViewController: ToolAndColorDelegate {
    func didTapToolOrColor(tool: ActionToolType?, color: ColorType?) {
        if let tool = tool {
            switch currentTool {
            case .pen:
                let brushType = tool.brushType ?? .light
                currentPenToolConfig.brushType = brushType
                whiteboardView.setPenStroke(brush: brushType)
                WhiteboardTracks.trackBoardClick(.drawSelection(penOrBrush: tool), whiteboardId: whiteboardId)
            case .highlighter:
                let brushType = tool.brushType ?? .light
                currentHighlighterToolConfig.brushType = brushType
                whiteboardView.setHightlighterStroke(brush: brushType)
                WhiteboardTracks.trackBoardClick(.drawSelection(penOrBrush: tool), whiteboardId: whiteboardId)
            case .shape:
                currentShapeToolConfig.shape = tool
                WhiteboardTracks.trackBoardClick(.shapeSelection(shape: tool), whiteboardId: whiteboardId)
                whiteboardView.setShapeType(shape: tool)
                configShapeToSDK(shape: tool)
            default:
                break
            }
        }
        if let color = color {
            WhiteboardTracks.trackBoardClick(.colorSelection(color: color), whiteboardId: whiteboardId)
            switch currentTool {
            case .pen:
                currentPenToolConfig.color = color
                whiteboardView.setPenColor(color: color)
            case .highlighter:
                currentHighlighterToolConfig.color = color
                whiteboardView.setHightlighterColor(color: color)
            case .shape:
                currentShapeToolConfig.color = color
                whiteboardView.setShapeColor(color: color)
                configShapeToSDK(shape: currentShapeToolConfig.shape)
            default:
                break
            }
            iPadShapeTool.isHidden = true
            iPadBrushAndColorView.isHidden = true
        }
    }
}

extension WhiteboardViewController {
    @objc func showMultiPages() {
        DispatchQueue.main.async {
            WhiteboardTracks.trackBoardClick(.multiBoard, whiteboardId: self.whiteboardId)
            if !self.containView.isHidden {
                self.multiPageButton.setImage(self.foldImage, for: .normal)
                self.multiPageButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
            } else {
                self.multiPageButton.setImage(self.unFoldImage, for: .normal)
                self.multiPageButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            }
            if !self.containView.isHidden {
                self.containView.isHidden = true
                return
            }
            self.ipadItems = self.whiteboardView.getSnapshotItems().sorted(by: { $0.index < $1.index })
            self.pagesLayoutStyle = self.calculateHeight()
            self.containView.snp.remakeConstraints { maker in
                maker.right.equalToSuperview().inset(16)
                maker.bottom.equalTo(self.multiPageButton.snp.top).offset(-8)
                maker.width.equalTo(Layout.containViewWidth)
                if case .adaption(let height) = self.pagesLayoutStyle {
                    maker.height.equalTo(height)
                } else {
                    maker.top.equalToSuperview().inset(12)
                }
            }
            self.containView.isHidden = false
            self.collectionView.reloadData()
        }
    }
// MARK: ipad新建页面
    @objc func createPage() {
        guard self.ipadItems.count < maxPageCount else {
            let config = UDToastConfig(toastType: .info, text: BundleI18n.Whiteboard.View_G_MaxBoardCreateNote(maxPageCount), operation: nil)
            UDToast.showToast(with: config, on: view)
            return
        }
        guard let item = ipadItems.last else { return }
        showLoading(true)
        let newPage = WhiteboardPage(pageID: 0, pageNum: item.page.pageNum + 1, isSharing: true)
        WhiteboardTracks.trackBoardClick(.newBoard, whiteboardId: item.whiteboardId)
        let request = OperateWhiteboardPageRequest(action: .newPage, whiteboardId: item.whiteboardId, pages: [item.page, newPage])
        HttpClient(userId: userId).getResponse(request) { [weak self] r in
            switch r {
            case .success:
                self?.showLoading(false)
                logger.info("operateWhiteboardPage newPage success")
                self?.whiteboardView.setLayerScale()
            case .failure(let error):
                self?.showLoading(false, isFailed: true)
                logger.info("operateWhiteboardPage newPage error: \(error)")
            }
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.containView.isHidden = true
                self.multiPageButton.setImage(self.foldImage, for: .normal)
                self.multiPageButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
            }
        }
    }

    func showLoading(_ isLoading: Bool, isFailed: Bool = false) {
        DispatchQueue.main.async {
            if isLoading {
                self.createPageButton.isEnabled = false
                self.createPageButton.addSubview(self.loadingView)
                // nolint-next-line: magic number
                let offset = self.createPageButton.titleLabel?.text?.vc.boundingWidth(height: 48, font: .systemFont(ofSize: 17)) ?? 0
                self.loadingView.snp.remakeConstraints { (maker) in
                    maker.right.equalTo(self.createPageButton.snp.centerX).offset(-offset / 2.0)
                    maker.centerY.equalToSuperview()
                    maker.size.equalTo(CGSize(width: 16, height: 16))
                }
                self.loadingView.play()
                self.createPageButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            } else {
                self.createPageButton.isEnabled = true
                self.createPageButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                self.loadingView.stop()
                self.loadingView.removeFromSuperview()
            }
        }
    }
}
