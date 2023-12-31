//
//  GetSchemaFile.swift
//  LarkWorkplaceModel
//
//  Created by Shengxy on 2022/10/27.
//

import Foundation
import SwiftyJSON

/// [ <templateFileURL>] - request parameters
/// request parameters for getting template schema
struct WPGetTemplateSchemaRequestParams: Codable {
    /// lark version number, eg: "5.27.0"
    let larkVersion: String
    /// locale for response data
    let locale: String
}

/// [ <templateFileURL>] - response data
/// template portal schema -> component list
struct WPTemplateSchema: Codable {
    /// schema version: "1.0"
    let schemaVersion: String
    /// template portal schema data
    let schema: SchemaData
}

extension WPTemplateSchema {
    /// template portal schema data
    struct SchemaData: Codable {
        /// root schema identifier: "mobile-root"
        let id: String
        /// root schema name: "Page"
        let componentName: String
        /// template portal properties
        let props: PortalProps?
        /// template portal component list
        let children: [Component]
    }
}

extension WPTemplateSchema.SchemaData {
    /// template portal properties
    struct PortalProps: Codable {
        /// template portal background properties
        let backgroundProps: BackgroundProps?
    }

    /// template portal component
    struct Component: Codable {
        /// component identifier, for index
        let id: String?
        /// component type
        let componentName: ComponentType
        /// component layout
        let styles: Layout?
        /// component type related properties
        /// inner type could be: Navi | Block | Favorite | FeedList | FeedSwiper
        let props: JSON?
        /// component child
        let children: [Component]?
        /// the data source of `FeedList` and `FeedSwiper`
        let dataSource: DataSource?
    }
}

extension WPTemplateSchema.SchemaData.PortalProps {
    /// template portal background properties
    struct BackgroundProps: Codable {
        // compile params, unused
        // let settingProps: JSON?
        /// template portal background image properties
        let background: BackgroundImage
    }

    /// template portal background image properties
    struct BackgroundImage: Codable {
        /// image in light mode
        let light: BackgroundImageProps?
        /// image in dark mode
        let dark: BackgroundImageProps?
    }

    /// template portal background image properties
    struct BackgroundImageProps: Codable {
        /// image url
        let url: String
        /// image key
        let key: String
        /// A strategy for stitching domain names
        /// only used for monitor
        let fsUnit: String
    }
}

extension WPTemplateSchema.SchemaData.Component {
    /// template portal group component layout properties
    /// the following fields are optional and have default values
    struct Layout: Codable {
        /// component width
        let width: String?
        /// component height
        let height: String?
        /// top margin
        let marginTop: Int?
        /// right margin
        let marginRight: Int?
        /// bottom margin
        let marginBottom: Int?
        /// left margin
        let marginLeft: Int?
        /// background radius
        let backgroundRadius: Int?
        /// component background color
        let backgroundColor: String?
        /// component background color ramp: start color
        let backgroundStartColor: String?
        /// component background color ramp: end color
        let backgroundEndColor: String?

        // MARK: following fields only exist in FeedList and FeedSwiper
        
        /// for feedlist: the corner radius of feed list items' icon
        /// for feedswiper: the corner radius of the feed swiper card
        let imageRadius: Int?

        // MARK: following fields only exist in FeedList
        
        /// the font size of the feed list items' title
        let titleFontSize: Int?
        /// the font size of the feed list items' description
        let descFontSize: Int?
        /// the font size of the feed list items' date text
        let dateFontSize: Int?

        // MARK: following fields only exist in FeedSwiper

        /// the font size of the feed swiper card's title
        let feedTitleFontSize: Int?
    }

    /// template portal component type
    enum ComponentType: String, Codable {
        /// template portal navigation bar
        case header = "Header"
        /// single block component
        case block = "Block"
        /// common and recommend component
        case favorite = "CommonAndRecommend"
        /// single empty component (old version of workplace editor)
        @available(*, deprecated, message: "Single not available")
        case single = "Single"
        /// feed swiper component ( image )
        /// compatible with old versions, no new users
        @available(*, deprecated, message: "FeedSwiper not available")
        case feedSwiper = "FeedSwiper"
        /// feed list component ( list )
        /// compatible with old versions, no new users
        @available(*, deprecated, message: "FeedList not available")
        case feedList = "FeedList"
    }

    /// template portal navigation bar component
    struct Navi: Codable {
        /// show title in navigation bar or not
        let showTitle: Bool?
        /// the properties of icons in navigation bar
        let iconItems: [NaviIconProps]?
    }

    /// template portal common and recommend component
    struct Favorite: Codable {
        /// header title
        let title: [String: String]?
        /// header icon url
        let titleIconURL: String?
        /// header link
        let schema: String?
        /// show background or not
        let showBackground: Bool?
        /// set in editor
        /// when user preferred language doesn't exist in supported language list,
        /// using the 'defaultLocale' as the shown language
        let defaultLocale: String?

        enum CodingKeys: String, CodingKey {
            case title = "mTitle"
            case titleIconURL = "titleIconUrl"
            case schema
            case showBackground
            case defaultLocale
        }
    }

