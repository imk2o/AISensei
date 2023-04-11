//
//  URLSession+Extension.swift
//  AISensei
//
//  Created by k2o on 2023/04/03.
//

import Foundation

protocol URLConvertible {
    var url: URL { get }
}

extension URL: URLConvertible {
    var url: URL { self }
}

extension String: URLConvertible {
    var url: URL { .init(string: self)! }
}

extension URLRequest {
    static func post(
        _ convertible: URLConvertible,
        body: some Encodable,
        requestEncoder: JSONEncoder = .init()
    ) throws -> Self {
        var request = URLRequest(url: convertible.url)
        request.httpMethod = "POST"
        request.httpBody = try requestEncoder.encode(body)
        return request
    }
}

//extension URLSession {
//    func post<ResponseBody: Decodable>(
//        _ url: URLConvertible,
//        body: some Encodable,
//        responseType type: ResponseBody.Type,
//        requestEncoder: JSONEncoder = .init(),
//        responseDecoder: JSONDecoder = .init()
//    ) async throws -> (ResponseBody, HTTPURLResponse) {
//        let (data, response) = try await data(for: .post(url, body: body, requestEncoder: requestEncoder))
//        
//        let httpResponse = response as! HTTPURLResponse
//        let responseBody = try responseDecoder.decode(type, from: data)
//        
//        return (responseBody, httpResponse)
//    }
//}
