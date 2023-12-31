//
//  UDAvatarUIConfig.swift
//  UniverseDesignAvatar
//
//  Created by 郭怡然 on 2022/8/19.
//

import UIKit
import Foundation
import UniverseDesignFont

/// Universe Design Avatar UI Config
extension UDAvatar {
    public struct Configuration {

        /// Avatar Style
        public enum Style {
            /// Round corner = min(bounds.width, bounds.height) / 6
            case square
            /// Round corner = min(bounds.width, bounds.height) / 2
            case circle
        }

        public enum Size {

            case mini
            case small
            case middle
            case large
            case extraLarge

            var height: CGFloat {
                switch self{
                case .mini:     return 20
                case .small:    return 24
                case .middle:   return 32
                case .large:    return 40
                case .extraLarge:    return 48
                }
            }

            var width: CGFloat {
                switch self{
                case .mini:     return 20
                case .small:    return 24
                case .middle:   return 32
                case .large:    return 40
                case .extraLarge:    return 48
                }
            }

            var borderWidth: CGFloat {
                switch self{
                case .mini:     return 2
                case .small:    return 2
                case .middle:   return 3
                case .large:    return 3
                case .extraLarge:    return 4
                }
            }


            var font: UIFont {
                switch self{
                case .mini:     return UDFont.caption2
                case .small:    return UDFont.caption2
                case .middle:   return UDFont.caption0
                case .large:    return UDFont.body1
                case .extraLarge:    return UDFont.title3
                }
            }
        }
        public var image: UIImage?

        /// Placeholder when the avatar is empty
        public var placeholder: UIImage?

        /// Avatar Component BackgroundColor
        public var backgroundColor: UIColor?

        /// Avatar Component View CornerRadius
        public var style: Configuration.Style

        /// A flag used to determine how a view lays out its content when its bounds change.
        public var contentMode: UIView.ContentMode

        public var sizeClass: Configuration.Size = .middle

        public var height: CGFloat {
            sizeClass.height
        }

        public var width: CGFloat {
            sizeClass.width
        }

        public var hasExternalBorder: Bool = false

        public var externalBorderWidth: CGFloat {
            sizeClass.borderWidth
        }

        public var font: UIFont {
            sizeClass.font
        }

        /// - Parameters:
        ///   - placeholder: Placeholder when the avatar is empty
        ///   - backgroundColor: AvatarComponent BackgroundColor
        ///   - style: Avatar Component View CornerRadius
        ///   - contentMode: A flag used to determine how a view lays out its content when its bounds change.
        public init(placeholder: UIImage? = nil,
                    backgroundColor: UIColor? = nil,
                    style: Configuration.Style = .circle,
                    contentMode: UIView.ContentMode = .scaleAspectFill,
                    sizeClass: Configuration.Size = .middle,
                    hasBorder: Bool = false
        ) {
            self.placeholder = placeholder
            self.backgroundColor = backgroundColor
            self.style = style
            self.contentMode = contentMode
            self.sizeClass = sizeClass
            self.hasExternalBorder = hasBorder
        }
    }
}
