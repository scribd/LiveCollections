//
//  APIClient.swift
//  LiveCollectionsSample
//
//  Created by Théophane Rupin on 4/4/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

// MARK: - Error
enum APIError: Error {
    case networkingProtocolIsNotHTTP
    case network(Error)
    case url(String)
    case deserialization(Error)
    case emptyBodyResponse
    case api(statusCode: Int, message: String?)
}

// MARK: - HTTP method
enum APIHTTPMethod {
    case get
}

// MARK: - Request
struct APIRequestConfig {
    let method: APIHTTPMethod
    let host: String?
    let path: String
    var query: [String: Any]
}

struct APIRequest<Model> {
    
    let config: APIRequestConfig
    
    init(_ config: APIRequestConfig) {
        self.config = config
    }
    
    init(method: APIHTTPMethod = .get,
                host: String? = nil,
                path: String,
                query: [String: Any] = [:]) {
        
        let config = APIRequestConfig(method: method,
                                      host: host,
                                      path: path,
                                      query: query)
        self.init(config)
    }
}

// MARK: - API
protocol APIProtocol {
    
    func send(request: APIRequest<Data>, completion: @escaping (Result<Data, APIError>) -> Void)
    
    func send<Model>(request: APIRequest<Model>, completion: @escaping (Result<Model, APIError>) -> Void) where Model: Decodable
}

