import UIKit
import SwiftyJSON

class TariffSelectorVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: - Properties
    var tariffType = -1
    var completion: ((_ id: Int) -> Void)?
    var tariffsToSelect: [JSON] = []

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHC: NSLayoutConstraint!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tariffsToSelect = tariffsToSelect.sorted(by: { $0["coast"].intValue < $1["coast"].intValue })
        
        tableViewHC.constant = min(self.view.bounds.height - 200, CGFloat(tariffsToSelect.count * 98))
        tableView.reloadData()        
    }

    // MARK: - IBActions
    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tariffsToSelect.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TariffSelectorItem", for: indexPath as IndexPath) as! TariffSelectorItem
        
        cell.price.text = "\(tariffsToSelect[indexPath.row]["coast"].intValue) руб."

        if tariffType == TARIFF_SINGLE_TRAIN {
            cell.descr.text = "Разовое занятие длительностью 1 час"
        }
        else {
        cell.descr.text = tariffsToSelect[indexPath.row]["description"].stringValue
        }
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = .clear
        cell.selectedBackgroundView = bgColorView
        
        cell.container.borderColor = isSubscribed(tariffsToSelect[indexPath.row]) ? .white : UIColor(argb: 0xff92B909)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: false)
        self.dismiss(animated: true, completion: {
            
            switch self.tariffType {
            case TARIFF_TRAINS_W_COACH:
                reportEvent("Coach\(self.tariffsToSelect[indexPath.row]["coast"].intValue)", [:])
            case TARIFF_ABONEMENT:
                reportEvent("Abon\(self.tariffsToSelect[indexPath.row]["coast"].intValue)", [:])
            default:
                break
            }

            self.completion?(self.tariffsToSelect[indexPath.row]["id"].intValue)
        })
    }
}

class TariffSelectorItem: UITableViewCell {
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var descr: UILabel!
    @IBOutlet weak var container: UIView!
}
