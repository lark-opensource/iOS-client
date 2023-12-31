//
//  PreloadKey+CustomParseResource.swift
//  SpaceKit
//
//  Created by chengqifan on 2019/8/26.
//  

import Foundation

// MARK: Parse image from slide clientvars
extension PreloadKey {
    var customeParseImageSrcs: [[String: String]]? {
        if type == .slides {
            return parseSlideImageSrcsFromClientVars()
        }
        return nil
    }

    var customeParseComments: [String]? {
        if type == .slides {
            return parseSlideCommentsFromClientVars()
        }
        return nil
    }

    /// 自定义解析Slide中图片链接
    ///
    /// - Returns: 图片链接 ["src": "xxxx"]
    private func parseSlideImageSrcsFromClientVars() -> [[String: String]]? {
        guard let clientVars = newCacheAPI.object(forKey: objToken, subKey: clientVarKey) as? [String: Any] else {
            return nil
        }
        return slideImageScrsOfClientVars(clientVars)
    }

    /// 判断Slide是否有评论
    ///
    /// - Returns: return value description
    private func parseSlideCommentsFromClientVars() -> [String]? {
        guard let clientVars = newCacheAPI.object(forKey: objToken, subKey: clientVarKey) as? [String: Any] else {
            return nil
        }
        return slideCommentsOfClientVars(clientVars)
    }

    //解析Slide Pages
    private func slidePages(_ clientVars: [String: Any]) -> [String: Any]? {
        guard let dataLevel1 = clientVars["data"] as? [String: Any],
            let dataType = dataLevel1["type"] as? String,
            dataType == "CLIENT_VARS",
            let dataLevel2 = dataLevel1["data"] as? [String: Any],
            let dataLevel3 = dataLevel2["data"] as? [String: Any],
            let slide = dataLevel3["slide"] as? [String: Any],
            let pages = slide["pages"] as? [String: Any] else {
                return nil
        }
        return pages
    }
    //解析Slide elements
    private func slideElementsOfPage(_ page: [String: Any]) -> [String: Any]? {
        guard let elements = page["elements"] as? [String: Any] else { return nil }
        return elements
    }

    //解析Slide图片
    private func slideImageScrsOfClientVars(_ clientVars: [String: Any]) -> [[String: String]]? {
        var imageSrcs = [[String: String]]()
        slidePages(clientVars)?.forEach({ (pageParams) in
            let (_, pageValue) = pageParams
            guard let page = pageValue as? [String: Any] else { return }
            //背景图片
            if let background = page["background"] as? [String: Any],
                let fillType = background["fillType"] as? String,
                fillType == "IMAGE",
                let backgroundImage = background["image"] as? [String: Any],
                let url = backgroundImage["url"] as? String {
                imageSrcs.append(["src": url])
            }
            slideElementsOfPage(page)?.forEach { (elementValue) in
                let (_, element) = elementValue
                guard let eid = element as? [String: Any],
                    let type = eid["type"] as? String,
                    type == "IMAGE",
                    let url = eid["url"] as? String else { return }
                imageSrcs.append(["src": url])
            }
        })
        guard imageSrcs.count > 0  else { return nil }
        return imageSrcs
    }

    //解析Slide评论
    private func slideCommentsOfClientVars(_ clientVars: [String: Any]) -> [String]? {
        var comments = [String]()
        slidePages(clientVars)?.forEach({ (pageParams) in
            let (_, pageValue) = pageParams
            guard let page = pageValue as? [String: Any] else { return }
            if let pagecomments = page["commentIds"] as? [String], pagecomments.count > 0 {
                comments += pagecomments
            }
            slideElementsOfPage(page)?.forEach { (elementValue) in
                let (_, element) = elementValue
                guard let eid = element as? [String: Any],
                    let elementComments = eid["commentIds"] as? [String] else { return }
                comments += elementComments
            }
        })
        guard comments.count > 0 else { return nil }
        return comments
    }

}
