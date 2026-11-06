import Foundation

enum ClubServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case missingData
    case invalidClub

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Enter the raw HTTPS URL of your published clubs.json using Club Source."
        case .invalidResponse: return "The club server did not return an HTTP response."
        case .httpStatus(let code): return "The club server returned HTTP \(code). Check the published URL."
        case .missingData: return "The club server returned no data."
        case .invalidClub: return "Each club must have a nonempty name, category and iconName."
        }
    }
}

final class ClubService {
    @discardableResult
    func fetchClubs(from urlString: String,
                    completion: @escaping (Result<[ClubDTO], Error>) -> Void) -> URLSessionDataTask? {
        fetchData(from: urlString) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                do {
                    let clubs = try JSONDecoder().decode([ClubDTO].self, from: data)
                    guard clubs.allSatisfy({ $0.hasRequiredValues }) else {
                        throw ClubServiceError.invalidClub
                    }
                    completion(.success(clubs))
                } catch {
                    NSLog("Club JSON decoding failed: %@", error.localizedDescription)
                    completion(.failure(error))
                }
            }
        }
    }

    @discardableResult
    func fetchData(from urlString: String,
                   completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionDataTask? {
        guard let url = ClubFeedConfiguration.validatedURL(from: urlString) else {
            completion(.failure(ClubServiceError.invalidURL))
            return nil
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 25)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Transport errors must be checked before inspecting the HTTP response.
            if let error = error {
                NSLog("Club request failed: %@", error.localizedDescription)
                completion(.failure(error))
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(ClubServiceError.invalidResponse))
                return
            }
            guard (200...299).contains(http.statusCode) else {
                completion(.failure(ClubServiceError.httpStatus(http.statusCode)))
                return
            }
            guard let data = data else {
                completion(.failure(ClubServiceError.missingData))
                return
            }
            completion(.success(data))
        }
        task.resume()
        return task
    }
}
