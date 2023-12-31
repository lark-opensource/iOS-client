import UIKit
import UniverseDesignColor
import UniverseDesignShadow

extension UIView {
    func applyFloatingBGAndBorder() {
        self.applyFloatingBorder()
        self.applyFloatingBG()
        self.layer.masksToBounds = true
    }

    func applyFloatingBG() {
        self.backgroundColor = UDColor.vcTokenMeetingBgVideoOff
    }

    func applyFloatingBorder() {
        self.applyFloatingCorner()
        self.layer.borderWidth = 1.0
        self.layer.ud.setBorderColor(UDColor.lineDividerDefault)
    }

    func applyFloatingCorner() {
        self.layer.cornerRadius = 8.0
    }

    func applyFloatingShadow() {
        self.applyFloatingCorner()
        self.layer.ud.setShadow(type: Display.phone ? .s4Down : .s5Down)
        // assert(!self.layer.masksToBounds && !self.clipsToBounds)
    }
}
