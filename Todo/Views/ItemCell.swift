import UIKit
import Firebase

protocol ItemCellDelegate {
    func pressedStar()
    func pressedDone()
}

class ItemCell: UITableViewCell {
        
    @IBOutlet weak var checkBox: UIButton!
    @IBOutlet weak var star: UIButton!
    @IBOutlet weak var bubble: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var cellDelegate: ItemCellDelegate?
    
    var checked: Bool! {
        didSet {
            if checked == true {
                checkBox.setImage(UIImage(systemName:"checkmark.square"), for: .normal)
            } else {
                checkBox.setImage(UIImage(systemName:"square"), for: .normal)
            }
        }
    }
    var starred: Bool! {
        didSet {
            if starred == true{
                star.setImage(UIImage(systemName:"star.fill"), for: .normal)
            } else {
                star.setImage(UIImage(systemName:"star"), for: .normal)
            }
        }
    }
    var db: Firestore!
    var itemID: String!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bubble.layer.cornerRadius = bubble.frame.size.height / 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func checkBoxPressed(_ sender: UIButton) {
        cellDelegate?.pressedDone()
        let item = db.collection(K.FStore.collectionName).document(itemID)
        if checked {
            checked = false
            item.updateData([
                K.FStore.statusField: false
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
        }
        else {
            checked = true
            item.updateData([
                K.FStore.statusField: true
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
        }
    }
    
    
    @IBAction func starPressed(_ sender: UIButton) {
        cellDelegate?.pressedStar()
        let item = db.collection(K.FStore.collectionName).document(itemID)

        if starred {
            item.updateData([
                K.FStore.starField: false
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
             starred = false
        }
        else {
            item.updateData([
                K.FStore.starField: true
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
            starred = true
        }
    }
    
  
}
