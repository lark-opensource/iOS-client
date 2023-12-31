//
//  OpenPluginMediaProxy.swift
//  OPPluginBiz
//
//  Created by ByteDance on 2023/12/7.
//

import Foundation

public protocol OpenPluginMediaProxy {
    
    func saveImageToPhotosAlbum(tokenIdentifier: String?, imageData: Data?, completion: @escaping (Bool, Error?) -> Void)
    
    func saveVideoToPhotosAlbum(tokenIdentifier: String?, fileURL: URL?, completion: @escaping (Bool, Error?) -> Void)

}

