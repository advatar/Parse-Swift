//
//  URLSession+extensions.swift
//  ParseSwift
//
//  Original file, URLSession+sync.swift, created by Florent Vilmart on 17-09-24.
//  Name change to URLSession+extensions.swift and support for sync/async by Corey Baker on 7/25/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

extension URLSession {

    internal func dataTask<U>(
        with request: URLRequest,
        callbackQueue: DispatchQueue?,
        mapper: @escaping (Data) throws -> U,
        completion: @escaping(Result<U, ParseError>) -> Void
    ) {
        print("request \(request)")

        func makeResult(responseData: Data?, urlResponse: URLResponse?,
                        responseError: Error?) -> Result<U, ParseError> {

            if let data = responseData,  let str = String(data: data, encoding: .utf8) {
                print("makeResult \(str)")
            }

            if let responseData = responseData {
                do {
                    let mapped = try mapper(responseData)
                    print("mapped \(mapped)")
                    return try .success(mapper(responseData))
                } catch {
                    if let str = String(data: responseData, encoding: .utf8) {
                        print("failed for \(str)")
                    }
                    let parseError = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: responseData)
                    return .failure(parseError ?? ParseError(code: .unknownError, message: "cannot decode error"))
                }
            } else if let responseError = responseError {
                return .failure(ParseError(code: .unknownError, message: "Unable to sync: \(responseError)"))
            } else {
                return .failure(ParseError(code: .unknownError,
                                           message: "Unable to sync: \(String(describing: urlResponse))."))
            }
        }

        dataTask(with: request) { (responseData, urlResponse, responseError) in
            let result = makeResult(responseData: responseData, urlResponse: urlResponse, responseError: responseError)

            if let callbackQueue = callbackQueue {
                callbackQueue.async { completion(result) }
            } else {
                completion(result)
            }
        }.resume()
    }
}
