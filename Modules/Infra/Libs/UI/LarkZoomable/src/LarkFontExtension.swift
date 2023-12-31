//
//  LarkFontExtension.swift
//  EEAtomic
//
//  Created by Hayden on 2020/11/20.
//

import UIKit
import Foundation
import UniverseDesignFont

/// Lark font with specified transformer.
public extension UIFont {

    /// Return a **TITLE** font instance at specific zooming system.
    @available(*, deprecated, renamed: "UIFont.ud.title0()")
    static func title(_ transformer: Zoom.Transformer) -> UIFont {
        return UIFont.ud.title0(transformer)
    }

    /// Return a **HEADING1** font instance at specific zooming system.
    @available(*, deprecated, renamed: "UIFont.ud.title1()")
    static func heading1(_ transformer: Zoom.Transformer) -> UIFont {
        return UIFont.ud.title1(transformer)
    }

    /// Return a **HEADING2** font instance at specific zooming system.
    @available(*, deprecated, renamed: "UIFont.ud.title2()")
    static func heading2(_ transformer: Zoom.Transformer) -> UIFont {
        return UIFont.ud.title2(transformer)
    }

    /// Return a **HEADING3** font instance at specific zooming system.
    @available(*, deprecated, renamed: "UIFont.ud.title3()")
    static func heading3(_ transformer: Zoom.Transformer) -> UIFont {
        return UIFont.ud.title3(transformer)
    }

    /// Return a **SUBHEADING** font instance at specific zooming system.
    @available(*, deprecated, renamed: "UIFont.ud.title4()")
    static func subheading(_ transformer: Zoom.Transformer) -> UIFont {
        return UIFont.ud.title4(transformer)
    }

    /// Return a **BODY0** font instance at specific zooming system.
    @available(*, deprecated, renamed: "UIFont.ud.headline()")
    static func body0(_ transformer: Zoom.Transformer) -> UIFont {
        return UIFont.ud.headline(transformer)
    }

    /// Return a **BODY1** font instance at specific zooming system.
    @available(*, deprecated, renamed: "UIFont.ud.body0()")
    static func body1(_ transformer: Zoom.Transformer) -> UIFont {
        return UIFont.ud.body0(transformer)
    }

    /// Return a **BODY2** font instance at specific zooming system.
    @available(*, deprecated, renamed: "UIFont.ud.body1()")
    static func body2(_ transformer: Zoom.Transformer) -> UIFont {
        return UIFont.ud.body1(transformer)
    }

    /// Return a **BODY3** font instance at specific zooming system.
    @available(*, deprecated, renamed: "UIFont.ud.body2()")
    static func body3(_ transformer: Zoom.Transformer) -> UIFont {
        return UIFont.ud.body2(transformer)
    }

    /// Return a **CAPTION1** font instance at specific zooming system.
    @available(*, deprecated, renamed: "UIFont.ud.caption0()")
    static func caption1(_ transformer: Zoom.Transformer) -> UIFont {
        return UIFont.ud.caption0(transformer)
    }

    /// Return a **CAPTION2** font instance at specific zooming system.
    @available(*, deprecated, renamed: "UIFont.ud.caption1()")
    static func caption2(_ transformer: Zoom.Transformer) -> UIFont {
        return UIFont.ud.caption1(transformer)
    }

    /// Return a **CAPTION3** font instance at specific zooming system.
    @available(*, deprecated, renamed: "UIFont.ud.caption2()")
    static func caption3(_ transformer: Zoom.Transformer) -> UIFont {
        return UIFont.ud.caption2(transformer)
    }

    /// Return a **CAPTION4** font instance at specific zooming system.
    @available(*, deprecated, renamed: "UIFont.ud.caption3()")
    static func caption4(_ transformer: Zoom.Transformer) -> UIFont {
        return UIFont.ud.caption3(transformer)
    }
}

public extension UIFont {

    /// *26pt*, *semibold* at normal level.
    @available(*, deprecated, renamed: "UIFont.ud.title0")
    static var title: UIFont { return UIFont.ud.title0 }

    /// *24pt*, *semibold* at normal level.
    @available(*, deprecated, renamed: "UIFont.ud.title1")
    static var heading1: UIFont { return UIFont.ud.title1 }

    /// *20pt*, *medium* at normal level.
    @available(*, deprecated, renamed: "UIFont.ud.title2")
    static var heading2: UIFont { return UIFont.ud.title2 }

    /// *17pt*, *medium* at normal level.
    @available(*, deprecated, renamed: "UIFont.ud.title3")
    static var heading3: UIFont { return UIFont.ud.title3 }

    /// *17pt*, *regular* at normal level.
    @available(*, deprecated, renamed: "UIFont.ud.title4")
    static var subheading: UIFont { return UIFont.ud.title4 }

    /// *16pt*, *medium* at normal level.
    @available(*, deprecated, renamed: "UIFont.ud.headline")
    static var body0: UIFont { return UIFont.ud.headline }

    /// *16pt*, *regular* at normal level.
    @available(*, deprecated, renamed: "UIFont.ud.body0")
    static var body1: UIFont { return UIFont.ud.body0 }

    /// *14pt*, *medium* at normal level.
    @available(*, deprecated, renamed: "UIFont.ud.body1")
    static var body2: UIFont { return UIFont.ud.body1 }

    /// *14pt*, *regular* at normal level.
    @available(*, deprecated, renamed: "UIFont.ud.body2")
    static var body3: UIFont { return UIFont.ud.body2 }

    /// *12pt*, *medium* at normal level.
    @available(*, deprecated, renamed: "UIFont.ud.caption0")
    static var caption1: UIFont { return UIFont.ud.caption0 }

    /// *12pt*, *regular* at normal level.
    @available(*, deprecated, renamed: "UIFont.ud.caption1")
    static var caption2: UIFont { return UIFont.ud.caption1 }

    /// *10pt*, *medium* at normal level.
    @available(*, deprecated, renamed: "UIFont.ud.caption2")
    static var caption3: UIFont { return UIFont.ud.caption2 }

    /// *10pt*, *regular* at normal level.
    @available(*, deprecated, renamed: "UIFont.ud.caption3")
    static var caption4: UIFont { return UIFont.ud.caption3 }
}
