//
//  OCRProtocol.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/8/23.
//

import UIKit
import Foundation
import RxSwift

public enum ImageOCRError: Error {
    case noOCRResult
}

public enum ImageOCRSource {
    case image(UIImage)
    case key(String)
}

public protocol ImageOCRService {
    func recognition(source: ImageOCRSource, extra: [String: Any]) -> Observable<ImageOCRResult>
}

public protocol ImageOCRDelegate: AnyObject {
    func ocrResultCopy(result: String, from: UIViewController, dismissCallback: @escaping (Bool) -> Void)
    func ocrResultForward(result: String, from: UIViewController, dismissCallback: @escaping (Bool) -> Void)
    func ocrResultTapNumber(number: String, from: UIViewController, dismissCallback: @escaping (Bool) -> Void)
    func ocrResultTapLink(link: String, from: UIViewController, dismissCallback: @escaping (Bool) -> Void)
    func ocrRecognizeResult(imageKey: String, str: NSAttributedString)
}
