//
//  LiveSettingsDataSource.swift
//  ByteView
//
//  Created by yangfukai on 2020/11/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxDataSources

struct LiveSettingsSectionModel: SectionModelType {
    init(items: [LiveSettings]) {
        self.items = items
    }

    init(original: LiveSettingsSectionModel, items: [LiveSettings]) {
        self = original
        self.items = items
    }

    var items: [LiveSettings]
    var headText: String?
    typealias Item = LiveSettings
}

class LiveSettingDataSource: RxTableViewSectionedReloadDataSource<LiveSettingsSectionModel> {
}
