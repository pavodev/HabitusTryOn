//
//  WordPressClient.swift
//  BodyDetection
//
//  Created by Ivan Pavic on 25.08.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import UIKit
import Security

// Simple credentials container for WordPress
struct WordPressCredentials {
    let baseURL: URL
    let username: String
    let appPassword: String
}

// Keychain storage for WordPress credentials
final class KeychainCredentialsStore {
    private let service = "com.BodyDetection.wpcreds" // you can change to your bundle id
    private let account = "default"

    /// Save credentials to Keychain. Returns true on success.
    @discardableResult
    func save(urlString: String, username: String, appPassword: String) -> Bool {
        guard URL(string: urlString) != nil,
              let data = try? JSONSerialization.data(withJSONObject: [
                  "url": urlString,
                  "username": username,
                  "password": appPassword
              ], options: []) else {
            return false
        }

        // Remove any existing item to avoid duplicates
        delete()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Load credentials from Keychain, or nil if missing/invalid.
    func load() -> WordPressCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: String],
              let urlStr = dict["url"],
              let username = dict["username"],
              let password = dict["password"],
              let url = URL(string: urlStr) else {
            return nil
        }
        return WordPressCredentials(baseURL: url, username: username, appPassword: password)
    }

    /// Delete stored credentials.
    func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

final class WordPressClient {

    private let baseURL: URL
    private let username: String
    private let appPassword: String

    init(baseURL: URL, username: String, appPassword: String) {
        self.baseURL = baseURL
        self.username = username
        self.appPassword = appPassword
    }

    convenience init(credentials: WordPressCredentials) {
        self.init(baseURL: credentials.baseURL,
                  username: credentials.username,
                  appPassword: credentials.appPassword)
    }

    // Build REST URL using ?rest_route= form; robust for subdirectory installs and plain permalinks
    private func restURL(_ restPath: String) -> URL {
        var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        var path = comps.path.isEmpty ? "/" : comps.path
        if !path.hasSuffix("/") { path.append("/") } // avoid 301 POST→GET redirect
        comps.path = path
        comps.queryItems = [URLQueryItem(name: "rest_route", value: restPath)]
        return comps.url!
    }

    private var authHeader: String {
        "Basic " + Data("\(username):\(appPassword)".utf8).base64EncodedString()
    }

    // Async/await upload (single POST that returns image + QR)
    func upload(image: UIImage, title: String?) async throws -> UploadWithQRResponse {
        guard let jpeg = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not encode JPEG"])
        }

        var req = URLRequest(url: restURL("/ar/v1/upload-with-qr"))
        req.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.setValue(authHeader, forHTTPHeaderField: "Authorization")

        var body = Data()
        // file field
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"snapshot.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(jpeg)
        body.append("\r\n")
        // optional title
        if let title, !title.isEmpty {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"title\"\r\n\r\n")
            body.append("\(title)\r\n")
        }
        body.append("--\(boundary)--\r\n")
        req.httpBody = body

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Server error"
            throw NSError(domain: "Upload", code: (resp as? HTTPURLResponse)?.statusCode ?? -2, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return try JSONDecoder().decode(UploadWithQRResponse.self, from: data)
    }

    // Async image fetcher (QR PNG)
    func fetchImage(at url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let img = UIImage(data: data) else {
            throw NSError(domain: "QR", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }
        return img
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let d = string.data(using: .utf8) {
            append(d)
        }
    }
}
