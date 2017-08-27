import Foundation

let defaultMessage = "New issue created: URL unavailable"
func main(args: [String:Any]) -> [String:Any] {
    guard let issue = args["issue"] as? [String:Any] else { return ["text" : "Error"] }
    guard let htmlUrl = issue["html_url"] as? String else { return ["text" : defaultMessage] }
    guard let title = issue["title"] as? String else { return ["text": defaultMessage] }
    return ["text":"New issue created: <\(htmlUrl)|\(title)>"]
}
