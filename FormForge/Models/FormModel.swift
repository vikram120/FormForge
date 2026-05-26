//
//  FormModel.swift
//  FormForge
//
//  Created by Vikram Kunwar on 26/05/26.
//

import Foundation
import SwiftUI

// MARK: - Root Payload

struct FormPayload: Decodable {
    let theme: Theme
    let formTitle: String
    let fields: [AnyFormField]

    enum CodingKeys: String, CodingKey {
        case theme
        case formTitle = "form_title"
        case fields
    }

    var sortedFields: [AnyFormField] {
        fields.sorted { $0.order < $1.order }
    }
}

// MARK: - Theme

struct Theme: Decodable {
    let backgroundColor: Color
    let textColor: Color
    let borderColor: Color
    let errorColor: Color

    enum CodingKeys: String, CodingKey {
        case backgroundColor = "background_color"
        case textColor       = "text_color"
        case borderColor     = "border_color"
        case errorColor      = "error_color"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // FIX: wrap try? in parentheses before applying ?? so the optional is resolved correctly
        backgroundColor = Color(hex: (try? container.decode(String.self, forKey: .backgroundColor))) ?? .white
        textColor       = Color(hex: (try? container.decode(String.self, forKey: .textColor)))       ?? .black
        borderColor     = Color(hex: (try? container.decode(String.self, forKey: .borderColor)))     ?? .gray
        errorColor      = Color(hex: (try? container.decode(String.self, forKey: .errorColor)))      ?? .red
    }
}

// MARK: - Polymorphic Field

indirect enum AnyFormField: Decodable, Identifiable {
    case text(TextFieldData)
    case dropdown(DropdownFieldData)
    case toggle(ToggleFieldData)
    case checkbox(CheckboxFieldData)
    case unknown(id: String)

    var id: String {
        switch self {
        case .text(let d):       return d.id
        case .dropdown(let d):   return d.id
        case .toggle(let d):     return d.id
        case .checkbox(let d):   return d.id
        case .unknown(let id):   return id
        }
    }

    var order: Int {
        switch self {
        case .text(let d):       return d.order
        case .dropdown(let d):   return d.order
        case .toggle(let d):     return d.order
        case .checkbox(let d):   return d.order
        case .unknown:           return Int.max
        }
    }

    var label: String {
        switch self {
        case .text(let d):       return d.label
        case .dropdown(let d):   return d.label
        case .toggle(let d):     return d.label
        case .checkbox(let d):   return d.label
        case .unknown:           return "Unknown Field"
        }
    }

    var isRequired: Bool {
        switch self {
        case .text(let d):       return d.required
        case .dropdown(let d):   return d.required
        case .toggle(let d):     return d.required
        case .checkbox(let d):   return d.required
        case .unknown:           return false
        }
    }

    var errorMessage: String? {
        switch self {
        case .text(let d):       return d.errorMessage
        case .dropdown(let d):   return d.errorMessage
        case .toggle(let d):     return d.errorMessage
        case .checkbox(let d):   return d.errorMessage
        case .unknown:           return nil
        }
    }

    init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: FieldCodingKeys.self)
        let id         = try? container.decode(String.self, forKey: .id)
        let typeString = try? container.decode(String.self, forKey: .type)

        guard let id, let typeString else {
            self = .unknown(id: id ?? "unknown")
            return
        }

        switch typeString {
        case "TEXT":
            self = (try? TextFieldData(from: decoder)).map { .text($0) } ?? .unknown(id: id)
        case "DROPDOWN":
            self = (try? DropdownFieldData(from: decoder)).map { .dropdown($0) } ?? .unknown(id: id)
        case "TOGGLE":
            self = (try? ToggleFieldData(from: decoder)).map { .toggle($0) } ?? .unknown(id: id)
        case "CHECKBOX":
            self = (try? CheckboxFieldData(from: decoder)).map { .checkbox($0) } ?? .unknown(id: id)
        default:
            self = .unknown(id: id)
        }
    }

    enum FieldCodingKeys: String, CodingKey {
        case id, type
    }
}

// MARK: - Field Data Structures

struct TextFieldData: Decodable {
    let id: String
    let order: Int
    let label: String
    let subtype: String
    let placeholder: String?
    let maxLength: Int?
    let supportingText: String?
    let errorMessage: String?
    let required: Bool

