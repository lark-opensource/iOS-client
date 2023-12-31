//
//  ChatMessageViewController+Transform.swift
//  ByteView
//
//  Created by wulv on 2021/1/19.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

extension ChatMessageViewController {

    func updateTransformWithKeyboard() {
        guard let info = keyboardInfo as NSDictionary? else {
            if editView.transform != .identity {
                editView.transform = .identity
            }
            if tableView.transform != .identity {
                tableView.transform = .identity
            }
            ChatMessageViewModel.logger.info("keyboard - info nil")
            return
        }
        guard let keyboardSize = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            ChatMessageViewModel.logger.info("keyboard - keyboardSize nil")
            return
        }
        guard let duration = info.object(forKey: UIResponder.keyboardAnimationDurationUserInfoKey) as? Double else {
            ChatMessageViewModel.logger.info("keyboard - duration nil")
            return
        }
        guard let curve = info.object(forKey: UIResponder.keyboardAnimationCurveUserInfoKey) as? UInt else {
            ChatMessageViewModel.logger.info("keyboard - curve nil")
            return
        }
        guard let window = UIApplication.shared.keyWindow else {
            ChatMessageViewModel.logger.info("keyboard - window nil")
            return
        }

        /*
         不同的ios版本，pad + slideOver 时拿到的keyboardFrame不同，例如ipad Air2（ipad Pro上也有类似的结果）：
         ios11、ios12: origin = (x = 0, y = 693), size = (width = 1024, height = 35)
         ios13: origin = (x = 0, y = 713), size = (width = 1024, height = 55)
         推测是部分版本下（小于ios13），keyboardFrame的坐标系空间去掉了slideOver浮窗上下相对于整个屏幕的offset，即keyboardFrame.minY + keyboardFrame.height < UIScreen.main.bounds.height，此时不需要再手动加上UIScreen.main.slideOverBottomInset
         */
        let keyboardFrame = keyboardSize.cgRectValue
        var slideOverBottomInset: CGFloat = 0
        if #available(iOS 13.0, *), let scene = self.view.window?.windowScene {
            let frame = scene.coordinateSpace.convert(scene.coordinateSpace.bounds, to: scene.screen.coordinateSpace)
            slideOverBottomInset = scene.screen.bounds.height - frame.maxY
        } else if keyboardFrame.minY + keyboardFrame.height < UIScreen.main.bounds.height {
            slideOverBottomInset = 0
        } else if let w = self.view.window {
            let frame = w.convert(w.bounds, to: w.screen.coordinateSpace)
            slideOverBottomInset = w.screen.bounds.height - frame.maxY
        }
        // 获取发送栏在屏幕中的位置
        let editViewRect = editView.convert(editView.bounds, to: window)
        // 获取键盘的位置
        let keyboardY = keyboardFrame.minY - slideOverBottomInset
        // 如果键盘遮挡发送栏，则发送栏上移
        let editViewGap = keyboardY - editViewRect.maxY
        // 如果已经transform过，需要叠加transform
        let currentEditViewTransformY = editView.transform.ty
        // 仅上移，不可下移
        let newEditViewTransformY = min(0, currentEditViewTransformY + editViewGap)
        ChatMessageViewModel.logger.info("keyboard - keyboardMinY = \(keyboardFrame.minY), slideOverBottomInset = \(slideOverBottomInset), editViewRect = \(editViewRect), editViewGap = \(editViewGap), currentEditViewTransformY = \(currentEditViewTransformY), newEditViewTransformY = \(newEditViewTransformY)")
        let option = UIView.AnimationOptions(rawValue: curve << 16)
        // 获取最后一条cell在屏幕中的位置
        guard let lastCell = tableView.visibleCells.last,
              let lastIndexPath = tableView.indexPath(for: lastCell),
              tableView.rectForRow(at: lastIndexPath) != .zero else {
            UIView.animate(withDuration: duration, delay: 0, options: option, animations: {
                self.editView.transform = CGAffineTransform(translationX: 0, y: newEditViewTransformY)
            })
            return
        }
        let lastCellRect = tableView.rectForRow(at: lastIndexPath)
        // 最底部内容的区域
        let cellRect = lastCell.convert(CGRect(origin: .zero, size: lastCellRect.size), to: window)
        // 最底部内容的区域不超过tableView的底部
        let tableviewRect = tableView.convert(tableView.bounds, to: window)
        // 如果键盘加editView的高度超过最底部内容区域的高度，则tableview上移
        let cellGap = keyboardY - editViewRect.size.height - min(cellRect.maxY, tableviewRect.maxY)
        // 如果已经transform过，需要叠加transform
        let currentTableViewTransformY = tableView.transform.ty
        // 仅上移，不可下移
        let newTableViewTransformY = min(0, currentTableViewTransformY + cellGap)
        ChatMessageViewModel.logger.info("keyboard - lastCellRect = \(lastCellRect), cellRect = \(cellRect), tableviewRect = \(tableviewRect), cellGap = \(cellGap), currentTableViewTransformY = \(currentTableViewTransformY), newTableViewTransformY = \(newTableViewTransformY)")
        UIView.animate(withDuration: duration, delay: 0, options: option, animations: {
            self.editView.transform = CGAffineTransform(translationX: 0, y: newEditViewTransformY)
            self.tableView.transform = CGAffineTransform(translationX: 0, y: newTableViewTransformY)
        })
    }

    func updateEditViewLocation() {
        if editView.transform != .identity {
            editView.transform = .identity
        }
    }

    func setSelectionRange(range: NSRange?) {
        selectedRange = range
        selectedLabel?.initSelectedRange = range
        selectedLabel?.inSelectionMode = range != nil
    }

    func resetSelection() {
        viewModel.unfreezeMessages()
        setSelectionRange(range: nil)
        selectedLabel = nil
        selectedCell = nil
        translateItem = nil
        menu?.dismiss()
        menu = nil
        if let pan = panGesture {
            view.removeGestureRecognizer(pan)
        }
        panGesture = nil
    }
}
