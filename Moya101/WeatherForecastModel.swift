//
//  WeatherForecastModel.swift
//  Moya101
//
//  Created by 강민성 on 2022/09/21.
//

import Foundation

struct WetherForecastModel: Codable {
    let list: [List]
}

// MARK: - List
struct List: Codable {
    let main: Main
    let dtTxt: String

    enum CodingKeys: String, CodingKey {
        case main
        case dtTxt = "dt_txt"
    }
}
