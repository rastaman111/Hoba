import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation
import MapKit
import Alamofire
import SwiftyJSON
import DSGradientProgressView

let MAXZOOM: Float = 20
let MINIMALDIST = 1
let ACTIVEBUTTONCOLOR = UIColor(argb: 0xff005FFF)

final class RoomsMapVC: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, GMSAutocompleteFetcherDelegate {
    
    var currentLocation = CLLocationCoordinate2D()
    
    let locationManager: CLLocationManager = {
        $0.requestWhenInUseAuthorization()
        $0.desiredAccuracy = kCLLocationAccuracyBest
        $0.startUpdatingLocation()
        $0.startUpdatingHeading()
        $0.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        //$0.allowsBackgroundLocationUpdates = true
        $0.pausesLocationUpdatesAutomatically = false
        $0.distanceFilter = 1.0
        $0.headingFilter = 0.1
        return $0
    }(CLLocationManager())
    
    var notYetSetCurrentLocation = true
    
    @IBOutlet weak var progressIndicator: DSGradientProgressView!

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var mapViewHC: NSLayoutConstraint!
    
    @IBOutlet weak var infoBlockView: UIView!
    @IBOutlet weak var infoBlockViewHC: NSLayoutConstraint!
    @IBOutlet weak var infoBlockTitle: UILabel!
    @IBOutlet weak var infoBlockDescription: UILabel!
    @IBOutlet weak var infoBlockImage: UIImageView!
    @IBOutlet weak var infoBlockButton: UIButton!
    
    var currentInfoBlock = 0
    
    var coord0 = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var coord1 = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    var currentZoom: Float = 12.0
    
    var jsonData: [JSON] = []
    var parentVC: SelectRoomVC?

    var roomMarkers: [GMSMarker] = []
    var activeMarkerIdx: Int = -1
    
    var viewFrame: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.isMyLocationEnabled = true
        
        // Ask for Authorisation from the User.
        locationManager.delegate = self
        
        scrollView.isScrollEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        mapViewHC.constant = self.view.frame.height
        infoBlockViewHC.constant = self.view.frame.height - 96
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            self.progressIndicator.isHidden = false
            self.progressIndicator.wait()
        }
    }
    
    func updateLocation() {
        if (self.notYetSetCurrentLocation) {
            delay(2.0, closure: {self.progressIndicator.signal()})
            self.notYetSetCurrentLocation = false
            findMe()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            updateLocation()
        default:
            let alert = UIAlertController(title: "Требуется доступ к геолокации",
                                          message: "Пожалуйста разрешите использование в \"Настройках\"",
                                          preferredStyle: UIAlertController.Style.alert)
            
            let okAction = UIAlertAction(title: "Открыть Настройки", style: UIAlertAction.Style.default) {
                UIAlertAction in
                let path = UIApplication.openSettingsURLString
                if let settingsURL = URL(string: path), UIApplication.shared.canOpenURL(settingsURL) {
                    UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                }
            }
            let cancelAction = UIAlertAction(title: "Отмена", style: UIAlertAction.Style.cancel)
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func findMe() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            delay(2.0, closure: {self.progressIndicator.signal()})
            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                if let currentLocation = locationManager.location?.coordinate {
                    let camera = GMSCameraPosition.camera(withLatitude: currentLocation.latitude, longitude: currentLocation.longitude, zoom: currentZoom)
                    mapView.animate(to: camera)
                    locationManager.stopUpdatingLocation()
                }
            }
        default:
            let alert = UIAlertController(title: "Требуется доступ к геолокации",
                                          message: "Пожалуйста разрешите использование в \"Настройках\"",
                                          preferredStyle: UIAlertController.Style.alert)
            
            let okAction = UIAlertAction(title: "Открыть Настройки", style: UIAlertAction.Style.default) {
                UIAlertAction in
                let path = UIApplication.openSettingsURLString
                if let settingsURL = URL(string: path), UIApplication.shared.canOpenURL(settingsURL) {
                    UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                }
            }
            let cancelAction = UIAlertAction(title: "Отмена", style: UIAlertAction.Style.cancel)
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func updateMap(json: [JSON]) {
        jsonData = json
        
        for m in roomMarkers { m.map = nil }
        roomMarkers = []
        
        for i in 0 ..< jsonData.count {
            let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: jsonData[i]["lattitude"].doubleValue, longitude: jsonData[i]["longitude"].doubleValue))
            marker.icon = UIImage(named: "geoTag")
            marker.map = mapView
            marker.snippet = "\(i)"
            
            roomMarkers.append(marker)
        }
    }
    
    func setActiveInfoBlock(idx: Int) {
        for i in 0 ..< roomMarkers.count {
            if i == idx {
                activeMarkerIdx = i
                roomMarkers[i].icon = UIImage(named: "geoTagActive")
                
                infoBlockTitle.text = jsonData[i]["address"].stringValue
                infoBlockDescription.text = jsonData[i]["note"].stringValue
                infoBlockButton.tag = jsonData[i]["id"].intValue
                
                let dataEncoded = jsonData[i]["listfoto"][0]["photo"].stringValue
                let dataDecoded : Data = Data(base64Encoded: dataEncoded, options: .ignoreUnknownCharacters)!
                let decodedimage = UIImage(data: dataDecoded)
                infoBlockImage.image = decodedimage

                self.scrollView.isScrollEnabled = true
                self.infoBlockView.isHidden = false
            }
            else {
                roomMarkers[i].icon = UIImage(named: "geoTag")
            }
        }
    }
    
    @IBAction func infoBlockAction(_ sender: UIButton) {
        for j in jsonData {
            if j["id"].intValue == sender.tag {
                App.this.reservedRoom = j["address"].stringValue
            }
        }
        parentVC?.loadSchedule(id: sender.tag)
    }
    
    /// GMS
    func didAutocomplete(with predictions: [GMSAutocompletePrediction]) { }
    func didFailAutocompleteWithError(_ error: Error) { }
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        let view = UIView(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        view.backgroundColor = UIColor.clear
        setActiveInfoBlock(idx: Int(marker.snippet ?? "") ?? -1)
        
        return view
    }
}
