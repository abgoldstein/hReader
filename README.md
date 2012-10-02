# Project Setup

- The build process requires the `plist` gem. Run `sudo gem install plist --no-rdoc --no-ri` to install the gem in your system Ruby.
- hReader relies on several git submodules. Run `git submodule update --init --recursive` to update all submodules.
- The build process requires the presence of the Xcode "Command Line Tools" package. Navigate to Xcode > Preferences > Downloads > Components and install the package.
- The build process requires openssl source code to be setup in the environment.
  - Download OpenSSL from <http://www.openssl.org/source/>. hReader has been tested against version 1.0.1c.
  - Untar the OpenSSL archive.
  - Create a new source tree in your Xcode preferences (Xcode > Preferences > Locations > Source Trees) called `OPENSSL_SRC` pointed at the location of the OpenSSL source directory.

# History

## 2012-5-20

### New

- Add initial launch flow including passcode, security questions, RHEx login, and family setup
- All patient data is being served by RHEx so some of it might not look pretty or be incorrect
- Fix bug in functional status applet
- Authentication is done against RHEx using OAuth 2
- New "Configure Family" view allows adding of patients and selecting a patient opens the main app interface to that patient
- All new encryption back end that keeps the app from functioning if the passcode has not been set
- Server authentication keys are stored in the keychain after being encrypted
- Timeline XML document is now marked as protected on the file system
- Fix bugs in patient reordering
- Persist and sync patient data with RHEx
- Applet selection and order is persisted

### Known Issues

- Resetting the passcode and security questions is not yet supported
- 6 digit passcode is succeptable to brute force attacks in about 8 seconds
- All patients are re-synced with RHEx even if the patient has not changed

## 2012-4-21

- Update timeline code to use new edge-to-edge timeline
- Add new patient image user interaction to timeline
- Update timeline view layout to match dimensions and style of the summary screen

## 2012-4-18

- Using new BMI charts to get percentile for male and female children
- Decreased search complexity when searching BMI chart which caused locking on the main thread
- BMI percentiles are now calculated based on the age they were taken

## 2012-4-16

- Children < 20 years old now show BMI percetiles

## 2012-4-14

- Started HRWebViewAppletTile
- Changed immunizations applet to show immunizations instead of up to date

## 2012-4-11

- Updated default applets
- Added some backwards compat changes to compile on Snow Leopard
- Upgraded TestFlight SDK to v1.0

## 2012-4-10

- disable different tap regions of patient image
- resolve crash where dragging installed applet to available applets would cause a crash

## 2012-4-10

- Make sure that the patient picker table view allows selection while in reorder mode
- Save which patient is selected and restore it on launch

## 2012-4-9

- Changed BMI normal range for adults to 18-25
- Added reordering of patients

## 2012-4-8

- Add alert offering to setup an email account if none is present when the Feedback button is tapped
- Change patient toggle to be cyclical
- Change patient image interaction on the summary view to be tap instead of swipe (left vs right half of the image will do previous vs next respectively)
- Sort conditions by the correct date field
- Update timeline

## 2012-4-7

- Converted feedback form to email instead of testflight.
- Emails go to hreader@googlegroups.com

## 2012-4-4

- make conditions and events tappable
- add full screen views for each patient for conditions and events
- lock entire user interface to landscape
- add oxygen saturation applet
- add respiratory rate applet
- set default applets for nancy
- update provider images for henry

## 2012-4-4

- immunizations applet shows black when up to date and red otherwise
- adjusted column width of condition dates to allow for more of the condition name to be shown
- remove date label from events > medication refills
- use sentence capitalization from all labels (not including rasterized images)
- patients are now sorted by age, oldest on top in the people picker
- update image assets for providers and simulated applets for almost every patient

## 2012-4-4

- minor ui bug fixes and changes
- sparklines now show unique visible range per-line instead of for the whole graph

## 2012-4-03

- update henry smith user image
- show dots for every point on sparklines, white for in range red for out
- refactor summary view header to reflect new layout
- add new people picker icon

## 2012-4-02

- Fixed timeline issues
- Finished HRSparkLine lib
- Fixed bug in date formatter parsing in timeline

## 2012-4-30

- Started custom sparkline library
- Updated user images
- Updated timeline code

## 2012-4-25

- Updated the default applets and their order for the Smith family
- Version bump to 0.4

## 2012-4-23

- Updated providers images

## 2012-4-20

- Added 1-finger swipe to user image
- Fixed view alignments
- Updated summary view images
- Changes doctors tab to providers
- Updated provider tiles
- Increased font size of vitals normals
- Updated patient image on all views

## 2012-4-19

- Implement new "people picker" view
- Implement name search on people picker view
- Transition "Summary" screen to new people picker view
- Add two-finger swipe left and right on the summary screen to go to previous / next patient respectively
- Show new tiles and associated full screen views on doctors tab

