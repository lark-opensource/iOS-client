//
//  DocsIconInfo+DefultIcon.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/19.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import RxSwift
import LarkContainer
import UniverseDesignTheme
import LarkIcon

//---------------MARK: 获取默认图标 ---------------------
extension DocsIconInfo {
    func getDefultIcon(shape: IconShpe = .CIRCLE,
                       container: ContainerInfo? = nil) -> UIImage {
        if let defaultcustomIcon = container?.defaultCustomIcon {
            return defaultcustomIcon
        }
        
        let objType = self.objType
        // 4.1 是否文件夹
        if objType == .folder {
            return UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
        }
        
        switch shape {
        case .CIRCLE: // 圆形
            return self.getCircleDefultIcon(isShortCut: container?.isShortCut ?? false)
        case .SQUARE: // 方型
            return self.getSquareColorfulDefultIcon(isShortCut: container?.isShortCut ?? false)
        case .OUTLINE: // 线框
            return self.getSquareOutlinedDefultIcon(isShortCut: container?.isShortCut ?? false).withRenderingMode(.alwaysTemplate)
        }
    }
}

//---------------MARK: 获取彩色圆形默认图标 ---------------------
extension DocsIconInfo {
    
    fileprivate func getCircleDefultIcon(isShortCut: Bool) -> UIImage  {
        let shortCutImage: UIImage? = isShortCut ? UDIcon.wikiShortcutarrowColorful : nil
        //fg使用，后续会比较快的去掉该fg，就没有用户态的问题
        let featureGating = try? Container.shared.getCurrentUserResolver().resolve(type: DocsIconFeatureGating.self)
        // fg 为true，才显示新的底色逻辑
        if featureGating?.suiteCustomIcon ?? false {
            //FG 为true 才显示圆形图标底色
            if featureGating?.circleBackgroundColor ?? false {
                
                let image = squareColorfulIconImage
                
                //反向fg， FG 为false 接入使用larkIcon
                //fg使用，后续会比较快的去掉该fg，就没有用户态的问题
                if !(featureGating?.larkIconDisable ?? true) {
                    
                    let iconImage = LarkIconBuilder.createImageWith(originImage: image,
                                                                scale: 0.6,
                                                                iconLayer: IconLayer(backgroundColor: self.iconBackgroundColor),
                                                                iconShape: .CIRCLE,
                                                                foreground: IconForeground(foregroundImage: shortCutImage)) ?? image
                    
                    return iconImage
                    
                }

                //后续larkIconDisable fg删掉，后面的代码也删除
                let lightMode = DocsIconCreateUtil.creatImage(image: image,
                                                              isShortCut: isShortCut,
                                                              backgroudColor: self.iconBackgroundColor.alwaysLight)
                let darkMode = DocsIconCreateUtil.creatImage(image: image,
                                                             isShortCut: isShortCut,
                                                             backgroudColor: self.iconBackgroundColor.alwaysDark)
                return lightMode & darkMode

            } else {
                //fg使用，后续会比较快的去掉该fg，就没有用户态的问题
                if !(featureGating?.larkIconDisable ?? true) {
                    let image = UDIcon.getIconByKeyNoLimitSize(self.roundColorfulIconKey)
                    return LarkIconBuilder.createImageWith(originImage: image,
                                                           foreground: IconForeground(foregroundImage: shortCutImage)) ?? image
                }
                
                //后续larkIconDisable fg删掉，后面的代码也删除
                return DocsIconCreateUtil.creatImage(image: UDIcon.getIconByKeyNoLimitSize(self.roundColorfulIconKey),
                                                     isShortCut: isShortCut)
            }
            
        } else { // fg 关 走旧的圆形逻辑
            //fg使用，后续会比较快的去掉该fg，就没有用户态的问题
            if !(featureGating?.larkIconDisable ?? true) {
                let image = UDIcon.getIconByKeyNoLimitSize(self.roundColorfulIconKey)
                return LarkIconBuilder.createImageWith(originImage: image,
                                                       foreground: IconForeground(foregroundImage: shortCutImage)) ?? image
            }
            
            //后续larkIconDisable fg删掉，后面的代码也删除
            return DocsIconCreateUtil.creatImage(image: UDIcon.getIconByKeyNoLimitSize(self.roundColorfulIconKey),
                                                 isShortCut: isShortCut)
            
        }
    }
    
    var roundColorfulIconKey: UDIconType {
        switch objType {
        case .doc:
            return .fileRoundDocColorful
        case .docX:
            return .fileRoundDocxColorful
        case .sheet:
            return .fileRoundSheetColorful
        case .mindnote:
            return .fileRoundMindnoteColorful
        case .slides:
            return .wikiSlidesCircleColorful
        case .bitable:
            return .fileRoundBitableColorful
        case .file:
            //获取fileType icon
            return fileType?.roundColorfulImageKey ?? .wikiOtherfileCircleColorful
        case .wiki:
            return .wikibookCircleColorful
        case .sync:
            return .syncedblockColorful
        default:
            return .fileRoundUnknowColorful
        }
    }
}

//---------------MARK: 获取彩色方形默认图标 ---------------------
extension DocsIconInfo {
    
