# Changelog for Redmine Issue Sync

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.1.12 - unreleased

### Added

* Redmine 5 Support

## 0.1.11 - 2022-09-23

### Changed

* README to include most required software

## 0.1.10 - 2022-09-21

### Changed

* BasePresenter to be used from AdvancedPluginHelper

## 0.1.9 - 2022-08-09

### Fixed

* stack level too deep error in issue_sync view due to presenter usage on plain
  ruby methods

## 0.1.8 - 2022-08-09

### Fixed

* undefined method error in SyncValidator which is removed now since unnecessary

## 0.1.7 - 2022-08-08

### Added

* plugin settings for ignoring some issue attributes when synchronising
* git hook scripts running automatically rubocop, brakeman, and tests

### Fixed

* requirement of optional settings to be set

## 0.1.6 - 2022-07-08

### Fixed

* nil error during object generation when module issue sync is not fully configured

## 0.1.5 - 2022-04-28

### Changed

* issue sync button to be displayed only if the user is allowed to

## 0.1.4 - 2022-03-06

### Fixed

* undefined local variable or method `source_project_list_for_select'
* failing IssuesController test in Redmine 4.2.4

## 0.1.3 - 2021-12-03

### Deleted

* blank line from select_tag in issue_sync/_settings.html.erb

### Added

* further selection option in issue sync dialog

## 0.1.2 - 2021-10-11

### Fixed

* nil error for trackers default settings

### Added

* custom field format project_type_master to select options for custom field
  selection in plugin settings
* method to relate issues to each other after synchronisation
* select_tag for all trackers in drop down list of synchronisation dialog

## 0.1.1 - 2021-07-02

### Added

* redmine_base_deface 1.6.2 plugin

### Changes

* typos in translations (:en)

## 0.1.0 - 2021-05-28

### Added

* issue synchronisation capability