## 2012-4-18

- Fixed normal ranges on blood pressure applet
- Added diastolic values to BP popover table
- Normal range is now checked for systolic values
- Added normal ranges to BMI applet
- Removed old vital applets and added blood pressure and/or BMI to the patients
- Moved "upcoming events" to align with grid
- Setup doctors view to use new health gateway views
- Added placeholders on doctors view

## 2012-4-16

- Fixed 'ghost' messages
- Converted BMI to standalone applet
- Converted blood pressure to standalone applet (still needs to account for diastolic)
- Add "slid out" view for applets. In the future the patient picker will work the same way

## 2012-4-13

- Add ability to reorder installed applets
- Fix bugs with data display
- Update simulated applets

## 2012-4-13

- Added new applets provided by Dave
- Added allergies to synthetic data
- Medication refill now shows refill date
- Set grid vertical padding to allow showing 2 full rows of applets
- Set appropriate applets for each user
- Added wahoo applet
- Added nikeplus applet
- Added withings applet
- Added fitbit applet
- Added wakemate applet
- Fixed chronic conditions misspelling
- Added functional status applet
- Added popHealth applet
- Added lyme disease applet
- Added ms applet
- Added chronic fatigue applet
- Added applet management mechanism

## 2012-4-12

- updated patient data files
- finish showing all data on the summary view after the summary view refactor

The following changes lay the foundation for the tools menu but customizations to applet visibility and sort order are available only at compile time.

- list of applets is now stored per-patient
- different patients can show different applets
- applets can be ordered per patient

## 2012-4-11

- Setup api to pass in tap events to applet tiles
- Moved vital views to be an applet
- Moved medications to be an applet
- Added mockup of TBI tracker tile
- TBI Tracker tap pushes full screen view onto the stack
- Fixed enterprise profile issue
- Applets are now loaded dynamically from a plist file
- Applet API automatically sets patient and user info dictionary for user defined values
- Added immunizations applet
- Added vitals applet
- Added medications applet
- Added recent encounters applet

## 2012-4-10

- Started implementation of applet loading

## 2012-4-09

- Change red color in the app
- Creating custom grid table view to be used for display infinite number of doctors and applets on the summary view.
- Added custom set horizontal and vertical padding to the custom grid table view.

## 2012-4-07

- Removed #'s after patient names and replaced with *
- Changed display name back to hReader
- Changed bundle identifier back to org.mitre.HReader (this will install as a fresh app)
- Minor version bump to 0.3

## 2012-4-06

- Filling in missing synthetic data
- Set all red color to hReader red
- Vitals in the timeline now also show the values
- Moved tools and about to toolbar
- Changed tools button from 'action' to 'add' icon per Jeff's request
- Added synthetic data disclaimer to about

## 2012-4-03

- Fixed issue with vitals popover staying on the screen after the app goes to background
- Fixed issue with tools popover staying on screen when selecting about or navigation segmented control
- Internal refactoring for custom view handling
- Load synthetic data from JSON files
- Messages now uses synthetic data
- Providers now uses synthetic data

## 2012-4-02

This build removes any synthetic data from the summary screen. All data being shown is parsed from PDS generated JSON.

- Removed mock message in footer
- Added tools button to nav bar
- Removed privacy demo
- Moved feedback button to top of about
- Added build date to about view
- Moved C32 HTML to tools
- Removed mock data
- Added tables for vitals when you tap on them
- Tapping DOB changes to age. If < 6 months it shows weeks, if < 2 years, show months, else show years

## 2012-3-30

- Fixed bugs in passcode handling
- Code and file cleanup

## 2012-3-28

- Finished passcode reset via security questions when a user forgets their PIN
- Fixed crash when you try to change security questions and they don't already exist
- Security questions 'Done' button is only enabled when the questions and answers exist
- Turned off autocomplete and autocapitalization on the security answers fields
- Updated timeline with overlapping dots fixes

## 2012-3-26

- Fixed usability issues with PIN code and security questions
- Last thing remaining is the PIN code reset

## 2012-3-23

- Security questions to assist in passcode reset
- Rewritten passcode view to support security question workflow
- There are some minor usability issues with this release but nothing that will keep the app from running properly

## 2012-3-6

- Minor refactoring of vital views
- Import new patient JSON files
- Show medications sorted with most recent on top

## 2012-02-29

- Fixed medications to be formatted properly (will show max of 8)
- Refactored vitals
- Sparklines are now generated from real data
- BMI implemented with normal check and ranges

## 2012-02-27

- Doctors view now setup to dynamically load providers
- Converted doctors view to storyboard view controller
- Ensure child view title is set on root view for when pushing onto the nav stack
- Code cleanup and refactoring

## 2012-02-23

- Added new swipe view to summary view
- Started using PDS variables for summary view

## 2012-02-17

