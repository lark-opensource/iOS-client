//
// Created by duanxiaochen.7 on 2019/9/9.
// Affiliated with SpaceKit.
//
// Description: Useful extensions of UIButton

import Foundation

public extension UIButton {
    /// Set the same image to different states for a `UIButton` all at once.
    ///
    /// - Parameters:
    ///   - image: The image to set.
    ///   - states: The states to set.
    func setImage(_ image: UIImage?, for states: [UIControl.State]) {
        for state in states {
            self.setImage(image, for: state)
        }
    }

    /// Set the same image with different colors to different states for a `UIButton` all at once.
    ///
    /// - Parameters:
    ///   - image: The image to set.
    ///   - mapping: An array of tuples of type `(UIColor, UIControl.State)` mapping from a `UIColor` to a `UIControl.State`.
    func setImage(_ image: UIImage?, withColorsForStates mapping: [(UIColor, UIControl.State)]) {
        for (color, state) in mapping {
            self.setImage(image?.ud.withTintColor(color), for: state)
        }
    }
}

public extension UIButton {
    /// Set the same background image to different states for a `UIButton` all at once.
    ///
    /// - Parameters:
    ///   - image: The image to set.
    ///   - states: The states to set.
    func setBackgroundImage(_ image: UIImage?, for states: [UIControl.State]) {
        for state in states {
            self.setBackgroundImage(image, for: state)
        }
    }

//    /// Set the same background image with different colors to different states for a `UIButton` all at once.
//    ///
//    /// - Parameters:
//    ///   - image: The image to set.
//    ///   - mapping: An array of tuples of type `(UIColor, UIControl.State)` mapping from a `UIColor` to a `UIControl.State`.
//    func setBackgroundImage(_ image: UIImage?, withColorsForStates mapping: [(UIColor, UIControl.State)]) {
//        for (color, state) in mapping {
//            self.setBackgroundImage(image?.withColor(color), for: state)
//        }
//    }

//    /// Set the same background image with a color for `.normal` state and another color for pressed state for a `UIButton` all at once.
//    ///
//    /// - Parameters:
//    ///   - image: The image to set.
//    ///   - color1: The color for the normal state.
//    ///   - color2: The color for the pressed state.
//    func setBackgroundImage(
//        _ image: UIImage?,
//        colorForNormalState color1: UIColor,
//        colorForPressedState color2: UIColor
//    ) {
//        self.setBackgroundImage(image, withColorsForStates: [
//            (color1, .normal),
//            (color2, .highlighted),
//            (color2, .selected),
//            (color2, UIControl.State.highlighted.union(.selected))
//        ])
//    }

//    /// Set different background images with different color for `.normal` state and for pressed state for a `UIButton` all at once.
//    ///
//    /// - Parameters:
//    ///   - image1: The image for the normal state.
//    ///   - color1: The color for the normal state.
//    ///   - image2: The image for the pressed state.
//    ///   - color2: The color for the pressed state.
//    func setBackgroundImages(
//        _ image1: UIImage?,
//        colorForNormalState color1: UIColor,
//        _ image2: UIImage?,
//        colorForPressedState color2: UIColor
//    ) {
//        self.setBackgroundImage(image1?.withColor(color1), for: .normal)
//        self.setBackgroundImage(image2?.withColor(color2), for: [.highlighted, .selected, UIControl.State.highlighted.union(.selected)])
//    }
}

public extension UIButton {
    /// Set the title with a font, a color to a state for a `UIButton`.
    ///
    /// - Parameters:
    ///   - title: The title to set.
    ///   - fontSize: The font size.
    ///   - fontWeight: The font weight.
    ///   - color: The title color.
    ///   - state: The state to set.
    func setTitle(
        _ title: String?,
        withFontSize fontSize: CGFloat,
        fontWeight: UIFont.Weight,
        color: UIColor,
        forState state: UIControl.State
    ) {
        self.setTitle(title, for: state)
        self.setTitleColor(color, for: state)
        self.titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
    }

    /// Set the title with same color for pressed states for a `UIButton` all at once.
    ///
    /// - Parameters:
    ///   - title: The title to set.
    ///   - fontSize: The font size.
    ///   - fontWeight: The font weight.
    ///   - color: The title color for pressed states.
    func setTitle(
        _ title: String?,
        withFontSize fontSize: CGFloat,
        fontWeight: UIFont.Weight,
        colorForPressedState color: UIColor
    ) {
        self.setTitle(
            title,
            withFontSize: fontSize,
            fontWeight: fontWeight,
            singleColor: color,
            forAllStates: [.highlighted, .selected, UIControl.State.highlighted.union(.selected)]
        )
    }

    /// Set the title with same font, a color for `.normal` state and another color for pressed state for a `UIButton` all at once.
    ///
    /// - Parameters:
    ///   - title: The title to set.
    ///   - fontSize: The font size.
    ///   - fontWeight: The font weight.
    ///   - color1: The color for the normal state.
    ///   - color2: The color for the pressed state.
    func setTitle(
        _ title: String?,
        withFontSize fontSize: CGFloat,
        fontWeight: UIFont.Weight,
        colorForNormalState color1: UIColor,
        colorForPressedState color2: UIColor
    ) {
        self.setTitle(
            title,
            withFontSize: fontSize,
            fontWeight: fontWeight,
            color: color1,
            forState: .normal
        )
        self.setTitle(
            title,
            withFontSize: fontSize,
            fontWeight: fontWeight,
            colorForPressedState: color2
        )
    }

    /// Set the title with same font, same color for all states for a `UIButton` all at once.
    ///
    /// - Parameters:
    ///   - title: The title to set.
    ///   - fontSize: The font size.
    ///   - fontWeight: The font weight.
    ///   - color: The title color.
    ///   - states: The states to set.
    func setTitle(
        _ title: String?,
        withFontSize fontSize: CGFloat,
        fontWeight: UIFont.Weight,
        singleColor color: UIColor,
        forAllStates states: [UIControl.State]
    ) {
        for state in states {
            self.setTitle(title, for: state)
            self.setTitleColor(color, for: state)
        }
        self.titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
    }

    /// Set the same title with different colors to different states for a `UIButton` all at once. The font is the same though.
    ///
    /// - Parameters:
    ///   - title: The title to set.
    ///   - fontSize: The font size.
    ///   - fontWeight: The font weight.
    ///   - mapping: An array of tuples of type `(UIColor, UIControl.State)` mapping from a `UIColor` to a `UIControl.State`.
    func setTitle(
        _ title: String?,
        withFontSize fontSize: CGFloat,
        fontWeight: UIFont.Weight,
        colorsForStates mapping: [(UIColor, UIControl.State)]
    ) {
        for (color, state) in mapping {
            self.setTitle(title, for: state)
            self.setTitleColor(color, for: state)
        }
        self.titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
    }
}
