# DiTour

## About
DiTour is a universal iOS app for displaying interactive slideshows on an external screen. It is designed for giving tourguide presentations. 

## Requirements
DiTour runs on any modern iPhone, iPad or iPod Touch, but iPad is recommended. An external monitor is required for displaying the presentations. Media content for the presentations are loaded from a web server.

## Web Server File Structure

### Presentations Groups
One or more presentation may be collected into a group. Each group is identified by a URL which specifies the location of the group which is the root directory of all presentations for that group. One or more group may be specified.

### Presentations
Within each directory pointed to by the group, is a list of directories (one for each presentation). Under each presentation directory, are directories corresponding to each track. Tracks will be loaded alphanumerically as they appear on the indexed webpage. You can force order by prefixing track names with any sequence of digits followed by an underscore. This prefix will be stripped when forming the track name to display. The first track is the default track. When the user selects a track, that slides in that track are presented until the specified duration expires or the user selects another track. When the duration expires, the presentation returns to the default track. The default track plays all its slides in order and repeats indefinitely. A slide may either by an image or a movie. An image is displayed for the track's default duration before switching to the next slide. A movie slide is presented until the movie plays to completion and then switches to the next slide. A PDF slide will present each of its pages as if they were individual image slides.

### Configuration
In each directory, a config.json file may be specified. The configuration is valid at the level of the directory and is inherited by all sub directories. Properties specified in a configuration file override inherited. The configuration file format is JSON format which may contain any of the following information:
* slideDuration  - floating point value indicating the time in seconds to display a slide
* singelImageSlideTrackDuration - floating point value indicating the time in seconds for displaying a track with a single slide before transitioning to the next track
* slideTransition - JSON dictionary of with the following key/value pairs:
  - `type` - string value for the transition type (one of:  `fade`, `push`, `reveal` or `moveIn`)
  - `subtype` - string value for the transition subtype (one of: `fromTop`, `fromLeft`, `fromRight` or `fromBottom`)
  - `duration` - floating point value in seconds for the transition time

### Media Directory Layout and Index Format
Media should be placed on a web server that is accessible to the device. The URL should point to the presentation group's directory and has the following structure:

* Presentation Group Directory
  * Presentation directories plus optional config.json
    * Track directories plus optional config.json
	  * Media files, icon file plus optional config.json

The supported media file extensions are: `png`, `jpeg`, `jpg`, `gif`, `mp4`, `m4v`, `pdf`, `dae` (iOS 8 and later) and `urlspec`. Note that dae (COLLADA 3D model) files must be compressed and should contain any referenced materials internally and are only supported in iOS 8 and later.

Any file named `Icon` with on of the supported image extensions is treated as an icon for the track rather than a slide. In the absence of an explicit icon, the first image slide or PDF page will be used if available and otherwise a default icon.

### Web Page Slides
A slide whose content is given by a web page can be specified using a plain text file with an extension of `urlspec` and whose contents is simply the URL of the page to render. By default, the page will be scaled (preserving aspect ratio) to fit on the external screen. You may optionally append a URL query key/value pair to specify an alternate scaling (all preserve aspect ratio) using one of the following mode values for the `ditour-zoom` key:

| Zoom Mode | Zoom Behavior |
| ----- | ------ |
| `none` | Don't scale. Will display the page just as Safari would cropped to the screen's view and positioned at the top left corner of the page pinned to the top left corner of the screen. |
| `width` | Scale the page to fit the width of the page onto the screen, cropping vertically and positioned at the top of the page pinned to the top of the screen. |
| `height` | Scale the page to fit the height of the page onto the screen, cropping horizontally and positioned at the left of the page pinned to the left of the screen. |
| `both` | This is the default behavior. It scales the page to fit both horizontally and vertically on the external screen. |

For example, to disable any scaling, one can specify the URL as: http://web.ornl.gov/~t6p/Main/DiTour.html?ditour-zoom=none

Be aware that while most websites simply ignore keys they don't define (which is ideal), some websites do not and web pages may fail to load properly when they are given query keys they don't define. If a web page can't handle these query keys, just don't use them and the page will be rendered using the default behavior.

