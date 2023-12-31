//
//  AudioOutputCallActionSheet.swift
//  ByteView
//
//  Created by kiri on 2023/3/23.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewCommon
import LarkMedia

protocol AudioOutputCallActionSheetDelegate: AnyObject {
    func audioOutputCallActionSheet(_ actionSheet: AudioOutputCallActionSheet, didSelect item: AudioOutputPickerItem)
    func audioOutputCallActionSheetDidPresent(_ actionSheet: AudioOutputCallActionSheet)
    func audioOutputCallActionSheetDidDismiss(_ actionSheet: AudioOutputCallActionSheet)
}

/// used in 1v1 calling/ringing
final class AudioOutputCallActionSheet: AlignPopoverPresentationDelegate {
    let scene: AudioOutputPickerScene
    let output: AudioOutput
    private var isSelected = false
    private weak var picker: AlignPopoverViewController?

    weak var delegate: AudioOutputCallActionSheetDelegate?

    init(scene: AudioOutputPickerScene, output: AudioOutput) {
        self.scene = scene
        self.output = output
    }

    func show(from: UIViewController, anchorView: UIView) {
        let appearance = ActionSheetAppearance(backgroundColor: .ud.bgFloat,
                                               contentViewColor: .ud.bgFloat,
                                               separatorColor: .clear,
                                               modalBackgroundColor: .ud.bgMask,
                                               customTextHeight: 50.0,
                                               tableViewCornerRadius: 0.0)

        let isSelectedSpeaker = self.output == .speaker
        let isSelectedReceiver = self.output == .receiver

        let actionSheetVC = ActionSheetController(appearance: appearance)
        actionSheetVC.modalPresentation = .alwaysPopover
        actionSheetVC.addAction(SheetAction(title: I18n.View_VM_Speaker,
                                            titleColor: isSelectedSpeaker ? .ud.primaryContentDefault : .ud.textTitle,
                                            titleFontConfig: isSelectedSpeaker ? .boldBodyAssist : .bodyAssist,
                                            icon: UDIcon.getIconByKey(.speakerOutlined, iconColor: isSelectedSpeaker ? .ud.primaryContentDefault : .ud.iconN1),
                                            showBottomSeparator: false,
                                            isSelected: isSelectedSpeaker,
                                            sheetStyle: .callIn,
                                            handler: { [weak self] _ in
            guard let self = self else { return }
            self.isSelected = true
            self.delegate?.audioOutputCallActionSheet(self, didSelect: .speaker)
            self.delegate?.audioOutputCallActionSheetDidDismiss(self)
        }))
        actionSheetVC.addAction(SheetAction(title: I18n.View_G_Receiver,
                                            titleColor: isSelectedReceiver ? .ud.primaryContentDefault : .ud.textTitle,
                                            titleFontConfig: isSelectedReceiver ? .boldBodyAssist : .bodyAssist,
                                            icon: UDIcon.getIconByKey(.earOutlined, iconColor: isSelectedReceiver ? .ud.primaryContentDefault : .ud.iconN1),
                                            showBottomSeparator: false,
                                            isSelected: isSelectedReceiver,
                                            sheetStyle: .callIn,
                                            handler: { [weak self] _ in
            guard let self = self else { return }
            self.isSelected = true
            self.delegate?.audioOutputCallActionSheet(self, didSelect: .receiver)
            self.delegate?.audioOutputCallActionSheetDidDismiss(self)
        }))

        let width = actionSheetVC.maxIntrinsicWidth
        let height = actionSheetVC.intrinsicHeight
        let anchor = AlignPopoverAnchor(sourceView: anchorView,
                                        contentWidth: .fixed(width),
                                        contentHeight: height,
                                        contentInsets: UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0),
                                        positionOffset: CGPoint(x: 0, y: 3),
                                        cornerRadius: 8.0,
                                        borderColor: UIColor.ud.lineBorderCard,
                                        dimmingColor: UIColor.clear,
                                        containerColor: UIColor.ud.bgFloat)
        self.picker = AlignPopoverManager.shared.present(viewController: actionSheetVC, from: from, anchor: anchor, delegate: self)
    }

    func dismiss() {
        self.picker?.dismiss(animated: true)
        self.picker = nil
    }

    func didPresent() {
        self.delegate?.audioOutputCallActionSheetDidPresent(self)
    }

    func didDismiss() {
        self.delegate?.audioOutputCallActionSheetDidDismiss(self)
    }
}
