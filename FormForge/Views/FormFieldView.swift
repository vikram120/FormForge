//
//  FormFieldView.swift
//  FormForge
//
//  Created by Vikram Kunwar on 26/05/26.
//

import SwiftUI

// MARK: - Parent Field Router

struct FormFieldView: View {
    let field: AnyFormField
    @ObservedObject var viewModel: FormViewModel

    var body: some View {
        Group {
            switch field {
            case .text(let data):
                TextFieldView(
                    data: data,
                    value: viewModel.textBinding(for: data.id),
                    hasError: viewModel.validationErrors[data.id] != nil
                )
            case .dropdown(let data):
                DropdownFieldView(
                    data: data,
                    multiValue: viewModel.multiSelectBinding(for: data.id),
                    hasError: viewModel.validationErrors[data.id] != nil
                )
            case .toggle(let data):
                ToggleFieldView(
                    data: data,
                    value: viewModel.toggleBinding(for: data.id)
                )
            case .checkbox(let data):
                CheckboxFieldView(
                    data: data,
                    value: viewModel.checkboxBinding(for: data.id),
                    hasError: viewModel.validationErrors[data.id] != nil
                )
            case .unknown:
                EmptyView()
            }
        }
    }
}

// MARK: - Styled Input Modifier

struct StyledInputModifier: ViewModifier {
    let hasError: Bool

    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        hasError ? Color.red : Color(.systemGray3),
                        lineWidth: hasError ? 2 : 1
                    )
            }
    }
}

extension View {
    func styledInput(hasError: Bool = false) -> some View {
        modifier(StyledInputModifier(hasError: hasError))
    }
}

// MARK: - Field Header

private struct FieldHeader: View {
    let label: String
    let required: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            if required {
                Text("*").foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Text Field View

struct TextFieldView: View {
    let data: TextFieldData
    @Binding var value: String
    var hasError: Bool = false

    var body: some View {
        // FIX: Section { } header: { } only works inside Form/List.
        // Using VStack here since fields are rendered in a plain ScrollView.
        VStack(alignment: .leading, spacing: 6) {
            FieldHeader(label: data.label, required: data.required)

            Group {
                if data.subtype == "MULTILINE" {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $value)
                            .scrollContentBackground(.hidden)
                            .font(.body)

                        if value.isEmpty {
                            Text(data.placeholder ?? "Enter text")
                                .foregroundStyle(.secondary)
                                .font(.body)
                                .padding(16)
                                .allowsHitTesting(false)
                        }
                    }
                    .frame(minHeight: 100)
                    .styledInput(hasError: hasError)
                } else if data.subtype == "SECURE" {
                    SecureField(data.placeholder ?? data.label, text: $value)
                        .textContentType(.password)
                        .styledInput(hasError: hasError)
                } else {
                    TextField(data.placeholder ?? data.label, text: $value)
                        .keyboardType(keyboardType(for: data.subtype))
                        .textContentType(textContentType(for: data.subtype))
                        .onChange(of: value) { oldValue, newValue in
                            if data.subtype == "NUMBER" {
                                value = sanitizeNumericInput(newValue)
                            }
                        }
                        .styledInput(hasError: hasError)
                }
            }

            if let maxLength = data.maxLength {
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Spacer()
                        Text("\(value.count)/\(maxLength)")
                            .font(.caption)
                            .foregroundStyle(value.count > maxLength ? .red : .secondary)
                    }
                    
                    // Inline error for maxLength violation
                    if value.count > maxLength {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                            Text("Must be \(maxLength) characters or less.")
                                .font(.caption)
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if hasError, let message = data.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(message)
                        .font(.caption)
                }
                .foregroundStyle(.red)
            }
        }
    }

    private func keyboardType(for subtype: String) -> UIKeyboardType {
        switch subtype {
        case "NUMBER": return .decimalPad
        case "URI":    return .URL
        default:       return .default
        }
    }

    private func textContentType(for subtype: String) -> UITextContentType? {
        switch subtype {
        case "URI": return .URL
        default:    return nil
        }
    }
}