- Refactor C32 browser to use storyboarding
- C32 now displays data based on the selected patient

## 2012-02-16

- Rewrite root view controller to eliminate a lot of memory and lifecycle issues

## 2012-02-15

- Refactored swipe control
- Updated swipe control on doctors, messages, timeline
- Timeline now dynamically loads greenJSON data

## 2012-02-08

- Refactored vitals into their own view class
- Vitals are now specific to the metric they are measuring and can determine if the results are in range
- Set version number to 0.2

## 2012-02-06

- Disable any kind of feedback on the PIN entry screen
- Set messages table view to gray gradient selection style
- Implement mechanism to set/change passcode

## 2012-02-02

- Change PIN entry screen to use new design and random digit layout
- Present PIN entry screen every time the app goes to the background

## 2012-01-30

- Refactored app navigation to not use wide scroll view. Also had to refactor how patient swipes were handled
- Code cleanup

## 2012-01-30

* Removed old PIN view

## 2012-01-25

* Changed patients order
* Fixed some typos

## 2012-01-20

* Removed unused assets

## 2012-01-19

### Summary View

* Updated sparklines

### Timeline View

* Removed overlapping encounters from C32

## 2012-01-18

### Summary View

* Added mock data
* Added sparklines
* Tweaked layout

### Timeline View

* Added patient name

### Messages View

* Set cell selected color to light gray

### Doctors View

* Added patient name

## 2012-01-16

### Summary View

* Redesign

## 2012-01-11

### Timeline View

* Updated to latest version with speed improvements
* Added Encounter parsing

## 2012-01-09

### Timeline View

* Updated to latest timeline simile.

### Doctors View

* Changed a few doctor titles
* Moved doctor detail view back arrow

### Patient Summary

* Fixed Johnny's name
* Aligned patient name with age and gender

## 2012-01-06

### Timeline View
* Updated to latest timeline simile.

## 2012-01-04

* Hide the window when the app goes to background to protect against caching screenshots of the screen. To test just double click the home button.
* Added TestFlight checkpoints to see how users are testing the app.
* Added Pinview (0000) whenever the app comes to foreground

### About View

* Added shadow and font changes to about text

### Doctors View

* Added 6 doctors

### Messages View

* Number of messages in segmented control is now dynamic based on the actual number of messages

### Timeline

* Added current SIMILE timeline
* Disabled events that cause the keyboard to show

## 2011-12-27

* Added privacy education and warning screen which shows on first launch. The user is asked to lock their iPad to check if the passcode is enabled and then tells the user if it is or not.

## 2011-12-20

* Research on passcode verification

### Messages View

* Added dynamic content, still waiting on mock data to fill real messages in

### Doctors View

* Added hospital when selected fades in a doctor detail view

## 2011-12-14

* Added TestFlight checkpoints to check usage

### Summary View

* Added variable DOB, phone number, place of birth, race, ethicity
* Added fade out/fade in of info when switching users
* Fixed issue when trying to swipe when at first or last patient

## 2011-12-05

* Added the TestFlight SDK to help gather feedback and statistics

### Summary View

* Added variable age, address, and gender

### C32 View

* Added button to lower right to show HTML version of C32 modally 

### About View

* Added version
* Added feedback form

## 2011-12-05

* Fixed issue which slowed down device orientation issues
* Patient swipe view now updates users photo when swiped from another patient swipe view

### Timeline View

* Changed timeline to use HTML provided by Jeff
* Added patient swipe view

### Messages View

* Added patient swipe view

### Doctor View

* Change name for Dr. Finger
* Added patient swipe view

## 2011-12-05

### Patient Summary View

* Created a reusable patient swipe view with a page control. You can now swipe the users image or tap the dots to change a user. Currently this only works on the summary view. It also changes the users name.

## 2011-12-05

### Patient Summary View

* Finished up static content for patient summary
* Pixel perfect tweaks
* Only show shadow on patient summary when scrolled down, otherwise hide it

### Timeline View

* Shifted image left to align with edge of iPad

### Messages View

* Mocked up
* Added border to left of content view
* Added shadow to patient image view
* Set background to linen

### Doctors View

* Mocked up
* Added border and shadow to doctor image

## 2011-12-02

* Refactored app to use new navigation
* Added static image for timeline
* Added placeholder views for all other components

## 2011-11-30

* Refactored app to use new full screen view. Every view in the app must have a header of the same size to accommodate swiping. The content views will be able to contain any type of iOS view elements and can be interacted with without the headers intercepting the touch events.

* Segmented control is dynamically created based on the views and it autosizes the width. Selecting a segment scrolls to the correct view.

* Added WebView to content area which can be pinched and zoomed to show that it can be interacted with without affecting the swiping

## 2011-11-28

* Scrollview test
* Added red placeholder for timeline view and swiping. Next step is to refactor the entire structure to accommodate the new navigation behavior.