    /// template portal block component
    struct Block: Codable {
        /// block instance identifier
        let blockId: String?
        /// application item identifier, for index
        let itemId: String?
        /// show block header or not
        let showHeader: Bool?
        /// block header title
        let title: [String: String]?
        /// block header redirect url
        let schema: String?
        /// block header shown inside block or not
        let isTitleInside: Bool?
        /// block header icon url
        let titleIconURL: String?
        /// block header menu items
        let menuItems: [WPMenuItem]?
        /// block force update
        let forceUpdate: Bool?
        /// pass to blockit, no parsing is required
        let templateConfig: JSON?
        /// set in editor
        /// when user preferred language doesn't exist in supported language list,
        /// using the 'defaultLocale' as the shown language
        let defaultLocale: String?

        enum CodingKeys: String, CodingKey {
            case blockId
            case itemId
            case showHeader
            case title
            case schema
            case isTitleInside
            case titleIconURL = "titleIconUrl"
            case menuItems
            case forceUpdate
            case templateConfig
            case defaultLocale
        }
    }

    /// template portal feedlist component
    /// old version, no longer supported in current workplace editor
    @available(*, deprecated, message: "FeedList not available")
    struct FeedList: Codable {
        /// the title of the feed list card
        let title: [String: String]?
        /// the default language of the title
        /// set in editor
        /// when user preferred language doesn't exist in supported language list,
        /// using the 'defaultLocale' as the shown language
        let defaultLocale: String?
        /// show header or not
        let showHeader: Bool?
        /// title icon resource url
        let titleIconURL: String?
        /// title icon redirect url
        let schema: String?
        /// title shown inside feed list card or not
        let isTitleInside: Bool?
        /// show background color or not
        let showBackground: Bool?
        /// different tab font size and icon image size
        let tabSize: TabSize?
        /// show feed list items' icon or not
        let showImage: Bool?
        /// the width of the feed list items' icon
        let imageWidth: Int?
        /// the height of the feed list items' icon
        let imageHeight: Int?
        /// the maximum number of lines for the title
        let titleMaxline: Int?
        /// the maximum number of lines for the description
        let descMaxline: Int?
        /// the maximun number of lines for the date text
        let dateMaxline: Int?
        /// the maximum number of feed list items to display
        let maxListLength: Int?
        /// feed list header menu items
        let menuItems: [WPMenuItem]?

        enum CodingKeys: String, CodingKey {
            case title
            case defaultLocale
            case showHeader
            case titleIconURL = "titleIconUrl"
            case schema
            case isTitleInside
            case showBackground
            case tabSize
            case showImage
            case imageWidth
            case imageHeight
            case titleMaxline
            case descMaxline
            case dateMaxline
            case maxListLength
            case menuItems
        }
    }

    /// template portal feedswiper component
    /// old version, no longer supported in current workplace editor
    @available(*, deprecated, message: "FeedSwiper not available")
    struct FeedSwiper: Codable {
        /// the title of the feed swiper card
        let title: [String: String]?
        /// the default language of the title
        /// set in editor
        /// when user preferred language doesn't exist in supported language list,
        /// using the 'defaultLocale' as the shown language
        let defaultLocale: String?
        /// show header or not
        let showHeader: Bool?
        /// title icon resource url
        let titleIconURL: String?
        /// title icon redirect url
        let schema: String?
        /// title shown inside feed swiper card or not
        let isTitleInside: Bool?
        /// show background color or not
        let showBackground: Bool?
        /// feed swiper card height = (image height) + (height of the text area)
        let imageHeight: Int?
        /// automatic swiper interval
        let interval: Int?
        /// feed swiper header menu items
        let menuItems: [WPMenuItem]?

        enum CodingKeys: String, CodingKey {
            case title
            case defaultLocale
            case showHeader
            case titleIconURL = "titleIconUrl"
            case schema
            case isTitleInside
            case showBackground
            case imageHeight
            case interval
            case menuItems
        }
    }

    /// the data source of  `FeedList` and `FeedSwiper`
    @available(*, deprecated, message: "Native compoent（FeedList & FeedSwiper）not available")
    struct DataSource: Codable {
        /// the resource url
        let url: String?
        /// request params
        let params: JSON?
        /// request with authorization or not
        let withAuth: Bool?
    }
}

extension WPTemplateSchema.SchemaData.Component.Navi {
    /// the properties of the icon in navigation bar
    struct NaviIconProps: Codable {
        /// navigation icon key
        let key: String
        /// navigation icon url
        let iconURL: String?
        /// navigation icon schema
        let schema: String?

        enum CodingKeys: String, CodingKey {
            case key
            case iconURL = "iconUrl"
            case schema
        }
    }
}

extension WPTemplateSchema.SchemaData.Component.FeedList {
    /// the tab size of the feed list
    enum TabSize: String, Codable {
        /// tab font size: 16; icon size: 22
        case large = "Large"
        /// tab font size: 14; icon size: 20
        case medium = "Midium"
    }
}

/// menu item (used in Block & FeedList & FeedSwiper component)
struct WPMenuItem: Codable {
    /// menu item name
    let name: [String: String]
    /// menu item key
    let key: String?
    /// menu item icon url
    let iconURL: String
    /// menu item redirect url
    let schema: String?

    enum CodingKeys: String, CodingKey {
        case name
        case key
        case iconURL = "iconUrl"
        case schema
    }
}
