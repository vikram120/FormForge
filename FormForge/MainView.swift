//
//  MainView.swift
//  FormForge
//
//  Created by Vikram Kunwar on 26/05/26.
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = FormViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading form...")
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage)
            } else {
                FormView(viewModel: viewModel)
            }
        }
        .task {
            viewModel.loadForm()
        }
        .alert("Form Submitted", isPresented: $viewModel.showSubmissionAlert) {
            Button("OK") {
                viewModel.submittedData = nil
            }
        } message: {
            if let submittedData = viewModel.submittedData {
                let dataText = submittedData
                    .sorted { $0.key < $1.key }
                    .map { "\($0.key): \($0.value)" }
                    .joined(separator: "\n")
                Text(dataText)
            }
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Error")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Form View

struct FormView: View {
    @ObservedObject var viewModel: FormViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        if !viewModel.formTitle.isEmpty {
                            Text(viewModel.formTitle)
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        ForEach(viewModel.fields) { field in
                            fieldRow(for: field)
                        }
                    }
                    .padding(16)
                }

                // Fixed save button
                VStack(spacing: 12) {
                    Divider()

                    Button(action: { viewModel.submitForm() }) {
                        HStack {
                            if viewModel.isSubmitting {
                                ProgressView().tint(.white)
                            }
                            Text(viewModel.isSubmitting ? "Saving..." : "Save")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isSubmitting)
                    .padding(16)
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle(viewModel.formTitle.isEmpty ? "Form" : viewModel.formTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func fieldRow(for field: AnyFormField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            switch field {
            case .text(let data):
                TextFieldView(
                    data: data,
                    value: viewModel.textBinding(for: data.id),
                    hasError: viewModel.validationErrors[data.id] != nil
                )
            case .dropdown(let data):
                // FIX: removed stale `value:` argument — DropdownFieldView only takes multiValue
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

            if let error = viewModel.validationErrors[field.id] {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundStyle(.red)
                .padding(.leading, 4)
            }
        }
    }
}

#Preview {
    MainView()
}
