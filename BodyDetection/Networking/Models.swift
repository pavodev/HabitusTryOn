//
//  Models.swift
//  BodyDetection
//
//  Created by Ivan Pavic on 25.08.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation

struct UploadWithQRResponse: Decodable {
    let media_id: Int
    let media_url: String
    let qr_id: Int
    let qr_url: String
}
