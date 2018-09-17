//
//  MovieAPI.swift
//  LiveCollectionsSample
//
//  Created by Théophane Rupin on 4/4/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

final class MovieAPI: APIProtocol {
    
    private let urlSession: URLSession
    
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    func send(request: APIRequest<Data>, completion: @escaping (Result<Data, APIError>) -> Void) {
        
        let completionOnMainThread = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        var config = request.config
        config.query["api_key"] = Constants.apiKey
        
        guard let url = URL(string: (config.host ?? Constants.apiHost) + config.path + "?" + config.queryString) else {
            completion(.failure(.url(request.config.path)))
            return
        }
        
        let task = urlSession.dataTask(with: url) { (data, response, error) in
            
            if let error = error {
                completionOnMainThread(.failure(.network(error)))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completionOnMainThread(.failure(.networkingProtocolIsNotHTTP))
                return
            }
            
            guard response.statusCode == 200 || response.statusCode == 304 else {
                completionOnMainThread(.failure(.api(statusCode: response.statusCode, message: nil)))
                return
            }
            
            guard let data = data else {
                completionOnMainThread(.failure(.emptyBodyResponse))
                return
            }
            
            completionOnMainThread(.success(data))
        }
        
        task.resume()
    }
    
    func send<Model>(request: APIRequest<Model>, completion: @escaping (Result<Model, APIError>) -> Void) where Model: Decodable {
        
        let dataRequest = APIRequest<Data>(request.config)
        
        send(request: dataRequest) { result in
            switch result {
            case .success(let data):
                if let errorModel = try? JSONDecoder().decode(APIErrorModel.self, from: data) {
                    completion(.failure(.api(statusCode: errorModel.status_code, message: errorModel.status_message)))
                    return
                }
                
                do {
                    let model = try JSONDecoder().decode(Model.self, from: data)
                    completion(.success(model))
                } catch {
                    completion(.failure(.deserialization(error)))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension MovieAPI {
    
    enum Constants {
        static let apiHost = "https://api.themoviedb.org/3"
        static let apiKey = "1a6eb1225335bbb37278527537d28a5d"
        
        static let imageAPIHost = "https://image.tmdb.org/t/p/w300"
    }
}

// MARK: - Utils
private extension APIRequestConfig {
    var queryString: String {
        return query.map { "\($0)=\($1)" }.joined(separator: "&")
    }
}
