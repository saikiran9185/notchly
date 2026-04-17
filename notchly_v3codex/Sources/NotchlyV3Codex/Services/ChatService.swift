import Foundation

struct ChatService {
    private static let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    private static let apiKey   = "REDACTED_KEY"
    private static let model    = "anthropic/claude-3-haiku-20240307"

    struct Message: Codable {
        let role: String
        let content: String
    }

    static func send(
        userMessage: String,
        history: [Message],
        systemPrompt: String,
        completion: @escaping @Sendable (Result<String, Error>) -> Void
    ) {
        var allMessages: [Message] = [Message(role: "system", content: systemPrompt)]
        allMessages += history
        allMessages.append(Message(role: "user", content: userMessage))

        let body: [String: Any] = [
            "model":      model,
            "messages":   allMessages.map { ["role": $0.role, "content": $0.content] },
            "max_tokens": 300,
            "temperature": 0.7
        ]

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)",      forHTTPHeaderField: "Authorization")
        req.setValue("application/json",      forHTTPHeaderField: "Content-Type")
        req.setValue("https://notchly.app",   forHTTPHeaderField: "HTTP-Referer")
        req.setValue("Notchly",               forHTTPHeaderField: "X-Title")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let msg = choices.first?["message"] as? [String: Any],
                  let text = msg["content"] as? String
            else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "ChatService", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unexpected response"])))
                }
                return
            }
            DispatchQueue.main.async { completion(.success(text.trimmingCharacters(in: .whitespacesAndNewlines))) }
        }.resume()
    }
}
