//
//  FocusFilterIntent.swift
//  LarkAppIntents
//
//  Created by Hayden on 2022/9/5.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import AppIntents
import LarkHTTP
import LarkExtensionServices
import LarkStorageCore

@available(iOS 16.0, *)
struct LarkFocusFilterIntent: SetFocusFilterIntent {

    static var title: LocalizedStringResource {
        return LocalizedStringResource("title")
    }

    static var description: IntentDescription? {
        return IntentDescription(LocalizedStringResource("description"))
    }

    @Parameter(title: LocalizedStringResource("selected_status"), optionsProvider: FocusOptionsProvider())
    var status: StatusEntity?

    // 参数的标题以及参数值
    var displayRepresentation: DisplayRepresentation {
        var subtitleList: [String] = []
        if let status = self.status {
            subtitleList.append("\(status.title)")
        }
        let title = LocalizedStringResource("selected_status")
        let subtitle = LocalizedStringResource("\(subtitleList.formatted())")
        return DisplayRepresentation(title: title, subtitle: subtitle)
    }

    func perform() async throws -> some IntentResult {
        Logger.info("--->>> [LarkFocusIntent] perform() called. status \(self.status?.id ?? "nil")")
        var currentFocusStatusID = KVConfig(
            key: KVKeys.Extension.currentFocusStatusID,
            store: KVStores.Extension.globalShared()
        )
        if let idStr = self.status?.id, let id = Int64(idStr) {
            currentFocusStatusID.value = id
            Logger.info("--->>> [LarkFocusIntent] turning on status: \(id).")
            await FocusAPI.turnOnStatus(byID: id)
        } else {
            if let id = currentFocusStatusID.value {
                Logger.info("--->>> [LarkFocusIntent] turning off status: \(id).")
                await FocusAPI.turnOffStatus(byID: id)
            } else {
                Logger.error("--->>> [LarkFocusIntent] turning off Status failed: status ID not found.")
            }
        }
        return .result()
    }

    struct FocusOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [StatusEntity] {
            let res = await FocusAPI.getFocusList().map {
                $0.toStatusEntity()
            }
            return res
        }
    }
}

@available(iOS 16.0, *)
struct StatusEntity: AppEntity {

    var id: String

    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: title))
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "personal_status")
    }

    static var defaultQuery = StatusQuery()
}

@available(iOS 16.0, *)
struct StatusQuery: EntityQuery {

    func entities(for identifiers: [String]) async throws -> [StatusEntity] {
        let res = await FocusAPI.getFocusList().map {
            $0.toStatusEntity()
        }.filter {
            identifiers.contains($0.id)
        }
        return res
    }
}

@available(iOS 16.0, *)
extension ServerPB_Im_settings_UserCustomStatus {

    private func getLanguageKey() -> String {
        guard let languageCode = Locale.current.language.languageCode,
              let region = Locale.current.language.region else { return "en_us" }
        switch languageCode {
        case .english:  return "en_us"
        case .chinese:
            if region == .hongKong {
                return "zh_hk"
            } else if region == .taiwan {
                return "zh_tw"
            } else {
                return "zh_cn"
            }
        case .korean: return "ko_kr"
        case .hindi: return "hi_in"
        case .portuguese: return "pt_br"
        case .french: return "fr_fr"
        case .spanish: return "es_es"
        case .thai: return "th_th"
        case .german: return "de_de"
        case .japanese: return "ja_jp"
        case .italian: return "it_it"
        case .russian: return "ru_ru"
        case .vietnamese: return "vi_vn"
        case .indonesian: return "id_id"
        default: return "en_us"
        }
    }

    func toStatusEntity() -> StatusEntity {
        if let localizedTitle = i18NTitle[getLanguageKey()] {
            return StatusEntity(id: String(id), title: localizedTitle)
        } else {
            return StatusEntity(id: String(id), title: title)
        }
    }
}
