//
//  OPMockMediaService.swift
//  OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/12/7.
//

import Foundation
import LarkAssembler
import Swinject
import OPPlugin

final class OpenPlatformMockMediaProvider: OpenPluginMediaProxy {
    func saveImageToPhotosAlbum(tokenIdentifier: String?, imageData: Data?, completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }
    
    func saveVideoToPhotosAlbum(tokenIdentifier: String?, fileURL: URL?, completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }
    
}
