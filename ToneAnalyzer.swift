import Foundation
import Dispatch 

let defaultMessage = "New comment received: URL unavailable"
func main(args: [String:Any]) -> [String:Any] {
    guard let issue = args["issue"] as? [String:Any] else { return ["text" : defaultMessage] }
    guard let issueUrl = issue["html_url"] as? String else { return ["text" : defaultMessage] }
    guard let title = issue["title"] as? String else { return ["text" : defaultMessage] }
    guard let comment = args["comment"] as? [String:Any] else { return ["text" : "Error"] }
    guard let commentUrl = comment["html_url"] as? String else { return ["text" : defaultMessage] }
    guard let body = comment["body"] as? String else { return ["text": defaultMessage] }
    return ["text":"A <\(commentUrl)|\(sentiment(body)) comment> was received on issue <\(issueUrl)|\(title)>"]
}

func sentiment(_ comment: String) -> String  {
    let config = URLSessionConfiguration.default
    let userPasswordString = "28d56fad-66b6-47c6-acb4-f44d52d0b758:OP4zpT3bGtGm"
    let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)!
    let base64EncodedCredential = userPasswordData.base64EncodedString()
    let authString = "Basic \(base64EncodedCredential)"
    config.httpAdditionalHeaders = ["Authorization" : authString, "Content-Type": "application/json"]
    let session = URLSession(configuration: config)

    let json = "{\"text\": \"\(comment)\"}"
    let sem = DispatchSemaphore(value: 0) 
    var urlReq = URLRequest(url: URL(string: "https://gateway.watsonplatform.net/tone-analyzer/api/v3/tone?version=2016-05-19")!)
    urlReq.httpBody = json.data(using: .utf8)!
    urlReq.httpMethod = "POST"
    urlReq.allHTTPHeaderFields = ["Authorization" : authString, "Content-Type": "application/json"] 
    var tone = "neutral" 
    let task = session.dataTask(with: urlReq) { data, response, error in
         do { 
            guard let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else { sem.signal(); return }
            guard let docTone = json["document_tone"] as? [String: Any] else { sem.signal(); return }
            guard let emotions = (docTone["tone_categories"] as? [Any])?[0] as? [String: Any] else { sem.signal(); return }
            guard let tones = emotions["tones"] as? [Any] else { sem.signal(); return }
            var max = 0.0, dominantEmotion = ""
            for tone in tones {
                guard let toneJson = tone as? [String:Any] else { continue }
                guard let score = toneJson["score"] as? Double, let emotion = toneJson["tone_id"] as? String, score > max else { continue }
                max = score
                dominantEmotion = emotion
             }
             tone = ["anger","disgust","fear","sadness"].contains(dominantEmotion) ? "negative":"positive"
         } catch { sem.signal() }
     
         sem.signal()
    }
    task.resume()
    sem.wait()
    return tone
}
