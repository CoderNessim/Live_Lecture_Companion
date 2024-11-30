import Foundation

let apiBaseURL = "https://fastapi-service-940454193602.us-central1.run.app"

// Function to test /process_wav_data/
func processWavData(bytestream: Data, condensedTranscript: String, completion: @escaping (String) -> Void) {
    guard let url = URL(string: apiBaseURL + "/process_wav_data/") else {
        completion("Invalid URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
    request.setValue(condensedTranscript, forHTTPHeaderField: "Condensed-Transcript")
//    request.setValue("\(bytestream.count)", forHTTPHeaderField: "Content-Length")
    request.httpBody = bytestream

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion("Error: \(error.localizedDescription)")
            return
        }
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
        }
        guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
            completion("Invalid response data")
            return
        }
        completion(responseString)
    }
    task.resume()
}

// Function to test /process_wav_file/
func processWavFile(filePath: String, condensedTranscript: String, completion: @escaping (String) -> Void) {
    guard let url = URL(string: apiBaseURL + "/process_wav_file/"),
          let fileURL = URL(string: "file://\(filePath)") else {
        completion("Invalid URL")
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(condensedTranscript, forHTTPHeaderField: "Condensed-Transcript")

    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var body = Data()
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)

    if let fileData = try? Data(contentsOf: fileURL) {
        body.append(fileData)
    } else {
        completion("Failed to load file at path: \(filePath)")
        return
    }
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
    request.httpBody = body

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion("Error: \(error.localizedDescription)")
            return
        }
        guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
            completion("Invalid response data")
            return
        }
        completion(responseString)
    }
    task.resume()
}

// Function to test /question/
func questionAndAnswer(question: String, condensedTranscript: String, completion: @escaping (String) -> Void) {
    guard let url = URL(string: apiBaseURL + "/question/") else {
        completion("Invalid URL")
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.setValue(condensedTranscript, forHTTPHeaderField: "Condensed-Transcript")
    let bodyString = "question=\(question.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
    request.httpBody = bodyString.data(using: .utf8)

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion("Error: \(error.localizedDescription)")
            return
        }
        guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
            completion("Invalid response data")
            return
        }
        completion(responseString)
    }
    task.resume()
}


