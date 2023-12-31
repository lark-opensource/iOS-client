//
// Created by duanxiaochen.7 on 2020/11/23.
// Affiliated with SKBrowser.
//
// Description:

import SKFoundation
import SKCommon
import SKBrowser
import SKResource
import UniverseDesignIcon
import HandyJSON

final class SheetToolbarItemInfo: HandyJSON {
    var id: BarButtonIdentifier = .at
    var hasSelectedState: Bool = false
    var isSelected: Bool = false
    var isBadged: Bool = false
    var text: String?
    var image: UIImage?
    var accID: String = ""
    var isEnabled: Bool = true

    // FIXME: 待删除源文件
    func didFinishMapping() {
        switch id {
        case .systemText:
            text = "ABC"
            accID = "sheets.keyboard.switch.systemABC"
        case .customNumber:
            text = "123"
            accID = "sheets.keyboard.switch.number"
        case .customDate:
            image = UDIcon.calendarOutlined // icon_tool_calendar_nor
            accID = "sheets.keyboard.switch.datetime"
        case .editInCard:
            image = UDIcon.sheetCardmodelOutlined // icon_tool_sheetcard_nor
            accID = "sheets.keyboard.switch.cardmode"
        case .insertImage:
            image = UDIcon.imageOutlined // icon_tool_pickimage_nor
            accID = "sheets.keyboard.insert.image"
        case .checkbox:
            image = UDIcon.todoOutlined // icon_tool_checkbox_nor
            accID = "sheets.keyboard.insert.checkbox"
        case .at:
            image = UDIcon.atOutlined // icon_tool_mention_nor
            accID = "sheets.keyboard.insert.at"
        case .addReminder:
            image = UDIcon.alarmClockOutlined // icon_tool_addreminder_nor
            accID = "sheets.keyboard.insert.reminder"
        default: break
        }
    }

    func updateValue(toSelected selected: Bool) {
        self.isSelected = selected
    }

    func updateValue(toBadged badged: Bool) {
        self.isBadged = badged
    }
}
