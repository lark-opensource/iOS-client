//
//  RecognizeLanguageManager.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/8/19.
//

import Foundation
import LarkLocalizations
import RxCocoa
import RxSwift

public final class RecognizeLanguageManager {
    public enum RecognizeType: String, Codable {
        case audioWithText
        case audio
        case text
    }

    public static let shared = RecognizeLanguageManager()

    lazy var languageSubject: BehaviorRelay<Lang> = {
        return BehaviorRelay(value: self.recognitionLanguage)
    }()

    public var recognitionLanguage: Lang {
        get {
            return KVStore.recognitionLanguage
        }
        set {
            KVStore.recognitionLanguage = newValue
            self.languageSubject.accept(newValue)
        }
    }

    public var recognitionLanguageI18n: String {
        get {
            return KVStore.recognitionI18n
        }
        set {
            KVStore.recognitionI18n = newValue
        }
    }

    public lazy var typeSubject: BehaviorRelay<RecognizeType> = {
        return BehaviorRelay(value: self.recognitionType)
    }()

    public var recognitionType: RecognizeType {
        get {
            return KVStore.recognitionType
        }
        set {
            KVStore.recognitionType = newValue
            self.typeSubject.accept(newValue)
        }
    }
}
