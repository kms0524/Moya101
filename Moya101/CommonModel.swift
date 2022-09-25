//
//  CommonModel.swift
//  Moya101
//
//  Created by 강민성 on 2022/09/21.
//

import Foundation

struct Main: Codable {
    let temp, tempMin, tempMax: Double

    enum CodingKeys: String, CodingKey {
        case temp
        case tempMin = "temp_min"
        case tempMax = "temp_max"
    }
}
