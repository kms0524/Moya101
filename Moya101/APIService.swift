//
//  APIService.swift
//  Moya101
//
//  Created by 강민성 on 2022/09/14.
//

import Foundation
import Moya

enum APIService {
    case currentWeather(lat: String, lon: String)
    case forecastWeather(lat: String, lon: String)
}

extension APIService: TargetType {

    var baseURL: URL { URL(string: BaseAPI.baseURL)!}
    
    var path: String {
        switch self {
        case .currentWeather(let lat, let lon) :
            return "/weather?lat=\(lat)&lon=\(lon)&appid=\(BaseAPI.apiKey)"
            
        case .forecastWeather(let lat, let lon) :
            return "/forecast?lat=\(lat)&lon=\(lon)&appid=\(BaseAPI.apiKey)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .currentWeather, .forecastWeather :
            return .get
        }
    }
    
    var task: Task {
        switch self {
        case let .currentWeather(lat, lon) :
            return .requestParameters(parameters: ["lat" : lat, "lon" : lon, "appid" : BaseAPI.apiKey], encoding: URLEncoding.queryString)
        case let .forecastWeather(lat, lon):
            return .requestParameters(parameters: ["lat" : lat, "lon" : lon, "appid" : BaseAPI.apiKey], encoding: URLEncoding.queryString)
        }
    }
    
    var headers: [String : String]? {
        return ["Content-type" : "application/json"]
    }
    
}
