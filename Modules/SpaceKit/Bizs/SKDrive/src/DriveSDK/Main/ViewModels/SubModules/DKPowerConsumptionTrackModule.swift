//
//  DKPowerConsumptionTrackModule.swift
//  SKDrive
//
//  Created by chensi(陈思) on 2022/9/4.
// swiftlint://disable pattern_matching_keywords

/*
import RxSwift
import Foundation
import SKFoundation

class DKPowerConsumptionTrackModule: DKBaseSubModule {
    
    private let disposeBag = DisposeBag()
    
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        setupBind()
        return self
    }
    
    private func setupBind() {
        guard let hostModule = hostModule else { return }
        hostModule.previewActionSubject.subscribe(onNext: { action in
            switch action {
            case .openDrive(let token, let appID):
                debugPrint("chensi 77, token:\(token), appID:\(appID)")
            case .setupChildPreviewVC(let openType):
                debugPrint("chensi 77, openType:\(openType)")
            case .openSuccess(let type):
                debugPrint("chensi 77, type:\(type)")
            case .open(let entry, let context):
                debugPrint("chensi 77, entry:\(entry), context:\(context)")
            case .openURL(let url):
                debugPrint("chensi 77, url:\(url)")
            case .exitPreview:
                debugPrint("chensi 77, exitPreview")
            default:
                break
            }
        }).disposed(by: disposeBag)
    }
    
    deinit {
        DocsLogger.driveInfo("\(Self.self) -- deinit")
    }
}
*/
