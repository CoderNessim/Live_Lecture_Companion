//
//  APICaller.swift
//  FinalProject-CSE438
//
//  Created by Jiayu Huang on 11/5/24.
//

import Foundation

struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: APIMessage
}

struct APIMessage: Codable {
    let content: String
}

final class APICaller {
    static let shared = APICaller()
    
    private var messageHistory: [[String: String]] = [
        ["role": "system", "content": "You are a helpful assistant."]
    ]
    
    private enum Constants {
        static let key = "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"
        static let endpoint = "https://api.openai.com/v1/chat/completions"
    }
    
    private init() {}
    
    public func clearHistory() {
        messageHistory = [
            ["role": "system", "content": "You are a helpful assistant."]
        ]
    }
    
    public func getResponse(input: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: Constants.endpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        messageHistory.append(["role": "user", "content": input])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Constants.key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messageHistory,
            "max_tokens": 1000
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // For debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(OpenAIResponse.self, from: data)
                if let content = response.choices.first?.message.content {
                    self?.messageHistory.append(["role": "assistant", "content": content])
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No content in response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
