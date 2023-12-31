//
//  WhiteboardViewController+Phone.swift
//  Whiteboard
//
//  Created by helijian on 2023/1/16.
//

import Foundation
import ByteViewUI

// WhiteboardViewTouchEventDelegate相关方法
extension WhiteboardViewController: WhiteboardViewTouchEventDelegate {

    func whiteboardViewIsZoomingOrDragging(isZoomingOrDragging: Bool) {
        DispatchQueue.main.async {
            if isZoomingOrDragging {
                // nolint-next-line: magic number
                UIView.animate(withDuration: 0.25, animations: {
                    self.phoneToolBar.alpha = 0.3
                })
            } else {
                // nolint-next-line: magic number
                UIView.animate(withDuration: 0.25, animations: {
                    self.phoneToolBar.alpha = 1
                })
            }
        }
    }

    func changeWhiteboardPhoneMenuHiddenStatus(to isHidden: Bool, isUpdate: Bool = false, animated: Bool = true) {
        // nolint-next-line: magic number
        UIView.animate(withDuration: animated ? 0.25 : 0, animations: { [weak self] in
            self?.whiteboardView.setWhiteboardMenuDisplayStatus(to: !isHidden, isUpdate: isUpdate)
        })
        self.setFailofGestRecognizer(shouldReceive: !isHidden)
    }
}

// WhiteboardViewDelegate有关方法
extension WhiteboardViewController {
    func changePhoneUndoState(canUndo: Bool) {
        self.phoneToolBar.setUndoButtonState(canUndo: canUndo)
    }

    func shouldReloadPhoneSnapshot(item: WhiteboardSnapshotItem) {
        self.snapShotVC?.reloadItem(item: item)
    }

    func changePhoneMultiPageInfo(currentPageNum: Int32, totalPages: Int) {
        self.snapShotVC?.changeMultiPageInfo(currentPageNum: currentPageNum)
    }

    func shouldReloadPhoneTotalSnapshot() {
        let items = self.whiteboardView.getSnapshotItems()
        self.snapShotVC?.resetItems(items: items)
    }
}

// 菜单切换点击事件相关方法
extension WhiteboardViewController {
    func didTapPhoneMore() {
        var items: [WhiteboardMoreSectionModel] = []

        let morePageCellModel = WhiteboardMorePresentModel(cellIdentifier: WhiteboardMorePageCell.description(),
                                                           title: BundleI18n.Whiteboard.View_MV_OtherBoardsTab,
                                                           action: { [weak self] from in
            guard let from = from else { return }
            guard let self = self else { return }
            let items = self.whiteboardView.getSnapshotItems()
            guard !items.isEmpty else {
                logger.info("multi snapshot items empty")
                return
            }
            WhiteboardTracks.trackBoardClick(.multiBoard, whiteboardId: self.whiteboardId)
            let vc = WhiteboardPhoneSnapshotViewController(items: items, userId: self.userId, whiteboardId: self.whiteboardId, maxPageCount: self.maxPageCount)
            vc.scaleLayerBlock = { [weak self] in
                self?.whiteboardView.setLayerScale()
            }
            vc.resetMiniScaleBlock = { [weak self] in
                self?.whiteboardView.setMiniScale()
            }
            self.snapShotVC = vc
            if let panVC = from.navigationController?.panViewController {
                panVC.push(vc, animated: true)
                return
            }
            from.presentDynamicModal(vc,
                                     regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                     compactConfig: .init(presentationStyle: .pan, needNavigation: true))
        })
        items.append(WhiteboardMoreSectionModel(items: [morePageCellModel]))
        let clearMine = WhiteboardMoreDetailModel(cellIdentifier: WhiteboardMoreDetailCell.description(), title: BundleI18n.Whiteboard.View_MV_ClearOwnContent, isLastModel: false, clickHandler: { [weak self] in
            WhiteboardTracks.trackBoardClick(.clearSelection(eraserType: .clearMine), whiteboardId: self?.whiteboardId ?? 0)
            self?.whiteboardView.clearMine()
        })
        if self.whiteboardView.isSelfSharing() {
            let clearOther = WhiteboardMoreDetailModel(cellIdentifier: WhiteboardMoreDetailCell.description(), title: BundleI18n.Whiteboard.View_MV_ClearOthersContent, isLastModel: false, clickHandler: { [weak self] in
                WhiteboardTracks.trackBoardClick(.clearSelection(eraserType: .clearOther), whiteboardId: self?.whiteboardId ?? 0)
                self?.whiteboardView.clearOthers()
            })
            let clearAll = WhiteboardMoreDetailModel(cellIdentifier: WhiteboardMoreDetailCell.description(), title: BundleI18n.Whiteboard.View_MV_ClearAll, isLastModel: true, clickHandler: { [weak self] in
                WhiteboardTracks.trackBoardClick(.clearSelection(eraserType: .clearAll), whiteboardId: self?.whiteboardId ?? 0)
                self?.whiteboardView.clearAll()
            })
            items.append(WhiteboardMoreSectionModel(items: [clearMine, clearOther, clearAll], headerText: BundleI18n.Whiteboard.View_MV_ClearBoard))
        } else {
            items.append(WhiteboardMoreSectionModel(items: [clearMine], headerText: BundleI18n.Whiteboard.View_MV_ClearBoard))
        }

        if self.isSaveEnabled {
            if self.whiteboardView.hasMultiBoards {
                let saveCurrent = WhiteboardMoreDetailModel(cellIdentifier: WhiteboardMoreDetailCell.description(), title: BundleI18n.Whiteboard.View_G_SaveThisWhiteBoard_Button, isLastModel: false, clickHandler: { [weak self] in
                    WhiteboardTracks.trackBoardClick(.saveCurrent, whiteboardId: self?.whiteboardId ?? 0, isSharer: self?.whiteboardView.isSelfSharing())
                    self?.whiteboardView.saveCurrent()
                })
                let saveAll = WhiteboardMoreDetailModel(cellIdentifier: WhiteboardMoreDetailCell.description(), title: BundleI18n.Whiteboard.View_G_SaveAllWhiteBoard_Button, isLastModel: true, clickHandler: { [weak self] in
                    WhiteboardTracks.trackBoardClick(.saveAll, whiteboardId: self?.whiteboardId ?? 0, isSharer: self?.whiteboardView.isSelfSharing())
                    self?.whiteboardView.saveAll()
                })
                items.append(WhiteboardMoreSectionModel(items: [saveCurrent, saveAll]))
            } else {
                let save = WhiteboardMoreDetailModel(cellIdentifier: WhiteboardMoreDetailCell.description(), title: BundleI18n.Whiteboard.View_G_SaveAnnoWhiteBoard_Button, isLastModel: true, clickHandler: { [weak self] in
                    WhiteboardTracks.trackBoardClick(.saveCurrent, whiteboardId: self?.whiteboardId ?? 0, isSharer: self?.whiteboardView.isSelfSharing())
                    self?.whiteboardView.saveCurrent()
                })
                items.append(WhiteboardMoreSectionModel(items: [save]))
            }
        }

        let vc = WhiteboardMoreViewController(items: items)
        self.moreVC = vc
        self.presentDynamicModal(vc,
                                 regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                 compactConfig: .init(presentationStyle: .pan, needNavigation: true))
    }

