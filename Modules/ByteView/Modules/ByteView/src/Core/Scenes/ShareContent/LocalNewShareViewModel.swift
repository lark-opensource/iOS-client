//
//  LocalNewShareViewModel.swift
//  ByteView
//
//  Created by Tobb Huang on 2021/5/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import ByteViewNetwork
import ByteViewSetting

class LocalNewShareViewModel: NewShareSettingsVMProtocol {
    lazy var adapter: IterableAdapter = {
        var items: [NewShareContentItem] = []
        if setting.isMagicShareNewDocsEnabled {
            items.append(docs)
        }
        if setting.isMSDocXEnabled {
            items.append(docX)
        }
        items.append(sheet)
        items.append(mind)
        if setting.isMagicShareNewBitableEnabled {
            items.append(bitable)
        }

        let section = SectionPresentable(items)
        return IterableAdapter([section])
    }()

    lazy var validFileTypes: [NewShareContentItem] = {
        var items: [NewShareContentItem] = []
        if setting.isMagicShareNewDocsEnabled {
            items.append(docs)
        }
        if setting.isMSDocXEnabled {
            items.append(docX)
        }
        items.append(sheet)
        items.append(mind)
        if setting.isMagicShareNewBitableEnabled {
            items.append(bitable)
        }
        return items
    }()

    lazy var docs: NewShareContentItem = {
        return NewShareContentItem(
            title: I18n.View_VM_NewDocs,
            image: VcDocType.doc.typeIcon) { [weak self] _ in
            MagicShareTracksV2.trackShareWindowOperation(action: .clickNewDocs, isLocal: true)
            self?.startSharing(.newShare(.doc))
        }
    }()

    lazy var sheet: NewShareContentItem = {
        return NewShareContentItem(
            title: I18n.View_VM_NewSheets,
            image: VcDocType.sheet.typeIcon) { [weak self] _ in
            MagicShareTracksV2.trackShareWindowOperation(action: .clickNewSheets, isLocal: true)
            self?.startSharing(.newShare(.sheet))
        }
    }()

    lazy var mind: NewShareContentItem = {
        return NewShareContentItem(
            title: I18n.View_VM_NewMindNotes,
            image: VcDocType.mindnote.typeIcon) { [weak self] _ in
            MagicShareTracksV2.trackShareWindowOperation(action: .clickNewMindNotes, isLocal: true)
            self?.startSharing(.newShare(.mindnote))
        }
    }()

    lazy var bitable: NewShareContentItem = {
        return NewShareContentItem(
            title: I18n.View_G_CreatNewBitables_SharedScreen,
            image: VcDocType.bitable.typeIcon) { [weak self] _ in
            MagicShareTracksV2.trackShareWindowOperation(action: .clickNewBitable, isLocal: true)
            self?.startSharing(.newShare(.bitable))
        }
    }()

    lazy var docX: NewShareContentItem = {
        return NewShareContentItem(
            title: I18n.View_VM_NewDocs,
            image: VcDocType.docx.typeIcon,
            showBeta: setting.isMSCreateNewDocXBetaShow) { [weak self] _ in
            MagicShareTracksV2.trackShareWindowOperation(action: .clickNewDocX, isLocal: true)
            self?.startSharing(.newShare(.docx))
        }
    }()

    let setting: MeetingSettingManager
    let startSharing: StartSharing

    var showLoadingObservable: Observable<Bool>

    init(setting: MeetingSettingManager, startSharing: @escaping StartSharing, showLoadingObservable: Observable<Bool>) {
        self.setting = setting
        self.startSharing = startSharing
        self.showLoadingObservable = showLoadingObservable
    }
}
