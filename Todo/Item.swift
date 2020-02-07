

import Foundation

struct Item: Codable {
    var id: String
    var description: String
    var status: Bool
    var star: Bool
    var owner: String
    var listName: String
    var dueDateTime: String
    var recordingStorageRef: URL?
}
