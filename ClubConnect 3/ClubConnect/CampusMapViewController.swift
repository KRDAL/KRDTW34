import UIKit
import MapKit
import CoreLocation

final class CampusMapViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var distanceLabel: UILabel!

    // A fixed demonstration campus point in Manila, chosen for this assignment.
    // Change these constants if your instructor requires your actual campus gate.
    private let campusName = "Demo Campus (Manila)"
    private let campusCoordinate = CLLocationCoordinate2D(latitude: 14.6045, longitude: 120.9885)
    private let locationManager = CLLocationManager()
    private var requestingLocation = false
    private var isVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Campus Map"
        let region = MKCoordinateRegion(center: campusCoordinate, latitudinalMeters: 1500, longitudinalMeters: 1500)
        mapView.setRegion(region, animated: false)
        let campusPin = MKPointAnnotation()
        campusPin.coordinate = campusCoordinate
        campusPin.title = campusName
        mapView.addAnnotation(campusPin)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        distanceLabel.text = "Allow location to calculate your distance from campus."
        locationManager.requestWhenInUseAuthorization()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isVisible = true
        updateAuthorization()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isVisible = false
        requestingLocation = false
        mapView.showsUserLocation = false
        locationManager.stopUpdatingLocation()
    }

    @IBAction private func locateTapped(_ sender: UIBarButtonItem) {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            updateAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuthorization()
    }

    private func updateAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            guard isVisible, !requestingLocation else { return }
            requestingLocation = true
            mapView.showsUserLocation = true
            distanceLabel.text = "Finding your location…"
            locationManager.requestLocation()
        case .denied:
            requestingLocation = false
            mapView.showsUserLocation = false
            distanceLabel.text = "Location access is denied. Allow location for ClubConnect in Settings to calculate the distance."
        case .restricted:
            requestingLocation = false
            mapView.showsUserLocation = false
            distanceLabel.text = "Location access is restricted on this device. The campus pin is still available."
        case .notDetermined:
            distanceLabel.text = "Choose Allow While Using App to calculate your distance from campus."
        @unknown default:
            distanceLabel.text = "Location authorization is unavailable."
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        requestingLocation = false
        guard isVisible, let current = locations.last, current.horizontalAccuracy >= 0 else { return }
        let campus = CLLocation(latitude: campusCoordinate.latitude, longitude: campusCoordinate.longitude)
        let meters = current.distance(from: campus)
        let prefix = manager.accuracyAuthorization == .reducedAccuracy ? "Approximate distance" : "Distance from campus"
        distanceLabel.text = String(format: "%@: %.0f meters\nLocation accuracy: ±%.0f meters", prefix, meters, current.horizontalAccuracy)

        // Fit both coordinates so a simulated position can be compared with the pin.
        let a = MKMapPoint(campusCoordinate)
        let b = MKMapPoint(current.coordinate)
        let bounds = MKMapRect(x: min(a.x, b.x), y: min(a.y, b.y),
                               width: max(abs(a.x - b.x), 1000), height: max(abs(a.y - b.y), 1000))
        mapView.setVisibleMapRect(bounds, edgePadding: UIEdgeInsets(top: 50, left: 40, bottom: 50, right: 40), animated: true)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        requestingLocation = false
        guard isVisible else { return }
        distanceLabel.text = "Location is unavailable. Tap Locate to retry. In Simulator, select a simulated location first."
        NSLog("Campus location failed: %@", error.localizedDescription)
    }
}
