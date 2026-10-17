import UIKit
import CoreData

class AnnouncementsViewController: UITableViewController {
    private var announcements: [CampusAnnouncement] = []
    private var selectedAnnouncement: CampusAnnouncement?

    private var context: NSManagedObjectContext {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Campus Announcements"
        tableView.rowHeight = 84
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAnnouncementTapped))
        seedInitialAnnouncementsIfNeeded()
        loadAnnouncements()
    }

    private func seedInitialAnnouncementsIfNeeded() {
        let request: NSFetchRequest<CampusAnnouncement> = CampusAnnouncement.fetchRequest()
        let existingCount = (try? context.count(for: request)) ?? 0
        guard existingCount == 0 else { return }
        let seeds = [
            ("Enrollment Period Extended", "August 3, 2026", "Registrar", "Urgent", "Registrar"),
            ("Library Hours Extended for Finals", "August 5, 2026", "Library", "Normal", "University Library"),
            ("Career Fair 2026", "August 7, 2026", "Career Center", "Normal", "Career Center"),
            ("Student Council Elections", "August 10, 2026", "Student Affairs", "Urgent", "Student Affairs"),
            ("Campus Wi-Fi Maintenance Notice", "August 12, 2026", "IT Services", "Urgent", "IT Services"),
            ("Intramural Sports Sign-Up", "August 14, 2026", "Athletics", "Normal", "Athletics Office")
        ]
        for seed in seeds {
            let item = CampusAnnouncement(context: context)
            item.title = seed.0
            item.date = seed.1
            item.category = seed.2
            item.priority = seed.3
            item.postedBy = seed.4
        }
        try? context.save()
    }

    private func loadAnnouncements() {
        let request: NSFetchRequest<CampusAnnouncement> = CampusAnnouncement.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        announcements = (try? context.fetch(request)) ?? []
        tableView.reloadData()
    }

    @objc private func addAnnouncementTapped() {
        let alert = UIAlertController(title: "New Announcement", message: "Enter a title and category.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Title" }
        alert.addTextField { $0.placeholder = "Category" }
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let titleText = alert?.textFields?[0].text, !titleText.isEmpty,
                  let categoryText = alert?.textFields?[1].text, !categoryText.isEmpty else { return }
            let item = CampusAnnouncement(context: self.context)
            item.title = titleText
            item.date = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
            item.category = categoryText
            item.priority = "Normal"
            item.postedBy = categoryText
            try? self.context.save()
            self.loadAnnouncements()
        }
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        announcements.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AnnouncementCell", for: indexPath) as? AnnouncementCell else {
            return UITableViewCell()
        }
        cell.configure(with: announcements[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedAnnouncement = announcements[indexPath.row]
        performSegue(withIdentifier: "ShowAnnouncementDetailSegue", sender: self)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let item = announcements[indexPath.row]
        context.delete(item)
        try? context.save()
        announcements.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowAnnouncementDetailSegue",
              let destination = segue.destination as? DetailViewController,
              let announcement = selectedAnnouncement else { return }
        destination.announcement = announcement
    }
}
