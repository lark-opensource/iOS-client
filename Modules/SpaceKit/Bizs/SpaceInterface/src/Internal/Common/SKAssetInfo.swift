//
//  SKAssetInfo.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/31.
//  


import Foundation

public struct SKAssetInfo {
    public var objToken: String
    public var uuid: String
    public var fileToken: String
    public var picType: String
    public var cacheKey: String
    public var sourceUrl: String
    public var uploadKey: String
    public var fileSize: Int
    public var assetType: String
    public var source: String
    
    public init(objToken: String?, uuid: String? = nil, fileToken: String? = nil, picType: String? = nil, cacheKey: String? = nil, sourceUrl: String? = nil, uploadKey: String? = nil, fileSize: Int? = nil, assetType: String? = nil, source: String? = nil) {
        self.objToken = objToken ?? ""
        self.uuid = uuid ?? ""
        self.fileToken = fileToken ?? ""
        self.picType = picType ?? ""
        self.cacheKey = cacheKey ?? ""
        self.sourceUrl = sourceUrl ?? ""
        self.uploadKey = uploadKey ?? ""
        self.fileSize = fileSize ?? 0
        self.assetType = assetType ?? ""
        self.source = source ?? ""
    }
}
