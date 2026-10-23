# Mapping to the supplied modules

Sources: `MAD2_MP1_CampusClubConnect(2).pdf` (7 pages) and `MAD2_MP2_CampusClubConnect(4).pdf` (8 pages). Both were read in full, including deliverables and the documentation requirement.

## MP1

| Requirement | Implementation / remaining verification |
| --- | --- |
| New ClubConnect Swift/UIKit/Storyboard app; no Core Data in MP1 | Independent project with standard App/Scene delegates; `mp1-complete` has no model or persistence stack. Assembled outside Xcode; the template wizard was not run. |
| Git from creation | Repository initialization followed by actual milestone commits; `.git` included in ZIP |
| Welcome title, subtitle, fixed Aspect Fit logo and Safe Area constraints | Main storyboard: Welcome scene, 28 pt bold title, tagline, 72×72 SF Symbol image, scrolling Auto Layout form |
| Title IBOutlet assigned in `viewDidLoad()` | `titleLabel.text = "Campus Club Connect"` in Welcome |
| Two different Simulator sizes, no clipping/overlap | Scrollable layout implemented; verify on the Mac using the checklist |
| Navigation controller and navigation title | Initial navigation controller with Welcome root; navigation items supplied |
| Button IBAction and manual Show segue | `joinClubTapped` calls `performSegue`; controller-level `ShowConfirmationSegue` |
| Separate ConfirmationViewController and message IBOutlet | Confirmation scene and Swift subclass |
| Automatic Back button | Native push through the navigation controller; verify in Simulator |
| Name text field, switch and Member/Officer segmented control | Storyboard controls connected to Welcome IBOutlets |
| Matching properties, default values, guarded `prepare`, safe optional text | Default name/reminders/role, identifier and destination guard, nil/empty/whitespace fallback |
| Summary assembled in `viewDidLoad()` | Confirmation combines name, role and reminder state |
| Dismiss keyboard before segue | `resignFirstResponder()` in the action |
| Populated and empty-name tests | Implementation handles both; execute the checklist on the Mac |
| Screenshots and reflection | Screenshot capture instructions plus a four-sentence reflection draft; real screenshots still needed |

## MP2

| Requirement | Implementation / remaining verification |
| --- | --- |
| Extend the same MP1 project | Welcome and Confirmation remain in the final target |
| Club model: name, category, iconName | Struct in Part A history; generated Core Data Club class in final Part D |
| Storyboard list reachable from Welcome | Browse Clubs action and `ShowClubListSegue` |
| Data source row count from collection | `clubs.count`, never a fixed row count |
| Reusable cells | `dequeueReusableCell(withIdentifier:for:)` |
| Custom storyboard cell with constrained image/name/category | Prototype `ClubCell`, three connected IBOutlets, `configure(with:)` |
| Matching reuse identifier | `ClubCell` in storyboard and the Swift static constant |
| Deselect row, store selection, manual segue | `didSelectRowAt`, `selectedClub`, `ShowClubDetailSegue` |
| Optional Club on existing detail, `if let` branch | `club: Club?` in Confirmation; details hidden for the MP1 path |
| Preserve MP1 information on detail screen | The directory forwards name, role and reminders along with the selected club |
| Private enum UserDefaults keys | `DefaultsKey` in Welcome |
| Save inside existing action before navigation | Three `set` calls in `joinClubTapped`; also saved when browsing |
| Restore typed values with first-launch defaults | `register(defaults:)`, `string`, `bool`, `integer`; guarded role index |
| `.xcdatamodeld` and automatic subclass generation | ClubConnect model; Club code generation set to Class Definition |
| Persistent container in AppDelegate | `NSPersistentContainer(name: "ClubConnect")`, loaded before initial screen |
| Context available to directory | `persistentContainer.viewContext` passed through AppDelegate access |
| Typed fetch replaces hardcoded array | `NSFetchRequest<Club>` and `context.fetch` |
| Seed >=4 only when fetched count is zero, save once | Five records inserted when `clubs.isEmpty`, then a single save |
| Add Club alert with name/category, insert-save-refresh | Plus bar button, two alert text fields, validation, insert, save, fetch and reload |
| Relaunch persistence for preferences, seed and added club | Storage implemented; verify on the same Simulator installation |
| Git commits for A–D | Separate MP2 A, B, C and D commits included |
| Reflection and screenshots | Four-sentence reflection draft plus checklist; native screenshots still needed |

Code comments explain the key logic as required by both rubrics. No fabricated Simulator screenshots or run results are included.
