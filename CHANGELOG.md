# Changelog for Redmine Issue Sync

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.1.4 - 2022-03-05

### Fixed

* undefined local variable or method `source_project_list_for_select'

## 0.1.3 - 2021-12-03

### Deleted

* blank line from select_tag in sync_issues/_settings.html.erb

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
