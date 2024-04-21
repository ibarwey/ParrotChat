//
//  GrammarCheck.swift
//  ParrotChat
//
//  Created by Ishna Barwey  on 4/20/24.
//

import Foundation
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct Edit: Codable {
    var end: Int
    var error_type: String
    var general_error_type: String
    var id: String
    var replacement: String
    var sentence: String
    var sentence_start: Int
    var start: Int
}

struct GrammarChecks: Codable {
    var edits: [Edit]
}

func decodeJSON (data: Data) -> GrammarChecks{
    do {
        let decoder = JSONDecoder()
        let grammarEdits = try decoder.decode(GrammarChecks.self, from:data)
        print(grammarEdits)
        return grammarEdits
    } catch {
        print("Could not decode")
        return GrammarChecks(edits: [])
    }
}

func getGrammarCheck(content: String, completion: @escaping (Result<GrammarChecks, Error>) -> Void) {
    let json: [String: Any] = [
        "key": SAP_KEY,
        "text": content,
        "session_id": "Parrot"
    ]
    
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: json)

        let url = URL(string: "https://api.sapling.ai/api/v1/edits")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(jsonData.count)", forHTTPHeaderField: "Content-Length")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            let grammarEdits = decodeJSON(data: data)
            completion(.success(grammarEdits))
        }
        task.resume()
    } catch {
        completion(.failure(error))
    }
}
