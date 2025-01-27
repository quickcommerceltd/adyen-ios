//
// Copyright (c) 2020 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import UIKit

/// :nodoc:
/// Describes any API Client.
public protocol APIClientProtocol {
    
    /// :nodoc:
    typealias CompletionHandler<T> = (Result<T, Error>) -> Void
    
    /// :nodoc:
    /// Performs the API request.
    func perform<R: Request>(_ request: R, completionHandler: @escaping CompletionHandler<R.ResponseType>)
    
}

/// :nodoc:
/// The Basic API Client.
public final class APIClient: APIClientProtocol {
    
    /// :nodoc:
    public typealias CompletionHandler<T> = (Result<T, Error>) -> Void
    
    /// :nodoc:
    /// The API environment.
    public let environment: APIEnvironment
    
    /// :nodoc:
    /// Initializes the API client.
    ///
    /// - Parameters:
    ///   - environment: The API environment.
    public init(environment: APIEnvironment) {
        self.environment = environment
    }
    
    /// :nodoc:
    public func perform<R: Request>(_ request: R, completionHandler: @escaping CompletionHandler<R.ResponseType>) {
        let url = environment.baseURL.appendingPathComponent(request.path)
        let body: Data
        do {
            body = try Coder.encode(request)
        } catch {
            completionHandler(.failure(error))
            
            return
        }
        
        adyenPrint("---- Request (/\(request.path)) ----")
        
        printAsJSON(body)
        
        var urlRequest = URLRequest(url: add(queryParameters: request.queryParameters + environment.queryParameters, to: url))
        urlRequest.httpMethod = request.method.rawValue
        if request.method == .post {
            urlRequest.httpBody = body
        }
        
        urlRequest.allHTTPHeaderFields = request.headers.merging(environment.headers, uniquingKeysWith: { key1, _ in key1 })
        
        requestCounter += 1
        
        urlSession.adyen.dataTask(with: urlRequest) { [weak self] result in
            
            self?.requestCounter -= 1
            
            switch result {
            case let .success(data):
                do {
                    adyenPrint("---- Response (/\(request.path)) ----")
                    printAsJSON(data)
                    
                    if let apiError: APIError = try? Coder.decode(data) {
                        completionHandler(.failure(apiError))
                    } else {
                        let response = try Coder.decode(data) as R.ResponseType
                        completionHandler(.success(response))
                    }
                } catch {
                    completionHandler(.failure(error))
                }
            case let .failure(error):
                completionHandler(.failure(error))
            }
            
        }.resume()
    }
    
    /// :nodoc:
    private func add(queryParameters: [URLQueryItem], to url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if !queryParameters.isEmpty {
            components?.queryItems = queryParameters
        }
        return components?.url ?? url
    }
    
    /// :nodoc:
    private lazy var urlSession: URLSession = {
        URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
    }()
    
    /// :nodoc:
    private var requestCounter = 0 {
        didSet {
            let application = UIApplication.shared
            application.isNetworkActivityIndicatorVisible = self.requestCounter > 0
        }
    }
    
}

internal func printAsJSON(_ data: Data) {
    guard AdyenLogging.isEnabled else { return }
    do {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        adyenPrint(jsonString)
    } catch {
        if let string = String(data: data, encoding: .utf8) {
            adyenPrint(string)
        }
    }
}