    func didTapPhoneExit() {
        shouldShowMenuFirst = false
        self.showMenuButton.isHidden = false
        self.phoneToolBar.isHidden = true
        changeWhiteboardPhoneMenuHiddenStatus(to: true)
    }

    func didTapPhoneEraser() {
        whiteboardView.setTool(tool: .Eraser)
    }

    func didChangePhoneColor(color: ColorType) {
        if currentTool == .pen {
            currentPenToolConfig.color = color
            whiteboardView.setPenColor(color: color)
        } else if currentTool == .highlighter {
            currentHighlighterToolConfig.color = color
            whiteboardView.setHightlighterColor(color: color)
        } else if currentTool == .shape {
            currentShapeToolConfig.color = color
            whiteboardView.setShapeColor(color: color)
            configShapeToSDK(shape: currentShapeToolConfig.shape)
        }
        phoneToolBar.didTapLeftArrow()
    }

    func didTapPhoneMove() {
        whiteboardView.setTool(tool: .Move)
    }

    func didChangePhoneBrushType(brushType: BrushType) {
        if currentTool == .pen {
            currentPenToolConfig.brushType = brushType
            whiteboardView.setPenStroke(brush: brushType)
        } else if currentTool == .highlighter {
            currentHighlighterToolConfig.brushType = brushType
            whiteboardView.setHightlighterStroke(brush: brushType)
        } else if currentTool == .shape {
            whiteboardView.setStrokeWidth(brushType.brushValue)
        }
        phoneToolBar.didTapLeftArrow()
    }

    func didChangePhoneToolType(toolType: ActionToolType) {
        switch toolType {
        case .pen, .highlighter, .rectangle, .ellipse, .triangle, .line, .arrow, .save:
            whiteboardView.setTool(tool: toolType.wbTool)
            configShapeToSDK(shape: toolType)
        default:
            break
        }
    }

    func didChangePhoneShapeType(shapeTool: ActionToolType) {
        if [.rectangle, .ellipse, .triangle, .line, .arrow].contains(shapeTool) {
            currentShapeToolConfig.shape = shapeTool
            whiteboardView.setShapeType(shape: shapeTool)
            configShapeToSDK(shape: shapeTool)
        }
    }
}
