//
//  FormDataService.swift
//  FormForge
//
//  Created by Vikram Kunwar on 26/05/26.
//


import Foundation

class FormDataService {
    enum DataServiceError: LocalizedError {
        case fileNotFound(String)
        case decodingFailed(String)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let filename):
                return "JSON file '\(filename)' not found in bundle"
            case .decodingFailed(let details):
                return "Failed to decode JSON: \(details)"
            }
        }
    }

    func loadFormPayload(filename: String) throws -> FormPayload {
        guard let url = Bundle.main.url(forResource: "forms", withExtension: "json") else {
            throw DataServiceError.fileNotFound(filename)
        }

        let data = try Data(contentsOf: url)

        do {
            return try JSONDecoder().decode(FormPayload.self, from: data)
        } catch {
            throw DataServiceError.decodingFailed(error.localizedDescription)
        }
    }
}