    //获取彩色的方形图标
    fileprivate func getSquareColorfulDefultIcon(isShortCut: Bool) -> UIImage  {
        let image = squareColorfulIconImage
        //fg使用，后续会比较快的去掉该fg，就没有用户态的问题
        let featureGating = try? Container.shared.getCurrentUserResolver().resolve(type: DocsIconFeatureGating.self)
        //反向fg
        if !(featureGating?.larkIconDisable ?? true) {
            let shortCutImage: UIImage? = isShortCut ? UDIcon.wikiShortcutarrowColorful : nil
            return LarkIconBuilder.createImageWith(originImage: image,
                                                   foreground: IconForeground(foregroundImage: shortCutImage)) ?? image
        }
        return DocsIconCreateUtil.creatImage(image: image, isShortCut: isShortCut)
    }
    
    var squareColorfulIconImage: UIImage {
        let image: UIImage
        switch objType {
        case .bitable, .baseAdd:
            let featureGating = try? Container.shared.getCurrentUserResolver().resolve(type: DocsIconFeatureGating.self)
            if featureGating?.btSquareIcon ?? false {
                image = LarkDocsIconForBase.Base.base_default_icon
            } else {
                image = UDIcon.getIconByKeyNoLimitSize(squareColorfulIconKey)
            }
        default:
            image = UDIcon.getIconByKeyNoLimitSize(squareColorfulIconKey)
        }
        return image
    }
    
    //MARK: WIKI 图标相关
    //彩色的方形图标
    private var squareColorfulIconKey: UDIconType {
        switch objType {
        case .doc:
            return .fileDocColorful
        case .docX:
            return .fileDocxColorful
        case .sheet:
            return .fileSheetColorful
        case .mindnote:
            return .fileMindnoteColorful
        case .slides:
            return .wikiSlidesColorful
        case .bitable:
            return .fileBitableColorful
        case .file:
            return fileType?.squareColorfulImageKey
            ?? .wikiOtherfileColorful
        case .wiki:
            return .wikiColorful
        case .folder:
            return .fileFolderColorful
        case .sync:
            return .syncedblockColorful
        default:
            return .fileUnknowColorful
        }
    }
}

//---------------MARK: 获取线框方形默认图标 ---------------------
extension DocsIconInfo {
    
    //获取线框的方形图标
    fileprivate func getSquareOutlinedDefultIcon(isShortCut: Bool) -> UIImage  {
        if isShortCut {
            return UDIcon.getIconByKeyNoLimitSize(self.shortcutOutlinedIconKey)
        } else {
            return UDIcon.getIconByKeyNoLimitSize(self.outlinedIconKey)
        }
    }
    
    var outlinedIconKey: UDIconType {
        switch objType {
        case .doc:
            return .fileLinkWordOutlined
        case .docX:
            return .fileLinkWordOutlined
        case .sheet:
            return .fileLinkSheetOutlined
        case .mindnote:
            return .fileLinkMindnoteOutlined
        case .slides:
            return .fileLinkSlidesOutlined
        case .bitable:
            return .fileLinkBitableOutlined
        case .file:
            return fileType?.outlinedImageKey
            ?? .fileLinkOtherfileOutlined
        case .wiki:
            return .wikiBookOutlined
        case .folder:
            return .folderOutlined
        case .whiteboard:
            return .vcWhiteboardOutlined
        case .sync:
            return .linkRecordOutlined
        default:
            return .fileLinkUnknowOutlined
        }
    }
    
    var shortcutOutlinedIconKey: UDIconType {
        switch objType {
        case .doc:
            return .wikiDocShortcutOutlined
        case .docX:
            return .fileLinkDocxShortcutOutlined
        case .sheet:
            return .wikiSheetShortcutOutlined
        case .mindnote:
            return .wikiMindnoteShortcutOutlined
        case .slides:
            return .fileLinkSlidesShortcutOutlined
        case .bitable:
            return .filelinkBitableShortcutOutlined
        case .file:
            return fileType?.shortcutOutlinedImageKey
            ?? .fileLinkOtherfileShortcutOutlined
        case .wiki:
            return .fileLinkWikiShortcutOutlined
        case .folder:
            return .folderOutlined
        default:
            return .fileLinkOtherfileShortcutOutlined
        }
    }
}


//---------------MARK: 解析失败兜底unknow默认图标 ---------------------
extension DocsIconInfo {
    static func defultUnknowIcon(docsType: CCMDocsType = .unknownDefaultType,
                                 shape: IconShpe,
                                 container: ContainerInfo?) -> UIImage {
        let iconInfo = DocsIconInfo(type: .none, objType: docsType)
        return iconInfo.getDefultIcon(shape: shape, container: container)
    }
    
    static func defultUnknowIconObserve(docsType: CCMDocsType = .unknownDefaultType,
                                        shape: IconShpe,
                                        container: ContainerInfo?) -> Observable<UIImage> {
        //默认图
        let downloadPlaceHolder: Observable<UIImage> = .from(optional: DocsIconInfo.defultUnknowIcon(docsType: docsType, shape: shape, container: container))
        return downloadPlaceHolder
    }
}
