import UIKit
import Cosmos
import SwiftyJSON
import Alamofire
import APESuperHUD
import YandexMobileMetrica

final class FeedbackVC: UIViewController { //}, UINavigationControllerDelegate {
    
    @IBOutlet weak var stars: CosmosView!
    @IBOutlet weak var review: UITextView!
    
    var trainId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// UI
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.title = "Поделитесь мнением"
        
        if let rootVC = navigationController?.viewControllers.first {
            navigationController?.viewControllers = [rootVC, self]
        }
    }
    
    @IBAction func bookNext(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func sendFeedback(_ sender: Any) {
        reportEvent("Отзыв", [:])
        
        let hdr = [
            "Content-Type": "application/json",
            "X-AUTH-TOKEN": App.this.userToken
        ]
        let feedbackUrl = "\(App.BASEURL)/addreview"
        let body: [String : Any] = [
            "idroom": App.this.reservedRoomId,
            "mark": Int(stars.rating),
            "note": review.text ?? "",
            "uuid": trainId
        ]

        APESuperHUD.show(style: .loadingIndicator(type: .standard), title: nil, message: "Отменяем...")
        
        Alamofire.request(feedbackUrl, method: .post, parameters: [:], encoding: JSON(body).rawString()!, headers: hdr)
            .responseString {
                response in
                APESuperHUD.dismissAll(animated: true)
                switch response.response?.statusCode {
                case 200, 201:
                    APESuperHUD.dismissAll(animated: true)
                    let alert = UIAlertController(title: "Отзыв отправлен!", message: "Спасибо, что помогаете нам стать лучше.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ок", style: .default, handler: {
                        action in
                        self.navigationController?.popToRootViewController(animated: true)
                    }))
                    self.present(alert, animated: true, completion: nil)
                default:
                    self.raiseAlert("Увы!", "Не удалось отправить отзыв. Пожалуста, повторите попытку позже.", "Понятно")
                }
        }
    }
}