    enum CodingKeys: String, CodingKey {
        case id, order, label, subtype, placeholder, required
        case maxLength      = "max_length"
        case supportingText = "supporting_text"
        case errorMessage   = "error_message"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // FIX: parentheses around try? so ?? resolves the Optional, not the expression
        id            = (try? c.decode(String.self, forKey: .id))       ?? ""
        order         = (try? c.decode(Int.self,    forKey: .order))     ?? 0
        label         = (try? c.decode(String.self, forKey: .label))     ?? ""
        subtype       = (try? c.decode(String.self, forKey: .subtype))   ?? "PLAIN"
        placeholder   = try? c.decode(String.self, forKey: .placeholder)
        maxLength     = try? c.decode(Int.self,    forKey: .maxLength)
        supportingText = try? c.decode(String.self, forKey: .supportingText)
        errorMessage  = try? c.decode(String.self, forKey: .errorMessage)
        required      = (try? c.decode(Bool.self,   forKey: .required))  ?? false
    }
}

struct DropdownFieldData: Decodable {
    let id: String
    let order: Int
    let label: String
    let allowMultiple: Bool
    let defaultValues: [String]
    let options: [FormOption]
    let errorMessage: String?
    let required: Bool

    enum CodingKeys: String, CodingKey {
        case id, order, label, options, required
        case allowMultiple = "allow_multiple"
        case defaultValues = "default_values"
        case errorMessage  = "error_message"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = (try? c.decode(String.self,      forKey: .id))           ?? ""
        order         = (try? c.decode(Int.self,         forKey: .order))        ?? 0
        label         = (try? c.decode(String.self,      forKey: .label))        ?? ""
        allowMultiple = (try? c.decode(Bool.self,        forKey: .allowMultiple)) ?? false
        defaultValues = (try? c.decode([String].self,    forKey: .defaultValues)) ?? []
        options       = (try? c.decode([FormOption].self, forKey: .options))     ?? []
        errorMessage  = try? c.decode(String.self, forKey: .errorMessage)
        required      = (try? c.decode(Bool.self,        forKey: .required))     ?? false
    }
}

struct ToggleFieldData: Decodable {
    let id: String
    let order: Int
    let label: String
    let errorMessage: String?
    let required: Bool

    enum CodingKeys: String, CodingKey {
        case id, order, label, required
        case errorMessage = "error_message"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = (try? c.decode(String.self, forKey: .id))    ?? ""
        order        = (try? c.decode(Int.self,    forKey: .order)) ?? 0
        label        = (try? c.decode(String.self, forKey: .label)) ?? ""
        errorMessage = try? c.decode(String.self, forKey: .errorMessage)
        required     = (try? c.decode(Bool.self,   forKey: .required)) ?? false
    }
}

struct CheckboxFieldData: Decodable {
    let id: String
    let order: Int
    let label: String
    let metadata: [String: String]?
    let clickableTextColor: Color?
    let errorMessage: String?
    let required: Bool

    enum CodingKeys: String, CodingKey {
        case id, order, label, metadata, required
        case clickableTextColor = "clickable_text_color"
        case errorMessage       = "error_message"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                 = (try? c.decode(String.self,             forKey: .id))    ?? ""
        order              = (try? c.decode(Int.self,                forKey: .order)) ?? 0
        label              = (try? c.decode(String.self,             forKey: .label)) ?? ""
        metadata           = try? c.decode([String: String].self,    forKey: .metadata)
        errorMessage       = try? c.decode(String.self,              forKey: .errorMessage)
        required           = (try? c.decode(Bool.self,               forKey: .required)) ?? false
        let hex            = try? c.decode(String.self,              forKey: .clickableTextColor)
        clickableTextColor = hex.flatMap { Color(hex: $0) }
    }
}

struct FormOption: Decodable, Identifiable {
    let id: String
    let label: String
}

// MARK: - Color Hex Extension

extension Color {
    /// Supports #RRGGBB and #RRGGBBAA hex strings
    init?(hex: String?) {
        guard let hex else { return nil }

        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") { sanitized = String(sanitized.dropFirst()) }

        guard sanitized.count == 6 || sanitized.count == 8 else { return nil }

        var rgb: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&rgb) else { return nil }

        // FIX: mask must be UInt64 to match the type of rgb — using Int caused a
        // "binary operator '&' cannot be applied to operands of type UInt64 and Int" error
        let mask: UInt64 = 0xFF

        let r, g, b, a: Double
        if sanitized.count == 8 {
            r = Double((rgb >> 24) & mask) / 255
            g = Double((rgb >> 16) & mask) / 255
            b = Double((rgb >> 8)  & mask) / 255
            a = Double( rgb        & mask) / 255
        } else {
            r = Double((rgb >> 16) & mask) / 255
            g = Double((rgb >> 8)  & mask) / 255
            b = Double( rgb        & mask) / 255
            a = 1.0
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
