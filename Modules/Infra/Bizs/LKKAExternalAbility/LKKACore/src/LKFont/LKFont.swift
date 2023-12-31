import UIKit
import Foundation
protocol LKKAFontProtocol {
    var title: UIFont { get }
    var heading1: UIFont { get }
    var heading2: UIFont { get }
    var heading3: UIFont { get }
    var subheading: UIFont { get }
    var body1: UIFont { get }
    var body2: UIFont { get }
    var body3: UIFont { get }
    var caption1: UIFont { get }
    var caption2: UIFont { get }
    var caption3: UIFont { get }
}
@objcMembers
public class LKFont: NSObject {
    public static let fontDidChange: String = "LKKAFontDidChange"
    static var delegate: LKKAFontProtocol?
    public static var title: UIFont {
        delegate?.title ?? preferredFont(.largeTitle)
    }

    public static var heading1: UIFont {
        delegate?.heading1 ?? preferredFont(.title1)
    }

    public static var heading2: UIFont {
        delegate?.heading2 ?? preferredFont(.title2)
    }

    public static var heading3: UIFont {
        delegate?.heading3 ?? preferredFont(.title3)
    }

    public static var subheading: UIFont {
        delegate?.subheading ?? preferredFont(.headline)
    }

    public static var body1: UIFont {
        delegate?.body1 ?? preferredFont(.body)
    }

    public static var body2: UIFont {
        delegate?.body2 ?? preferredFont(.body)
    }

    public static var body3: UIFont {
        delegate?.body3 ?? preferredFont(.body)
    }

    public static var caption1: UIFont {
        delegate?.caption1 ?? preferredFont(.caption1)
    }

    public static var caption2: UIFont {
        delegate?.caption2 ?? preferredFont(.caption2)
    }

    public static var caption3: UIFont {
        delegate?.caption3 ?? preferredFont(.caption2)
    }

    static func preferredFont(_ style: UIFont.TextStyle) -> UIFont {
        UIFont.preferredFont(forTextStyle: style)
    }
}
