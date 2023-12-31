//
//  OpenPluginMediaProvider.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/12/6.
//

import Foundation
import ECOInfra
import OPPlugin

class OpenPlatformMediaProvider: OpenPluginMediaProxy {
       
    func saveImageToPhotosAlbum(tokenIdentifier: String?, imageData: Data?, completion: @escaping (Bool, Error?) -> Void) {
        BDPSaveImageToPhotosAlbum(tokenIdentifier, imageData, completion)
    }
    
    func saveVideoToPhotosAlbum(tokenIdentifier: String?, fileURL: URL?, completion: @escaping (Bool, Error?) -> Void) {
        BDPSaveVideoToPhotosAlbum(tokenIdentifier, fileURL, completion)
    }
}
