//
//  PreviewImageUploader.swift
//  LarkAvatar
//
//  Created by 姚启灏 on 2020/3/5.
//

import UIKit
import Foundation
import RxSwift
import LarkUIKit
import LarkImageEditor

public typealias ImageSourceProvider = () -> UIImage?

public protocol PreviewImageUploader {
    func upload(_ imageSources: [ImageSourceProvider], isOrigin: Bool) -> Observable<[String]>
    var imageEditAction: ((ImageEditEvent) -> Void)? { get }
}
