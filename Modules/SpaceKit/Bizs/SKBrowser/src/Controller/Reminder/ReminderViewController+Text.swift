//
// Created by duanxiaochen.7 on 2020/10/30.
// Affiliated with SKBrowser.
//
// Description:

import SKFoundation
import SKResource

extension ReminderViewController: ReminderTextViewDelegate {

    func setupKeyboardObservation() {
        destroyKeyboardObservation()

        keyboardObserver.on(event: .didShow) { [weak self] (option) in
            guard let self = self else { return }
            self.shouldResetContentSize = false
            // 记录之前的 contentOffset，用于计算上移的距离
            let prevContentOffset = self.scrollView.contentOffset
            // iOS 17 之前 监听键盘事件只会发一次，iOS 17键盘事件会发多次，最后一次时键盘此时已经出现，记录之前的 contentOffset会不正确 所以iOS 17只取第一次的初始位置
            if #available(iOS 17.0, *) {
                if self.recordScrollViewContentOffSet {
                    self.contentOffsetBeforeShowingKeyboard = prevContentOffset
                    self.recordScrollViewContentOffSet = false
                }
            } else {
                self.contentOffsetBeforeShowingKeyboard = prevContentOffset
            }

            // 下面的操作是为了让文本输入框始终处于可见范围，需要计算文本框要上移多少
            // 先计算 keyboard 的 endFrame 的 minY 在 view 里的位置
            // 坐标系转换需要拿当前整个屏幕的frame来转换，否则在台前调度高度会不够
            var keyboardTopInView = self.view.convert(option.endFrame, from: UIScreen.main.coordinateSpace).minY
            // iPad 上需要考虑外接键盘 + formSheet 的形式，这个时候键盘并不遮盖
            keyboardTopInView = min(keyboardTopInView, self.view.frame.maxY)
            // safeArea 是一个用自动布局贴在文本框下面的 view，专门用来计算 contentSize 和 contentOffset 的
            // safeArea 的 frame 与 contentOffset 相减，得到 sareArea 相对于 scrollView frame 顶端的距离
            var safeAreaBottom = self.bottomSafeArea.frame.maxY - prevContentOffset.y
            // 改成相对于 view 顶端的，和键盘保持同一个参考系
            safeAreaBottom += self.topBar.convert(self.topBar.bounds, to: self.view).maxY
            // 用 view 做参考系，safeArea 的 maxY 减去键盘的 minY 即为需要上移的距离
            let elevation = safeAreaBottom - keyboardTopInView

            let newContentOffset = CGPoint(x: prevContentOffset.x, y: max(prevContentOffset.y + elevation, 0))
            UIView.animate(withDuration: option.animationDuration,
                           delay: 0,
                           options: .curveEaseInOut) { [weak self] in
                guard let self = self else { return }
                self.scrollView.setContentOffset(newContentOffset, animated: false)
                self.setTopBarShadow(show: newContentOffset.y > 0)
                self.view.layoutIfNeeded()
            }
        }

        keyboardObserver.on(event: .willHide) { [weak self] (option) in
            guard let self = self else { return }
            self.shouldResetContentSize = true
            UIView.animate(withDuration: option.animationDuration,
                           delay: 0,
                           options: .curveEaseInOut) { [weak self] in
                guard let self = self else { return }
                self.scrollView.setContentOffset(self.contentOffsetBeforeShowingKeyboard, animated: false)
                self.recordScrollViewContentOffSet = true
                self.setTopBarShadow(show: self.contentOffsetBeforeShowingKeyboard.y > 0)
                self.view.layoutIfNeeded()
            }
        }
        keyboardObserver.start()
    }

    func destroyKeyboardObservation() {
        keyboardObserver.clear()
        keyboardObserver.stop()
    }

    func setTextItem(isHidden: Bool) {
        textItemView.isHidden = isHidden
        if isHidden {
            textItemHeightIsZeroConstraint.activate()
            textItemHeightInequalityConstraint.deactivate()
        } else {
            textItemHeightIsZeroConstraint.deactivate()
            textItemHeightInequalityConstraint.activate()
        }
    }
    func textDidChange(to newText: String?, heightDiff: (String?) -> CGFloat) {
        guard newText != reminder.notifyText else { return }
        let contentHeightChange = heightDiff(reminder.notifyText)
        DocsLogger.debug("contentHeightChange: \(contentHeightChange)", component: LogComponents.reminder)
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y + contentHeightChange),
                                    animated: false)
        setTopBarShadow(show: scrollView.contentOffset.y + contentHeightChange > 0)
        updateReminderText(to: newText)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        scrollView.contentSize = CGSize(width: view.frame.width, height: bottomSafeArea.frame.maxY)
    }

    /// 更新reminder数据的提醒文字
    func updateReminderText(to newText: String?) {
        reminder.notifyText = newText
    }
}
