
<!---
## [Unreleased]
### Added
### Fixed
### Changed
### Removed
-->

## iOS Version Requirements

MapsIndoors SDK v4 requires at least iOS 13 and Xcode 14.

## [4.1.0] 2023-05-17

### Added

- Mapbox version now 10.13.1 which adds:
- Wall extrusions 

### Fixed

- Multi-line label cut-off
- Marker missing when selecting location
- Clustering icon size fix
- Mapbox 10.13.1 fixes some Layers glitching
- Fixed some known bugs

## [4.0.3] 2023-04-21

### Added

- [MPMapControl.showInfoWindowOnClickedLocation](https://app.mapsindoors.com/mapsindoors/reference/ios/v4-doc/documentation/mapsindoors/mpmapcontrol/showinfowindowonclickedlocation) to control if info windows should be shown when a Location is selected

### Fixed

- Icons are now respecting zoom levels in Display Rules
- Labels are now respecting zoom levels in Display Rules inherited from the Location Type
- MPMapControl.hideFloorSelector now actually hides the floor selector

## [4.0.2] 2023-04-13

### Fixed

- A number of rendering issues have been corrected.
- An issue that could prevent a route from being correctly created.

## [4.0.1] 2023-04-05

### Fixed

- Fixed crash with Mapbox when panning around the map.

## [4.0.0] 2023-03-31

Version 4 of the MapsIndoors SDK has changed significantly compared to version 3. There is a [migration guide](https://docs.mapsindoors.com/getting-started/ios/v4/v4-migration-guide) that describes the changes.

### Added

* Support for new map providers
    * MapsIndoors can now be used with the Mapbox v10 SDK.
* `goTo(entity:)`
    * A new method for moving the camera to MapsIndoors locations, this new method goTo() can be used with any class that implements MPEntity, which includes but is not limited to MPLocation, MPFloor, and MPBuilding.
* Solution Config
    * The SDK now supports the Solution Config.
    * This also introduces the new Main Display Rule, which is bundled into the solution config, along with collision handling and clustering.
* New Cocoapods
    * The main Cocoapod to use is either `MapsIndoorsGoogleMaps` or `MapsIndoorsMapbox` depending on the map engine to use.
        * Both of these Cocoapods are dependent on the `MapsIndoors` and `MapsIndoorsCore` Cocoapods and will automatically include them.
        * Most classes in `MapsIndoorsCore` are public but meant for communication between the core SDK and map platform specific code. These classes are not described in the reference docs. Refrain from using these classes unless you know what you are doing.

### Changed

* Initialisation of MapsIndoors
    * The interface to initiate the SDK is improved for smaller and safer implementations.
    * Initialise MapsIndoors with `MPMapsIndoors.shared.load(apiKey: "YOUR_MAPSINDOORS_API_KEY")`
* Initialization of MapControl
    * In order to support multiple map engines an `MPMapConfig` is needed.
    * The `MPMapConfig` is then used to create a MapControl: `let mapControl = MPMapsIndoors.createMapControl(mapConfig: mapConfig)`.
* Display Rules
    * Display Rules have been reworked completely.
    * Display Rules are now reference based, thus any changes to a rule are instantaneous.
    * Display Rules can be reset with `reset()`. This will return the display rule to the state it has in the CMS.
* The iOS SDK Reference Docs have been modernised and are now available at https://app.mapsindoors.com/mapsindoors/reference/ios/v4-doc/documentation/mapsindoors/


* Many interface changes. See migration guide for help in migrating from MapsIndoors SDK v3.
* Minimum iOS version supported is iOS 13.
* Required Xcode version is Xcode 14.

