//
// Created by duanxiaochen.7 on 2020/10/30.
// Affiliated with SKBrowser.
//
// Description:

import Foundation
import UniverseDesignColor

extension ReminderViewController {
    /// 根据是否选择全天更新提醒选项
    func setNoticeItem(shouldSetTime: Bool) {
        noticeSelectArray.accept(shouldSetTime ? context.config.noticePickerConfig.noticeAtAMoment : context.config.noticePickerConfig.noticeOnADay)
    }

    /// 设置提醒选择器是否显示，是否需要滚动到底部展开
    func setNoticePicker(isHidden: Bool, scrollsToBottom: Bool) {
        guard noticePicker.isHidden != isHidden else { return }
        noticeItemView.setArrowState(to: isHidden ? .down : .up)
        noticePicker.isHidden = isHidden
//        if context.config.showWholeDaySwitch {
//            let offsetY = 731 - contentView.frame.height
//            contentView.setContentOffset(CGPoint(x: 0, y: isHidden ? 0 : offsetY > 0 ? offsetY : 0), animated: true)
//            contentView.isScrollEnabled = isHidden
//        }
        UIView.animate(withDuration: self.animateDuration) {
            self.noticePicker.snp.updateConstraints { (make) in
                make.height.equalTo(isHidden ? 0 : 156)
            }
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.updateDisplayAreaContentSize()
            if scrollsToBottom {
                self.scrollsToBottomAnimated(true)
            }
        }
        if isHidden {
            noticeItemView.rightView.textColor = UDColor.textCaption
        } else {
            noticeItemView.rightView.textColor = UDColor.colorfulBlue
            updateNoticePicker()
        }
    }

    /// 更新提醒选择器的选项
    func updateNoticePicker() {
        guard let notifyStrategy = reminder.notifyStrategy else { return }
        let shouldSetTime = reminder.shouldSetTime ?? true
        let listItem = shouldSetTime ? context.config.noticePickerConfig.noticeAtAMoment : context.config.noticePickerConfig.noticeOnADay
        let index = listItem.firstIndex(where: { p in p.key == notifyStrategy }) ?? 1
        noticeItemView.rightView.text = listItem[index].value
        noticeSelectedRow.accept(index)
    }
}
