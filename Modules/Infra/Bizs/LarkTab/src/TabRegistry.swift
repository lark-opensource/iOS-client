//
//  TabRegistry.swift
//  LarkTab
//
//  Created by Supeng on 2020/12/16.
//

import Foundation
import ThreadSafeDataStructure
import LKCommonsLogging

// swiftlint:disable missing_docs
public typealias TabEntryProvider = ([URLQueryItem]?) -> TabRepresentable

/// Tab Register
public enum TabRegistry {

    static let logger = Logger.log(TabRegistry.self, category: "Module.TabBar")

    /// regist tab with provider
    /// - Parameters:
    ///   - tab: Tab
    ///   - provider: () -> TabRepresentable
    public static func register(_ tab: Tab, provider: @escaping TabEntryProvider) {
        tabsProvider[tab] = provider
    }

    /// unregist tab
    /// - Parameters:
    ///   - tab: Tab
    public static func unregister(_ tab: Tab) -> TabRepresentable? {
        return resolvedTabs.removeValue(forKey: tab)
    }

    public static func registerMatcher(_ prefix: String, provider: @escaping TabEntryProvider) {
        tabsPreMatchProvider[prefix] = provider
    }
    // swiftlint:enable missing_docs

    /// get TabRepresentable from registry
    /// - Parameter tab: Tab
    public static func resolve(_ tab: Tab) -> TabRepresentable? {
        if let resolved = resolvedTabs[tab] { return resolved }

        if let provider = self.getProvider(tab) {
            let entry = self.getEntryFromProvider(provider, tab: tab)
            resolvedTabs[tab] = entry
            return entry
        }
        assertionFailure("must call registerTab(_, provider) before resolveTab(_)")
        return nil
    }

    /// All Registed Tabs
    public static var allRegistedTabs: [Tab] {
        return tabsProvider.keys.getImmutableCopy()
    }

    /// whether "Tab" has been registered
    /// - Parameter tab: Tab
    public static func contain(_ tab: Tab) -> Bool {
        return tabsProvider.keys.contains(tab)
            || tabsPreMatchProvider.keys.contains { tab.urlString.hasPrefix($0) }
    }

    /// clear after logout
    public static func clear() {
        resolvedTabs.removeAll()
    }

    /// recycle Tab when memory warning
    /// - Parameter current: The Current Selected Tab
    public static func recyleWhenMemoryWarning(without current: Tab) {
        let resolved = resolvedTabs[current]
        resolvedTabs.removeAll()
        resolvedTabs[current] = resolved
    }

    private static func getProvider(_ tab: Tab) -> TabEntryProvider? {
        // fully match
        if let tabProvider = tabsProvider[tab] {
            return tabProvider
        }
        // pre match
        let matchers = tabsPreMatchProvider.keys.getImmutableCopy()
        let key = matchers.first { tab.urlString.hasPrefix($0) }
        if let key = key, let preMatched = tabsPreMatchProvider[key] {
            return preMatched
        }
        Self.logger.error("cannot find provider, must call registerTab(_, provider) first", additionalData: ["tab": "\(tab)"])
        return nil
    }

    private static func getEntryFromProvider(_ provider: TabEntryProvider, tab: Tab) -> TabRepresentable {
        // let logger = "Resolove Tab: \(tab.urlString)"
        // TODO: 后续TimeLogger下沉
        // let id = TimeLogger.shared.logBegin(eventName: logger)
        let query = URLComponents(url: tab.url, resolvingAgainstBaseURL: false)?.queryItems
        let entry = provider(query)
        // TimeLogger.shared.logEnd(identityObject: id, eventName: logger)
        return entry
    }
}

private var tabsProvider: SafeDictionary<Tab, TabEntryProvider> = [:] + .readWriteLock
private var tabsPreMatchProvider: SafeDictionary<String, TabEntryProvider> = [:] + .readWriteLock
private var resolvedTabs: SafeDictionary<Tab, TabRepresentable> = [:] + .readWriteLock