// MARK: - Numeric Input Sanitizer

private func sanitizeNumericInput(_ input: String) -> String {
    var result = ""
    var hasDecimal = false
    
    for char in input {
        if char.isNumber {
            result.append(char)
        } else if char == "." && !hasDecimal {
            result.append(char)
            hasDecimal = true
        }
    }
    
    return result
}

// MARK: - Dropdown Field View

struct DropdownFieldView: View {
    let data: DropdownFieldData
    @Binding var multiValue: [String]
    var hasError: Bool = false

    @State private var isExpanded = false

    var body: some View {
        // FIX: Section replaced with VStack
        VStack(alignment: .leading, spacing: 6) {
            FieldHeader(label: data.label, required: data.required)

            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(selectedLabel)
                            .font(.body)
                            .foregroundStyle(multiValue.isEmpty ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(isExpanded ? 0 : 8)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(hasError ? Color.red : Color(.systemGray3),
                                    lineWidth: hasError ? 2 : 1)
                    }
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: 0) {
                        Divider()
                        ForEach(data.options, id: \.id) { option in
                            OptionRow(
                                option: option,
                                isSelected: multiValue.contains(option.id),
                                isMulti: data.allowMultiple,
                                onTap: { selectOption(option.id) }
                            )
                            if option.id != data.options.last?.id {
                                Divider().padding(.leading, 44)
                            }
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            if hasError, let message = data.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var selectedLabel: String {
        if data.allowMultiple {
            return multiValue.isEmpty ? "Select options..." : "\(multiValue.count) selected"
        } else {
            return data.options.first { multiValue.contains($0.id) }?.label ?? "Select option..."
        }
    }

    private func selectOption(_ id: String) {
        if data.allowMultiple {
            if multiValue.contains(id) {
                multiValue.removeAll { $0 == id }
            } else {
                multiValue.append(id)
            }
        } else {
            multiValue = [id]
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded = false
            }
        }
    }
}

// MARK: - Option Row

struct OptionRow: View {
    let option: FormOption
    let isSelected: Bool
    let isMulti: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isMulti
                      ? (isSelected ? "checkmark.square.fill" : "square")
                      : (isSelected ? "record.circle.fill"   : "circle"))
                    .foregroundStyle(isSelected ? .blue : .gray)

                Text(option.label)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.05) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Toggle Field View

struct ToggleFieldView: View {
    let data: ToggleFieldData
    @Binding var value: Bool

    var body: some View {
        // FIX: Section replaced with VStack
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: $value) {
                FieldHeader(label: data.label, required: data.required)
            }
        }
    }
}

// MARK: - Checkbox Field View

struct CheckboxFieldView: View {
    let data: CheckboxFieldData
    @Binding var value: Bool
    var hasError: Bool = false

    var body: some View {
        // FIX: Section replaced with VStack
        VStack(alignment: .leading, spacing: 6) {
            Button(action: { value.toggle() }) {
                HStack(spacing: 12) {
                    Image(systemName: value ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundStyle(value ? .blue : (hasError ? .red : .gray))

                    labelContent
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .styledInput(hasError: hasError)
            }
            .buttonStyle(.plain)

            if hasError, let message = data.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var labelContent: some View {
        if let metadata = data.metadata, !metadata.isEmpty {
            Text(attributedLabel(with: metadata))
        } else {
            HStack(spacing: 4) {
                Text(data.label)
                if data.required {
                    Text("*").foregroundStyle(.red)
                }
            }
        }
    }

    private func attributedLabel(with metadata: [String: String]) -> AttributedString {
        var result = AttributedString(data.label)
        for (key, urlString) in metadata {
            if let range = result.range(of: key), let url = URL(string: urlString) {
                result[range].link            = url
                result[range].foregroundColor = data.clickableTextColor ?? .blue
                result[range].underlineStyle  = .single
            }
        }
        return result
    }
}
