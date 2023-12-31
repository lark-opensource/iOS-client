//
//  XML.swift
//  LarkSearchCore
//
//  Created by SolaWing on 2020/12/21.
//

import Foundation

public enum XML {
    /// escape &, <, > in original text
    static func encode(text: String) -> String {
        var buffer = String()
        for i in text {
            switch i {
            case "&": buffer.append("&amp;")
            case "<": buffer.append("&lt;")
            case ">": buffer.append("&gt;")
            default: buffer.append(i)
            }
        }
        return buffer
    }

    public enum Node: CustomDebugStringConvertible {
        case text(String)
        case element(Element)

        public var debugDescription: String {
            switch self {
            case .text(let s): return s
            case .element(let e): return e.debugDescription
            }
        }
    }

    final public class Element: CustomDebugStringConvertible {
        var name: String
        public var items: [Node] = []
        var attributes: [String: String]

        public init(name: String, attributes: [String: String] = [:]) {
            self.name = name
            self.attributes = attributes
        }
        public var innerXML: String {
            var buffer = ""
            func append(element: Element) {
                for i in element.items {
                    switch i {
                    case .text(let v): buffer.append(XML.encode(text: v))
                    case .element(let v):
                        buffer.append("<")
                        buffer.append(v.name)
                        for _ in attributes {
                            assertionFailure("unimplemented")
                        }
                        buffer.append(">")

                        append(element: v)

                        buffer.append("<")
                        buffer.append("/")
                        buffer.append(v.name)
                        buffer.append(">")
                    }
                }
            }
            append(element: self)
            return buffer
        }

        /// the innerText ignore all tags, only content
        var innerText: String {
            var buffer = ""
            func append(element: Element) {
                for i in element.items {
                    switch i {
                    case .text(let v): buffer.append(v)
                    case .element(let v): append(element: v)
                    }
                }
            }
            append(element: self)
            return buffer
        }

        public var debugDescription: String {
            "<\(name) \(attributes)>\(items)</\(name)>"
        }
    }

    final class Document {
        var root: Element
        init(root: Element) {
            self.root = root
        }
        init(data: Data) throws {
            root = try Builder(data: data).build()
        }
        private final class Builder: NSObject, XMLParserDelegate {
            let parser: XMLParser
            var root: Element?
            var stack = [Element]()
            init(data: Data) {
                parser = XMLParser(data: data)
                super.init()
                parser.delegate = self
            }
            func build() throws -> Element {
                struct Unknown: Error {}
                if !parser.parse() {
                    throw parser.parserError ?? Unknown()
                }
                if let root = self.root {
                    return root
                }
                throw Unknown()
            }
            func log(function: String = #function, _ msg: @autoclosure () -> String) {
                // print(function, msg())
            }
            func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
                log("\(elementName), \(namespaceURI ?? ""), \(qName ?? ""), \(attributeDict)")
                stack.append(Element(name: elementName, attributes: attributeDict))
            }
            func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
                log("\(elementName), \(namespaceURI ?? ""), \(qName ?? "")")
                if let new = stack.popLast() {
                    assert(new.name == elementName) // should pair as stack
                    if let cur = stack.last {
                        cur.items.append(.element(new))
                    } else { // root
                        root = new
                    }
                }
            }

            /// 可能连续调用多次
            func parser(_ parser: XMLParser, foundCharacters string: String) {
                log(string)
                stack.last?.items.append(.text(string))
            }

            #if DEBUG
            /// custom &xxx;
            func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?) -> Data? {
                log("\(name), \(systemID)")
                return nil
            }
            func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
                log("\(parseError)")
            }
            func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
                log("\(validationError)")
            }
            #endif
        }
    }
}
