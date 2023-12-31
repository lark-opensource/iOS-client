//
//  Utils+Random.swift
//  LarkFoundation
//
//  Created by Saafo on 2023/5/25.
//

import Foundation

// MARK: Random string
extension Utils {
    private static let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private static let numbers = "0123456789"
    private static let lettersAndNumbers = letters + numbers

    /// Generate a random string from lowercase and uppercase letters and numbers
    public static func randomID(length: Int = 10) -> String {
        String((0 ..< length).map { _ in (lettersAndNumbers.randomElement() ?? "a") })
    }

    /// Generate a random string from numbers
    public static func randomNumbers(length: Int = 10) -> String {
        String((0 ..< length).map { _ in (numbers.randomElement() ?? "0") })
    }

    /// Generate a random string from lowercase and uppercase letters
    public static func randomLetters(length: Int = 10) -> String {
        String((0 ..< length).map { _ in (letters.randomElement() ?? "a") })
    }
}
