import UIKit

final class UsedTariffItem: UIView {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tariffTitle: UILabel!
    @IBOutlet weak var tariffDesc: UILabel!
    @IBOutlet weak var tariffProlong: UIButton!    
    @IBOutlet weak var tariffProlongHC: NSLayoutConstraint!
    
    class func instanceFromNib() -> UsedTariffItem {
        let nibView = UINib(nibName: "UsedTariffItem", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UsedTariffItem
        
    //    fixInView(nibView)
        nibView.tariffTitle.numberOfLines = 0
        return nibView
    }
    
    func fixInView(_ container: UIView!) -> Void {
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self);
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
    
    /*
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("UsedTariffItem", owner: self, options: nil)
        fixInView(contentView)
    }
    
    
 */
}
