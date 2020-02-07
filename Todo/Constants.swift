struct K {
    static let appName = "Todo"
    static let cellIdentifier = "ReusableCell"
    static let cellNibName = "ItemCell"
    static let registerSegue = "RegisterToChat"
    static let loginSegue = "LoginToChat"
    
    struct BrandColors {
        static let purple = "BrandPurple"
        static let lightPurple = "BrandLightPurple"
        static let blue = "BrandBlue"
        static let lighBlue = "BrandLightBlue"
    }
    
    struct FStore {
        static let collectionName = "items"
        static let idField = "id"
        static let descriptionField = "description"
        static let statusField = "status"
        static let dateField = "date"
        static let starField = "star"
        static let ownerField = "owner"
        static let listNameField = "listName"
        static let dueDateTime = "dueDateTime"
        static let recordingStorageRef = "storageRef"
    }
}
