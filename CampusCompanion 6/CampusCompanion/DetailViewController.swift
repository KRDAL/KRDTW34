import UIKit
import MapKit
import CoreLocation

class DetailViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var campusMapView: MKMapView!
    @IBOutlet weak var distanceLabel: UILabel!

    private enum CampusLocation {
        static let coordinate = CLLocationCoordinate2D(
            latitude: 14.6255,
            longitude: 121.0034
        )
    }

    private enum LibraryLocation {
        static let coordinate = CLLocationCoordinate2D(
            latitude: 14.6259,
            longitude: 121.0039
        )
    }

    private let locationManager = CLLocationManager()

    var studentName: String = ""
    var notificationsEnabled: Bool = false
    var selectedRole: String = ""
    var preferredEventDate: Date = Date()
    var numberOfGuests: Int = 1
    var announcement: CampusAnnouncement?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let announcement = announcement {
            title = announcement.category
            messageLabel.text = "\(announcement.title)\n\nCategory: \(announcement.category)\nDate: \(announcement.date)\nPriority: \(announcement.priority)\nPosted By: \(announcement.postedBy)"
        } else {
            title = "Campus Events"
            let notificationStatus = notificationsEnabled ? "on" : "off"
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            let dateText = formatter.string(from: preferredEventDate)
            messageLabel.text = "Welcome, \(studentName)! (\(selectedRole))\nNotifications: \(notificationStatus).\nEvent: \(dateText)\nGuests: \(numberOfGuests)"
        }
        configureMap()
        configureLocation()
    }

    private func configureMap() {
        let region = MKCoordinateRegion(
            center: CampusLocation.coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        campusMapView.setRegion(region, animated: false)

        let campusAnnotation = MKPointAnnotation()
        campusAnnotation.coordinate = CampusLocation.coordinate
        campusAnnotation.title = "Campus"

        let libraryAnnotation = MKPointAnnotation()
        libraryAnnotation.coordinate = LibraryLocation.coordinate
        libraryAnnotation.title = "Campus Library"

        campusMapView.addAnnotation(campusAnnotation)
        campusMapView.addAnnotation(libraryAnnotation)
    }

    private func configureLocation() {
        distanceLabel.text = "Waiting for location access..."
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            distanceLabel.text = "Location access denied."
        default:
            break
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let currentLocation = locations.first else { return }
        let campusLocation = CLLocation(
            latitude: CampusLocation.coordinate.latitude,
            longitude: CampusLocation.coordinate.longitude
        )
        let distanceInMeters = currentLocation.distance(from: campusLocation)
        distanceLabel.text = String(
            format: "You are approximately %.0f meters from campus.",
            distanceInMeters
        )
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        distanceLabel.text = "Unable to determine your location."
    }
}
