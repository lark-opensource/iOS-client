//
//  DocLikesType.swift
//  SKCommon
//
//  Created by lijuyou on 2020/7/13.
//  


import Foundation
import SpaceInterface

//From UtilLikeListService
//跟服务端进行交互的点赞类型
public enum DocLikesType: Int {
    case doc = 1
    case sheet = 2
    case slide = 3
    case bitable = 4
    case comment = 5
    case drive = 6
    case docX = 22

    /// 做非DocsType类型的转换
    private static func specialPathMapping() -> [String: DocLikesType] {
        return ["/comment/": DocLikesType.comment] // dict形式，方便以后新增其他特殊类型
    }
    private static func likeTypeBy(path: String) -> DocLikesType? {
        var type: DocLikesType?
        for (pathMark, likeType) in DocLikesType.specialPathMapping() {
            if path.lowercased().range(of: pathMark) != nil {
                type = likeType
                break
            }
        }
        return type
    }

    public func docType() -> DocsType {
        switch self {
        case .doc:
            return DocsType.doc
        case .sheet:
            return DocsType.sheet
        case .bitable:
            return DocsType.bitable
        case .drive:
            return DocsType.file
        case .docX:
            return DocsType.docX
        default: // 再次新增类型转换的时候，务必到这个方法中取检查需要新增逆向转换不？transformToLikeType(use docsType: DocsType)
            return DocsType.doc
        }
    }

    /// 新增识别likeType方法之后，为了减少其他地方的改动，此处增加一个冗余的转换，虽然其他地方业务逻辑会反向转化回来
     static func transformToLikeType(use docsType: DocsType) -> DocLikesType {
         var type: DocLikesType = .doc
         switch docsType {
         case .doc: type = .doc
         case .sheet: type = .sheet
         case .bitable: type = .bitable
         case .file, .mediaFile: type = .drive
         case .docX: type = .docX
         default:
             type = .doc
         }
         return type
     }

    public static func likeTypeBy(url: URL) -> DocLikesType? {

        // 先匹配跟DocsType没有一一对应的类型，比如：comment
        // 同时考虑到以后新增类型，再次转换成DocsType的情况
        if let type = likeTypeBy(path: url.path) {
            return type
        }

        let (_, type) = DocsUrlUtil.getFileInfoFrom(url)
        // 此处不对token做校验了，看方法名的作用是识别类型
        guard let fileType = type else { return nil }

        return transformToLikeType(use: fileType)

    }
}
