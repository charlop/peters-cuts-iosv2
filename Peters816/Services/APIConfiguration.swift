//
//  APIConfiguration.swift
//  Peters816
//
//  Updated for API v2 migration
//

import Foundation

struct APIConfiguration {
    static var baseURL: URL {
        #if DEBUG
        return URL(string: "https://dev-api.peterscuts.com/v2")!
        #else
        return URL(string: "https://d5la1oo09caqz.cloudfront.net/v2")!
        #endif
    }
}
