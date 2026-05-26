//
//  FormViewModel.swift
//  FormForge
//
//  Created by Vikram Kunwar on 26/05/26.
//

import Foundation
import SwiftUI
import Combine  

@MainActor
class FormViewModel: ObservableObject {

    // MARK: - Typed Field State

    enum FieldState: Equatable {
        case text(String)
        case multiSelect([String])
        case toggle(Bool)
        case checkbox(Bool)
    }

    // MARK: - Published Properties

    @Published var formTitle: String = ""
    @Published var theme: Theme?
    @Published var fields: [AnyFormField] = []
    @Published var fieldValues: [String: FieldState] = [:]
    @Published var validationErrors: [String: String] = [:]
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var submittedData: [String: String]?
    @Published var showSubmissionAlert = false

    // MARK: - Private

    private let dataService = FormDataService()

    // MARK: - Load

    func loadForm() {
        isLoading = true
        errorMessage = nil
        validationErrors = [:]

        do {
            // FIX: filename must match your actual JSON file name in the bundle
            let payload = try dataService.loadFormPayload(filename: "form")
            formTitle = payload.formTitle
            theme     = payload.theme
            fields    = payload.fields.sorted { $0.order < $1.order }

            for field in fields {
                switch field {
                case .text:
                    fieldValues[field.id] = .text("")
                case .dropdown(let data):
                    // Pre-populate default values
                    fieldValues[field.id] = .multiSelect(data.defaultValues)
                case .toggle:
                    fieldValues[field.id] = .toggle(false)
                case .checkbox:
                    fieldValues[field.id] = .checkbox(false)
                case .unknown:
                    break
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Binding Factories

    func textBinding(for fieldId: String) -> Binding<String> {
        Binding(
            get: {
                if case .text(let value) = self.fieldValues[fieldId] { return value }
                return ""
            },
            set: {
                self.fieldValues[fieldId] = .text($0)
                self.validationErrors.removeValue(forKey: fieldId)
            }
        )
    }

    func multiSelectBinding(for fieldId: String) -> Binding<[String]> {
        Binding(
            get: {
                if case .multiSelect(let values) = self.fieldValues[fieldId] { return values }
                return []
            },
            set: {
                self.fieldValues[fieldId] = .multiSelect($0)
                self.validationErrors.removeValue(forKey: fieldId)
            }
        )
    }

    func toggleBinding(for fieldId: String) -> Binding<Bool> {
        Binding(
            get: {
                if case .toggle(let value) = self.fieldValues[fieldId] { return value }
                return false
            },
            set: {
                self.fieldValues[fieldId] = .toggle($0)
                self.validationErrors.removeValue(forKey: fieldId)
            }
        )
    }

    func checkboxBinding(for fieldId: String) -> Binding<Bool> {
        Binding(
            get: {
                if case .checkbox(let value) = self.fieldValues[fieldId] { return value }
                return false
            },
            set: {
                self.fieldValues[fieldId] = .checkbox($0)
                self.validationErrors.removeValue(forKey: fieldId)
            }
        )
    }

    // MARK: - Submission

    func submitForm() {
        validationErrors = [:]

        // Validation: Required fields
        for field in fields {
            guard field.isRequired else { continue }

            let isEmpty: Bool
            switch fieldValues[field.id] {
            case .text(let value):
                isEmpty = value.trimmingCharacters(in: .whitespaces).isEmpty
            case .multiSelect(let values):
                isEmpty = values.isEmpty
            case .toggle(let value):
                isEmpty = !value
            case .checkbox(let value):
                // FIX: cannot pattern-match two associated values in one case when types differ
                // at the compiler level — split into separate cases to satisfy exhaustiveness
                isEmpty = !value
            case .none:
                isEmpty = true
            }

            if isEmpty {
                validationErrors[field.id] = field.errorMessage ?? "This field is required"
            }
        }

        // Validation: maxLength for text fields
        for field in fields {
            if case .text(let data) = field, let maxLength = data.maxLength {
                if case .text(let value) = fieldValues[field.id], value.count > maxLength {
                    validationErrors[field.id] = "Must be \(maxLength) characters or less."
                }
            }
        }

        // Validation: numeric format for NUMBER subtype
        for field in fields {
            if case .text(let data) = field, data.subtype == "NUMBER" {
                if case .text(let value) = fieldValues[field.id] {
                    let trimmed = value.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty && Double(trimmed) == nil {
                        validationErrors[field.id] = "Please enter a valid number."
                    }
                }
            }
        }

        guard validationErrors.isEmpty else { return }

        isSubmitting = true

        var submittedPairs: [String: String] = [:]
        for (fieldId, state) in fieldValues {
            switch state {
            case .text(let value):
                submittedPairs[fieldId] = value
            case .multiSelect(let values):
                // FIX: joined(separator:) returns a String directly — no type mismatch
                submittedPairs[fieldId] = values.joined(separator: ", ")
            case .toggle(let value):
                submittedPairs[fieldId] = String(value)
            case .checkbox(let value):
                submittedPairs[fieldId] = String(value)
            }
        }

        print("=== Form Submitted ===")
        for (key, value) in submittedPairs.sorted(by: { $0.key < $1.key }) {
            print("\(key): \(value)")
        }
        print("=====================")

        submittedData        = submittedPairs
        showSubmissionAlert  = true
        isSubmitting         = false
    }
}
