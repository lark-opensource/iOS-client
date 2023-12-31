//
//  TypingLabel.swift
//  LarkAI
//
//  Created by Hayden on 2023/5/27.
//

import UIKit

/// Set `text` at runtime to trigger type animation;
/// Set `charInterval` property for interval time between each character, default is 0.1;
/// Call `pauseTyping()` to pause animation;
/// Call `continueTyping()` to restart a paused animation;
open class TypingLabel: UILabel {

    /// Set interval time between each characters
    open var charInterval: Double = 0.1

    open var totalTime: Double?

    /// Optional handler which fires when typing animation is finished
    open var onTypingAnimationFinished: (() -> Void)?

    /// If text is always centered during typing
    open var centerText: Bool = true

    public var wordSeparator: (String) -> [String] = { str in
        let chars = Array(str).map { String($0) }
        return chars
    }

    private var typingStopped: Bool = false
    private var typingOver: Bool = true
    private var stoppedSubstring: String?
    private var attributes: [NSAttributedString.Key: Any]?
    private var currentDispatchID: Int = 320
    private let dispatchSerialQ = DispatchQueue(label: "CLTypingLableQueue")

    /// Setting the text will trigger animation automatically
    override open var text: String! {
        get {
            return super.text
        }
        set {
            let separatedWords = wordSeparator(newValue)
            if let totalTime = totalTime, !separatedWords.isEmpty {
                charInterval = abs(totalTime) / Double(separatedWords.count)
                print(charInterval)
            } else {
                charInterval = abs(charInterval)
            }

            currentDispatchID += 1
            typingStopped = false
            typingOver = false
            stoppedSubstring = nil

            attributes = nil
            setTextWithTypingAnimation(separatedWords, attributes, charInterval, true, currentDispatchID)
        }
    }

    /// Setting attributed text will trigger animation automatically
    override open var attributedText: NSAttributedString! {
        get {
            return super.attributedText
        }
        set {
            let separatedWords = wordSeparator(newValue.string)
            if let totalTime = totalTime, !separatedWords.isEmpty {
                charInterval = abs(totalTime) / Double(separatedWords.count)
            } else {
                charInterval = abs(charInterval)
            }

            currentDispatchID += 1
            typingStopped = false
            typingOver = false
            stoppedSubstring = nil

            attributes = newValue.attributes(at: 0, effectiveRange: nil)
            setTextWithTypingAnimation(separatedWords, attributes, charInterval, true, currentDispatchID)
        }
    }

    // MARK: Stop Typing Animation

    open func pauseTyping() {
        if typingOver == false {
            typingStopped = true
        }
    }

    // MARK: Continue Typing Animation

    open func continueTyping() {

        guard typingOver == false else {
            print("CLTypingLabel: Animation is already over")
            return
        }

        guard typingStopped == true else {
            print("CLTypingLabel: Animation is not stopped")
            return
        }
        guard let stoppedSubstring = stoppedSubstring else {
            return
        }

        typingStopped = false
        setTextWithTypingAnimation(stoppedSubstring, attributes, charInterval, false, currentDispatchID)
    }

    // MARK: Set Text Typing Recursive Loop

    private func setTextWithTypingAnimation(_ typedText: String, _ attributes: [NSAttributedString.Key: Any]?, _ charInterval: TimeInterval, _ initial: Bool, _ dispatchID: Int) {

        guard !typedText.isEmpty && currentDispatchID == dispatchID else {
            typingOver = true
            typingStopped = false
            if let nonNilBlock = onTypingAnimationFinished {
                DispatchQueue.main.async(execute: nonNilBlock)
            }
            return
        }

        guard typingStopped == false else {
            stoppedSubstring = typedText
            return
        }

        if initial == true {
            super.text = ""
        }

        let firstCharIndex = typedText.index(typedText.startIndex, offsetBy: 1)

        DispatchQueue.main.async {
            if let attributes = attributes {
                super.attributedText = NSAttributedString(string: (super.attributedText?.string ?? "") + String(typedText[..<firstCharIndex]),
                                                          attributes: attributes)
            } else {
                super.text = (super.text ?? "") + String(typedText[..<firstCharIndex])
            }

            if self.centerText == true {
                self.sizeToFit()
            }
            self.dispatchSerialQ.asyncAfter(deadline: .now() + charInterval) { [weak self] in
                let nextString = String(typedText[firstCharIndex...])

                self?.setTextWithTypingAnimation(nextString, attributes, charInterval, false, dispatchID)
            }
        }
    }

    private func setTextWithTypingAnimation(_ typedClippedTexts: [String], _ attributes: [NSAttributedString.Key: Any]?, _ charInterval: TimeInterval, _ initial: Bool, _ dispatchID: Int) {

        guard !typedClippedTexts.isEmpty && currentDispatchID == dispatchID else {
            typingOver = true
            typingStopped = false
            if let nonNilBlock = onTypingAnimationFinished {
                DispatchQueue.main.async(execute: nonNilBlock)
            }
            return
        }

        guard typingStopped == false else {
            stoppedSubstring = String(typedClippedTexts.joined())
            return
        }

        if initial == true {
            super.text = ""
        }

        let firstCharIndex = 1

        DispatchQueue.main.async {
            if let attributes = attributes {
                super.attributedText = NSAttributedString(string: (super.attributedText?.string ?? "") + String((typedClippedTexts[..<firstCharIndex]).joined()),
                                                          attributes: attributes)
            } else {
                super.text = (super.text ?? "") + String((typedClippedTexts[..<firstCharIndex]).joined())
            }

            if self.centerText == true {
                self.sizeToFit()
            }
            self.dispatchSerialQ.asyncAfter(deadline: .now() + charInterval) { [weak self] in
                let nextClippedTexts = Array(typedClippedTexts[firstCharIndex...])
                self?.setTextWithTypingAnimation(nextClippedTexts, attributes, charInterval, false, dispatchID)
            }
        }
    }
}

// https://medium.com/@sorenlind/three-ways-to-enumerate-the-words-in-a-string-using-swift-7da5504f0062
extension String {

    func tokenize() -> [String] {
        let inputRange = CFRangeMake(0, self.utf16.count)
        let flag = UInt(kCFStringTokenizerUnitWord)
        let locale = CFLocaleCopyCurrent()
        let tokenizer = CFStringTokenizerCreate( kCFAllocatorDefault, self as CFString, inputRange, flag, locale)
        var tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        var tokens: [String] = []

        while !tokenType.isEmpty {
            let currentTokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            let substring = self.substringWithRange(aRange: currentTokenRange)
            tokens.append(substring)
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }

        return tokens
    }

    func substringWithRange(aRange: CFRange) -> String {
        let nsrange = NSRange(location: aRange.location, length: aRange.length)
        let substring = (self as NSString).substring(with: nsrange)
        return substring
    }
}
