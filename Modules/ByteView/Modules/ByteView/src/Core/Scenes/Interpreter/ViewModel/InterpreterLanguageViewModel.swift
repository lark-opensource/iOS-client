//
//  InterpreterLanguageViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2020/10/22.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewNetwork
import ByteViewSetting

class InterpreterLanguageViewModel {

    typealias SelectionBlock = ((LanguageType) -> Void)

    private let languageRelay: BehaviorRelay<[InterpreterLanguagInfoSectionModel]> = BehaviorRelay<[InterpreterLanguagInfoSectionModel]>(value: [])
    private let searchSubject: BehaviorSubject<String?> = BehaviorSubject<String?>(value: nil)

    var languageDataSource: Observable<[InterpreterLanguagInfoSectionModel]> {
        languageRelay.asObservable()
    }

    var searchObserver: AnyObserver<String?> {
        searchSubject.asObserver()
    }

    private let disposeBag = DisposeBag()
    private let selectedLanguage: LanguageType
    let selectionBlock: SelectionBlock

    init(selectedLanguage: LanguageType, httpClient: HttpClient, supportLanguages: [InterpreterSetting.LanguageType], selectionBlock: @escaping SelectionBlock) {
        self.selectedLanguage = selectedLanguage
        self.selectionBlock = selectionBlock

        bindMeeting(httpClient: httpClient, supportLanguages: supportLanguages)
    }

    private func bindMeeting(httpClient: HttpClient, supportLanguages: [InterpreterSetting.LanguageType]) {
        let selectedLanguage = self.selectedLanguage
        let meetingSupportLanguagesObs = Observable.just(supportLanguages)
            .filter { !$0.isEmpty }
            .flatMapLatest { (langs) -> Observable<[InterpreterLanguageInfo]> in
                return RxTransform.single {
                    httpClient.i18n.get(langs.map { $0.despI18NKey }, completion: $0)
                }.map { template in
                    langs.map { InterpreterLanguageInfo(languageType: $0,
                                                        i18nText: template[$0.despI18NKey],
                                                        isSelected: selectedLanguage.sameAs(lang: $0)) }
                }
                .asObservable()
                .catchErrorJustReturn([])
            }

        Observable.combineLatest(meetingSupportLanguagesObs, searchSubject.asObservable())
            .subscribe(onNext: { [weak self] infos, searchKey in
                if let searchKey = searchKey, !searchKey.isEmpty {
                    self?.updateLanguageInfo(infos.filter({ info -> Bool in
                        return info.i18nText?.lowercased().contains(searchKey.lowercased()) ?? false
                    }))
                } else {
                    self?.updateLanguageInfo(infos)
                }
            })
            .disposed(by: disposeBag)
    }

    private func updateLanguageInfo(_ info: [InterpreterLanguageInfo]) {
        languageRelay.accept([InterpreterLanguagInfoSectionModel(items: info)])
    }
}
